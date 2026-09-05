# Evie Tool · 文本增强（M6）设计模式方案

> **状态**：📋 方案确认中（请用户 review 后再生成代码）
> **依赖**：[11-evie-tool独立轻量语音识别增强工具开发计划.md](./11-evie-tool独立轻量语音识别增强工具开发计划.md) M6 章节
> **设计约束**（用户反馈）：
> - 充分利用编程设计模式（Pipeline / Strategy / Factory / Flyweight / Observer）
> - 并发模型：基于 `context.Context` 的超时控制与取消传播
> - **三大禁止事项**：
>   - 禁止使用全局可变状态
>   - 禁止在 Processor 内部硬编码资源加载逻辑
>   - 禁止使用继承模拟

---

## 一、需求特性分析

evie/service 现有 8 层增强流水线（`enhancement.go`）的设计遗漏问题：

| 现有实现 | 问题 | 违反约束 |
|---|---|---|
| `EnhancementEngine.Enhance()` 内部调用 `authn.GetAuthUserTenantID(ctx)` 拿租户 ID 构建 VocabularyContext | Processor 内部硬编码资源加载（去 ctx 取租户） | 禁止事项 #2 |
| 步骤 `VocabularyMatchingStep` / `PinyinCorrectionStep` 通过 `c.Vocab.entries` / `c.Vocab.relations` 访问词库 | Processor 依赖外部 mutable state（VocabBuilder 单例） | 禁止事项 #1 |
| `EnhancementContext.lockedSpans` 是 `[]string`，每次 `lock()` append | 每次请求都共享同一个 slice 引用（事实上 data race 隐患） | 禁止事项 #1 |
| 步骤用 `time.Since(t0)` 计时，但 `enhance()` 内部直接拼装 `EnhancementResult`（多步混合职责） | 缺少观察者模式，每个步骤埋点不统一 | 模式缺失 |
| `EnhancementContext` 既承载数据也承载行为（lock / isLocked）| 缺少单一职责；相当于隐式继承（context "is-a" lock manager） | 禁止事项 #3 |
| 步骤零值 `{}` 实例，没有显式 Flyweight 声明 | 易被误用为 stateful（拷贝时共享） | 模式缺失 |

---

## 二、设计模式应用矩阵

| 模式 | 应用对象 | 解决的问题 |
|---|---|---|
| **Pipeline** | `Pipeline.Run(ctx, ec)` | 顺序执行 8 个步骤；每步可独立替换 |
| **Strategy** | `Policy` 决定哪些 Step 启用 | 不修改代码切换增强策略 |
| **Factory** | `BuildPipeline(policy, deps)` | 根据 Policy + 依赖构造完整 Pipeline |
| **Flyweight** | 每个 `Step` 是无状态空 struct（`type TextCleaningStep struct{}`）| 步骤实例可被所有请求共享，零拷贝 |
| **Observer** | `StepObserver` 监听步骤开始/完成/错误/变更 | 不修改 Pipeline 主体可加 metrics/logging/tracing |
| **Builder** | `EnhancementContextBuilder` 构造 per-request `EnhancementContext` | 强制显式不可变快照 |
| **Decorator（可选）** | `ObservingStep` 包装任一 `Step` 注入 Observer | 关注点分离，避免每个 step 重复埋点 |

**不引入的模式**（解释理由）：

- **Singleton**：禁止事项 #1（全局可变状态）
- **Inheritance**：禁止事项 #3（go 无继承；显式接口组合代替）
- **Mediator**：Pipeline 本身就是 Mediator 的轻量化体现
- **State**：策略决定步骤启停足够，不需要状态机

---

## 三、并发模型

```text
         ┌─────────────────────────────────────────────┐
         │   Pipeline（不可变，由 Factory 构造一次）     │
         │   steps []EnhancementStep  // Flyweight 共享  │
         └─────────────────────────────────────────────┘
                            ▲
                            │ Run(ctx, ec) // ctx 由调用方传入
                            │
         ┌─────────────────────────────────────────────┐
         │   EnhancementContext（per-request 不可变快照）│
         │   ├─ RawText       string                    │
         │   ├─ Text          string                    │
         │   ├─ Vocab         *VocabularySnapshot        │ // Build 一次
         │   ├─ Policy        *Policy                    │ // Build 一次
         │   ├─ Changes       []Change                   │ // append-only
         │   └─ lockedSpans   []string                   │ // append-only
         └─────────────────────────────────────────────┘
                            │
                            │ ctx.Done() / ctx.Err() 由各 Step 主动 select
                            ▼
                  业务调用方（ASR Usecase / Enhancement Service）
```

**取消传播规则**：

1. Pipeline 入口检查 `ctx.Err()`；已取消直接返回
2. 每 Step 内部在「重活」前（编译正则、模糊匹配循环）`select { case <-ctx.Done(): return ctx.Err(); default: }`
3. Pipeline 本身不持有 timer；超时由调用方 `context.WithTimeout` 注入
4. 取消时已积累的 `Changes` 仍可返回（部分结果）——EnhanceResult 标记 `status=3` (CANCELED)

**无全局可变状态校验**：

- `Pipeline.steps` 构造后只读
- 每个 `Step` 是空 struct，零字段
- `EnhancementContext` 在 `Run()` 内部创建，per-request
- `VocabularySnapshot` 由 `VocabularyBuilder.Build(ctx, tenantID)` 返回不可变快照（v1 已是 immutable；M5 阶段确认 `Build` 返回 deep copy）

---

## 四、关键类型设计

### 4.1 Step（Flyweight）

```go
// EnhancementStep 是文本增强步骤的最小契约。
//
// 设计约束：
//   1. Step 必须是无状态空 struct（Flyweight）；不允许携带 per-instance 字段
//   2. Apply 不允许从 ctx 拿资源（禁止事项 #2）；所有依赖必须显式从 ec 传
//   3. Apply 必须尊重 ctx 取消（每个重活前检查）
//   4. Apply 失败不返回 error（warn 模式，与 Normalizer C 决定一致）；
//      失败信息写入 ec.Changes 标记 status=DEGRADED
type EnhancementStep interface {
    // Name 返回步骤标识（与 Policy 中的 key 对齐）。
    Name() string

    // Apply 在 ec 上原地修改 Text / Changes / lockedSpans。
    // 失败语义：内部 warn + 跳过（不返回 error）。
    Apply(ctx context.Context, ec *EnhancementContext)
}
```

```go
// Flyweight 步骤示例（确定性步骤不持有任何状态）
type TextCleaningStep struct{}
type FillerStep struct{}
type VocabularyMatchingStep struct{}
type AliasResolutionStep struct{}
type DeterministicReplacementStep struct{}
type PhraseStandardizationStep struct{}
type PinyinCorrectionStep struct{}
type FuzzyMatchingStep struct{}
type ContextCorrectionStep struct{}
type LLMReservedStep struct{}  // 始终 no-op；M9 阶段评估是否实现
```

### 4.2 Policy（Strategy）

```go
// Policy 决定哪些步骤启用 + 推断阈值。
// 不可变（构造后只读）；多个 Pipeline 共享同一 Policy 实例。
type Policy struct {
    EnabledSteps        map[string]bool // "cleaning" / "filler" / ...
    PinyinThreshold     float64
    FuzzyAutoThreshold  float64
    FuzzySuggestThreshold float64
    LLMEnabled          bool
}

func (p *Policy) IsEnabled(step string) bool {
    if p == nil { return true } // nil policy = 全部启用（默认）
    return p.EnabledSteps[step]
}
```

### 4.3 VocabularySnapshot（不可变快照）

```go
// VocabularySnapshot 是 VocabularyContext 的不可变副本。
//
// M6 阶段复制 evie/service 的 VocabularyContext，去除任何 pointer-to-mutable。
// 所有下游 Step 只读这个快照；不允许写。
type VocabularySnapshot struct {
    Version   string
    Entries   map[string]*VocabularyEntry      // 浅 copy
    Relations map[string][]*VocabularyRelation  // 浅 copy
}
```

### 4.4 EnhancementContext（per-request 不可变 Builder）

```go
// EnhancementContext 是单次增强请求的全部可变状态。
// 通过 Builder 构造；构造后 Text/Vocab/Policy 不可改，
// Changes/lockedSpans 仅 append-only。
type EnhancementContext struct {
    RawText      string                 // 原始文本（不可变）
    Text         string                 // 当前文本（步骤原地修改）
    Vocab        *VocabularySnapshot    // 不可变快照
    Policy       *Policy                // 不可变策略
    Changes      []Change               // append-only
    LockedSpans  []string               // append-only
    Timings      map[string]time.Duration // append-only
    Canceled     bool                   // 取消标志
}

// NewEnhancementContext（Builder 模式）保证 RawText/Text/Vocab/Policy 一致性。
func NewEnhancementContext(rawText string, vocab *VocabularySnapshot, policy *Policy) *EnhancementContext
```

### 4.5 Observer

```go
// StepObserver 监听步骤生命周期事件；不修改 Pipeline 主体。
type StepObserver interface {
    OnStepStart(ctx context.Context, name string)
    OnStepComplete(ctx context.Context, name string, dur time.Duration, changes []Change)
    OnStepError(ctx context.Context, name string, err error)  // 预留；目前 warn 不返回 error
    OnPipelineComplete(ctx context.Context, result *EnhancementResult)
}
```

```go
// 默认实现：LoggingObserver（写到 kratos log）
type LoggingObserver struct{ log *log.Helper }
func (o *LoggingObserver) OnStepStart(...) { o.log.WithContext(ctx).Debugf(...) }
// ... 其他方法
```

### 4.6 ObservingStep（Decorator）

```go
// ObservingStep 是装饰器：包装任意 Step 注入 Observer 调用。
// 解决「每个 Step 内部重复埋点」问题。
type ObservingStep struct {
    inner    EnhancementStep
    observers []StepObserver
}

func (s *ObservingStep) Name() string { return s.inner.Name() }
func (s *ObservingStep) Apply(ctx context.Context, ec *EnhancementContext) {
    t0 := time.Now()
    for _, o := range s.observers { o.OnStepStart(ctx, s.inner.Name()) }
    s.inner.Apply(ctx, ec)  // 不捕获 error（warn 模式）
    dur := time.Since(t0)
    // 取本次步骤新增的 changes（按长度差）
    for _, o := range s.observers {
        o.OnStepComplete(ctx, s.inner.Name(), dur, nil)
    }
}
```

### 4.7 Pipeline + Factory

```go
// Pipeline 是 8 步序列；构造后不可变。
type Pipeline struct {
    steps    []EnhancementStep  // 已经过 ObservingStep 装饰
    policy   *Policy
    log      *log.Helper
}

// Run 顺序执行所有启用的步骤。
// 设计要点：
//   1. 入口检查 ctx.Err()
//   2. 每步在 ObservingStep 包装下执行（埋点统一）
//   3. ctx 取消时跳出循环
//   4. 返回 EnhanceResult（包含 status / timings / changes）
func (p *Pipeline) Run(ctx context.Context, ec *EnhancementContext) (*EnhanceResult, error) {
    for _, step := range p.steps {
        if err := ctx.Err(); err != nil { ec.Canceled = true; break }
        if !p.policy.IsEnabled(step.Name()) { continue }
        step.Apply(ctx, ec)
    }
    // ... 拼装 EnhanceResult
}
```

```go
// BuildPipeline 是 Factory：按 Policy + deps 构造完整 Pipeline。
//
// 所有 Step 通过依赖注入（不允许 Step 内部加载资源）。
// 工厂签名清晰：哪个 Step 需要什么资源一眼可见。
func BuildPipeline(
    policy *Policy,
    observers []StepObserver,
    log *log.Helper,
) *Pipeline {
    var rawSteps []EnhancementStep
    if policy.IsEnabled("cleaning") {
        rawSteps = append(rawSteps, TextCleaningStep{})
    }
    if policy.IsEnabled("filler") {
        rawSteps = append(rawSteps, FillerStep{})
    }
    // ... 共 9 个步骤（M6 设计 + 未来 LLM 步骤）
    if policy.IsEnabled("llm_reserved") && policy.LLMEnabled {
        rawSteps = append(rawSteps, LLMReservedStep{})
    }

    // Decorator 包装
    steps := make([]EnhancementStep, len(rawSteps))
    for i, s := range rawSteps {
        steps[i] = &ObservingStep{inner: s, observers: observers}
    }

    return &Pipeline{steps: steps, policy: policy, log: log}
}
```

### 4.8 Engine

```go
// EnhancementEngine 编排：build 不可变 snapshot → run pipeline。
//
// 不持有 mutable state；所有 per-request 数据走 EnhancementContext。
type EnhancementEngine struct {
    builder   *VocabularyBuilder
    pipeline  *Pipeline  // 启动时构造一次，Flyweight 共享
    observers []StepObserver
    log       *log.Helper
}

// Enhance 一次文本增强请求。
//
// 调用方负责：
//   - ctx 超时控制（context.WithTimeout）
//   - vocab snapshot 来源（VocabularyBuilder.Build(ctx, tenantID)）
//   - policy 选择（按 profile_id 选；M6 默认 STANDARD）
func (e *EnhancementEngine) Enhance(ctx context.Context, rawText string, policy *Policy) (*EnhanceResult, error) {
    vocab, err := e.builder.Build(ctx, getTenantIDFromContext(ctx))  // 一次性不可变快照
    if err != nil { return nil, err }

    ec := NewEnhancementContext(rawText, vocab, policy)
    return e.pipeline.Run(ctx, ec)
}
```

**注意**：`getTenantIDFromContext(ctx)` 是 Helper，从 `data.AuthInfoFromContext(ctx).TenantID` 取。这**不属于** Processor 内部硬编码资源加载（EnhancementEngine 是编排层，不是 Step；Step 内部不允许这样做）。

---

## 五、文件结构

```
internal/biz/
├── enhancement.go                # Policy + EnhancementEngine + Pipeline
├── enhancement_context.go        # EnhancementContext + Builder
├── enhancement_steps.go          # 9 个 Flyweight Step 集中定义
├── enhancement_observer.go       # StepObserver + LoggingObserver + ObservingStep
└── enhancement_inference.go      # Pinyin/Fuzzy/Context 等推断 Step（独立文件保持可读）
```

| 文件 | 包含的 Pattern | 关键类型 |
|---|---|---|
| enhancement.go | Strategy + Factory + Pipeline | `Policy`, `Pipeline`, `EnhancementEngine`, `BuildPipeline` |
| enhancement_context.go | Builder | `EnhancementContext`, `NewEnhancementContext` |
| enhancement_steps.go | Flyweight + Pipeline | 9 个 `Step` 实现 |
| enhancement_observer.go | Observer + Decorator | `StepObserver`, `LoggingObserver`, `ObservingStep` |
| enhancement_inference.go | Flyweight | 推断 Step（pinyin/fuzzy/context） |

---

## 六、关键不变量检查清单

| 不变量 | 实现位置 | 验证方式 |
|---|---|---|
| **无全局可变状态** | `Pipeline.steps` 在工厂构造后只读；`Step` 是空 struct | `go vet -cop` 静态检查；code review |
| **无 Processor 内部资源加载** | `Step.Apply(ctx, ec)` 签名；ec 已含所有依赖 | grep `Apply` 函数体内不允许出现 I/O / ctx 取租户 / 全局变量访问 |
| **无继承** | 全部组合（接口嵌入、struct 值嵌入）| grep `struct.*\.Apply` 不允许出现在子 struct 中 |
| **取消传播** | `Pipeline.Run` 入口 + 每 Step 内 select | context propagation 测试 |
| **不可变快照** | `EnhancementContext` 字段无 setter；`Vocab` 是 copy | race detector + vet |
| **Observer 不修改业务** | `StepObserver` 接口无返回值 | Observer 修改 ec 应导致 vet 失败 |
| **不破坏现有协议** | `EnhanceResult` 字段保持原 evie/service 形态 | 单测对照 10 个 case |

---

## 七、单元测试矩阵（M6 验收）

| 测试 | 验证点 |
|---|---|
| `TestPipeline_Run_AllSteps` | 8 层流水线全跑通；changes 顺序正确 |
| `TestPipeline_PolicyFilter` | Policy 关闭某步后该步不执行 |
| `TestPipeline_CancelPropagation` | ctx 取消后 Pipeline 提前退出；Changes 标记 canceled |
| `TestObservingStep_Decorator` | inner.Apply 调用前后 observer 都被调用 |
| `TestEnhancementContext_Builder_Immutability` | 构造后修改 RawText 不影响 ec |
| `TestFlyweight_ZeroSize` | `unsafe.Sizeof(TextCleaningStep{})` == 0（编译期断言）|
| `TestNoGlobalState` | 并发 100 goroutine 跑 Pipeline 不出现 race |
| `TestPolicy_NilIsDefault` | nil policy 等价于「全部启用」 |
| 现有 10 个 case（Case 1~8 + 别名/拼音/模糊）| 与 evie/service 算法一致 |

**集成测试**：

- `TestEnhancementEngine_EndToEnd` — 拿真实 qua 数据 → Normalizer → VocabularyBuilder.Build → Pipeline.Run → 检查 raw_text → enhanced_text 与预期一致

---

## 八、与现有 evie/service 代码的差异

| 维度 | evie/service 现状 | evie/tool M6 新设计 |
|---|---|---|
| 步骤存放 | 1 个文件 9 个 Step + 1 个 Engine | 拆 4 个文件（context/steps/observer/inference）|
| 状态追踪 | `EnhancementContext.lockedSpans []string` append | 显式 Builder + append-only |
| 资源访问 | `authn.GetAuthUserTenantID(ctx)` 在 Enhance 内部 | Engine 编排层；Step 内部禁止 |
| 步骤接口 | `Process(ctx *EnhancementContext) error`（Step 内部返回 error）| `Apply(ctx, ec)`（无返回值，warn 模式）|
| 计时 | `enhance()` 内 `time.Since(t0)` 拼装 | ObservingStep Decorator 统一埋点 |
| Pipeline 构造 | `e.steps = append(e.steps, &TextCleaningStep{}, ...)` 在 NewEnhancementEngine | `BuildPipeline(policy, observers, log)` 工厂 |
| Observer | 无 | StepObserver + LoggingObserver + ObservingStep |

**算法完全复用**（逻辑不变）：

- `TextCleaningStep` / `FillerStep` / `VocabularyMatchingStep` / `AliasResolutionStep` /
  `DeterministicReplacementStep` / `PhraseStandardizationStep` / `PinyinCorrectionStep` /
  `FuzzyMatchingStep` / `ContextCorrectionStep` 的核心算法（一行不删）照搬 evie/service
- 仅调整签名（`Process` → `Apply`）和错误处理（`return err` → 内部 warn + 跳过）

---

## 九、请你确认的设计取舍

| # | 决策 | 我的默认 | 你的选择 |
|---|---|---|---|
| 1 | 步骤 `Apply` 返回 `error` 还是无返回 | **无返回**（warn 模式，与 C 一致）| ☐ 无返回 ☐ 返回 error |
| 2 | 步骤是否内嵌「正则/词典」等只读资源 | **禁止内嵌**（依赖通过 `ec.Vocab` / 静态包变量）；正则/词典可放包级 `var`，但通过 `sync.Once` 初始化 | ☐ 仅包级 var + sync.Once ☐ 放进 Step 字段 |
| 3 | LLM 步骤占位实现 | **永远 no-op**（`Apply` 直接返回，不读 ec）；`policy.LLMEnabled=true` 才注册 | ☐ 永远 no-op ☐ 预留 HTTP 客户端 |
| 4 | Observer 默认行为 | **LoggingObserver**（Debug 级别打印 step name + duration）| ☐ Logging ☐ 无默认 ☐ Prometheus |
| 5 | Pipeline 是否可被多 goroutine 并发 Run | **是**（Pipeline 不可变；ec per-request）| ☐ 安全并发 ☐ 需 mutex |
| 6 | 装饰器是否默认启用 | **是**（BuildPipeline 内部统一包装；observers 可空 slice）| ☐ 默认启用 ☐ 显式 opt-in |
| 7 | 现有 10 个 case 算法对照 | **一字不改**（只调整签名 + 错误处理）| ☐ 一字不改 ☐ 允许微调 |

---

## 十、若确认后的实施计划

```
M6a · 类型骨架（1 个 PR）
  ├─ enhancement_context.go（Builder + 不可变）
  ├─ enhancement_observer.go（Observer + Decorator）
  ├─ enhancement_steps.go（9 个 Flyweight Step 骨架 + TestFlyweight_ZeroSize）
  └─ 验收：go build + 单测全绿

M6b · 业务实现（1 个 PR）
  ├─ 复用 evie/service 算法（enhancement.go + enhancement_inference.go 复制）
  ├─ 调整签名 Process → Apply；error → warn 内部处理
  └─ 验收：10 个 case 全绿

M6c · 编排层（1 个 PR）
  ├─ Policy + BuildPipeline + Pipeline.Run + EnhancementEngine
  ├─ VocabularySnapshot 类型（biz/vocabulary.go 精简版）
  └─ 验收：TestPipeline_* / TestEnhancementEngine_EndToEnd 全绿

M6d · wire 装配 + Admin 同步状态接口
  ├─ biz.ProviderSet 注入 NewEnhancementEngine
  ├─ 词库同步状态接口（M5 阶段）
  └─ 验收：make wire + make run 跑通
```

确认后我按 M6a → M6b → M6c → M6d 顺序生成代码，每步跑通 `go build + go test -race` 后再进入下一步。