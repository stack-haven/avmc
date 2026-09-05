# Evie Tool · 外部 API 接入 `pkg` 抽取设计

> **状态**：📋 设计确认中（请用户 review 后再生成代码）
> **触发**：用户反馈——`data/qua_client.go` + `data/qua_source.go` 的「外部 API → opaque → 内部类型」模式会反复出现，应抽到 `pkg/` 通用工具。
> **适用范围**：本工具内 qua / 飞书 / LDAP / OIDC / CSV / 后续所有外部数据源
> **设计原则**：Q13 决定的「不与具体外部系统耦合」继续贯彻

---

## 一、需求与现状

### 1.1 复用的痛点（用 qua_client.go 举例）

当前 `data/qua_client.go` 含大量**与 qua 无关**的样板代码：

| 样板 | 出现位置 | 复用场景 |
|---|---|---|
| HTTP client + timeout | `NewQuaClient` | 任何外部 HTTP |
| `Authorization: Bearer` 透传 | `applyCommonHeaders` | 任何 OAuth/JWT 系统 |
| `tenant-id` header 注入 + 字符串→int 转换 | `applyCommonHeaders` | 任何多租户 SaaS |
| 静态 header（`zone` 等）合并 | `applyCommonHeaders` | 任何带固定 header 的 API |
| Spring Cloud 风格 `{code, msg, data}` 响应壳 | `do` | RuoYi/Jeecg/Spring Cloud 99% 系统 |
| 业务码 → 错误映射 | `mapQuaBusinessError` | 任何带业务码的 API |
| Opaque `[]map[string]any` 返回 | `FetchUsersRaw` | 任何 list-style 响应 |
| `url.Values` 拼装（`selectAll=true`）| `FetchUsersRaw` | 任何带 query 的 API |

未来加飞书、钉钉、企微、OIDC、CSV/LDAP 同步，**这些样板至少 70% 会重复出现**。

### 1.2 已有的相关 `pkg/`（避免重复造轮子）

| 包 | 用途 | 是否够用 |
|---|---|---|
| `pkg/auth/authn` | JWT 验签、Claims、SecurityUser | 不够（qua 不用 JWT 验签）|
| `pkg/auth/middleware` | Bearer 中间件 | 不够（已自实现，理由见 M2）|
| `pkg/utils/convert` | 类型转换、`ToPointer` 等 | 部分够；无 HTTP 相关 |
| `pkg/objectstorage` | S3-compatible 存储 | 不适用 |
| `pkg/aip` | 分页 / 过滤 | 不适用 |
| `pkg/middleware` | kratos 中间件 | 不适用 |
| `app/platform/service/client` | platform gRPC client 模板 | 仅 gRPC，不通用 HTTP |

**结论**：**新设计两个 `pkg/`**：
- `pkg/extapi/` — 外部 HTTP API 集成工具（核心复用）
- `pkg/expr/` — dot-path 访问 + 简单条件求值（Normalizer 依赖抽取）

---

## 二、目标与不目标

### 2.1 目标（G）
1. **G1**：任何外部 HTTP API（qua / 飞书 / 企微 / OIDC ...）通过 `pkg/extapi` 集成，**只写 1 份 endpoint 配置 + 1 份错误映射**，无 HTTP 样板
2. **G2**：Header 注入（Bearer / 多租户 ID / 静态 header）是可插拔的 HeaderProvider，新增系统无需改 pkg
3. **G3**：业务码 → 错误映射通过 `BusinessErrorMapper` 接口注入，qua / 飞书各自实现
4. **G4**：返回 `Opaque`（`map[string]any`）和 `OpaqueList`（`[]map[string]any`）是统一产物，下游 Normalizer/Adapter 消费
5. **G5**：`pkg/expr` 的 dot-path + 简单条件求值被 Normalizer 复用，同时未来 `pkg/transform`（规则映射框架）也可复用
6. **G6**：Context 取消传播、超时控制、retry 策略全部走 `context.Context` 链路

### 2.2 不目标（NG）
1. **NG1**：不引入新的 HTTP 框架（基于 `net/http` 即可）
2. **NG2**：不绑定具体外部系统（qua / 飞书名字一律不出现在 `pkg/extapi`）
3. **NG3**：不做完整 CEL 表达式引擎（`pkg/expr` 仅支持 `==` / `!=` / 真值单 token，与 C 决定一致）
4. **NG4**：不实现 response caching / circuit breaker（留给调用方；M9 收口期考虑）
5. **NG5**：不做 streaming response（流式 ASR 由 `pkg/asr` 自身处理，不走 extapi）

---

## 三、架构与包结构

### 3.1 新增 `pkg/` 目录

```text
backend-service/pkg/
├── extapi/                       # 本次新增
│   ├── client.go                 # 核心 Client + Option 模式
│   ├── headers.go                # HeaderProvider 接口 + 常用实现
│   ├── decoder.go                # ResponseDecoder + JSON 业务码响应壳
│   ├── errors.go                 # 业务错误包装 (ErrorUnreachable/InvalidResponse/...)
│   ├── retry.go                  # RetryPolicy (简单指数退避)
│   ├── logger.go                 # 内部 Logger 接口（避免依赖 kratos）
│   ├── client_test.go            # httptest 覆盖核心场景
│   └── README.md
│
├── expr/                         # 本次新增
│   ├── path.go                   # dot-path 访问
│   ├── condition.go              # 简单条件求值
│   ├── convert.go                # toInt32 / isTruthy
│   ├── path_test.go
│   └── condition_test.go
│
└── (现有包不动)
```

### 3.2 数据流

```text
┌─────────────────────────────────────────────────────────────────┐
│ biz 层（领域知识）                                                  │
│   Normalizer（rule-based） + QuaSource（adapter）                 │
│        ▲                                                           │
│        │ Opaque / OpaqueList                                       │
│        │                                                           │
│   pkg/extapi · Client                                             │
│   ├─ HTTP client (timeout/retry)                                 │
│   ├─ HeaderProvider chain (Bearer / tenant-id / static)          │
│   ├─ RequestBuilder (URL + query)                                 │
│   └─ ResponseDecoder (JSON envelope {code,msg,data})              │
│        ▲                                                           │
│        │ http.Request / http.Response                              │
│        │                                                           │
│   外部系统（qua / 飞书 / OIDC / LDAP / CSV...）                   │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 与 qua 的关系

qua 集成从「写满 200 行 boilerplate」压缩到「30 行 endpoint 配置 + 1 份错误映射」：

```go
// 重构后的 data/qua_client.go（伪代码，最终代码待你确认后生成）
func NewQuaClient(c *conf.Qua, logger log.Logger) (QuaFetcher, error) {
    client, err := extapi.NewClient(c.GetBaseUrl(),
        extapi.WithTimeout(c.GetTimeout().AsDuration()),
        extapi.WithHeaderProviders(
            &BearerFromContext{},       // 从 AuthInfo 取 token
            &TenantIDFromContext{},     // 字符串→int 转换
            &extapi.StaticHeaderProvider{Headers: c.GetExtraHeaders()},
        ),
        extapi.WithBusinessError(mapQuaBusinessError),
    )
    if err != nil { return nil, err }
    return &quaClient{client: client, endpoints: c.GetEndpoints()}, nil
}
```

---

## 四、`pkg/extapi` 详细设计

### 4.1 核心类型

```go
// pkg/extapi/client.go
package extapi

// Opaque 是从外部 API 返回的不透明负载（典型为 JSON object）。
type Opaque = map[string]any

// OpaqueList 是 Opaque 的列表（典型为 JSON array of objects）。
type OpaqueList []Opaque

// Client 是外部 HTTP API 集成的核心入口。
//
// 构造方式：NewClient(baseURL, opts...).
// 用法：Fetch / FetchOpaque / FetchOpaqueList。
//
// 设计要点：
//   1. 不可变：构造后所有字段只读（除内部 http.Transport 由 std 库管理）
//   2. 并发安全：Client 本身可被多 goroutine 共享
//   3. HeaderProvider 链：每次请求按序合并（后注册的覆盖前注册的同名 header）
//   4. 不绑定任何具体外部系统
type Client struct {
    baseURL     string
    httpClient  *http.Client
    headers     []HeaderProvider
    decoder     ResponseDecoder
    retry       RetryPolicy
    log         Logger
}

// Option 客户端配置函数。
type Option func(*Client)

func NewClient(baseURL string, opts ...Option) (*Client, error)

// Fetch 通用请求：发请求 + 解码响应到 out。
// out 必须指向一个包含 {code, msg, data} envelope 的 struct（或由 decoder 自定义）。
func (c *Client) Fetch(ctx context.Context, method, endpoint string, query url.Values, body io.Reader, out any) error

// FetchOpaque 请求并返回 envelope.data 作为 Opaque。
// 适用场景：调用方不关心具体 schema，下游用 dot-path 访问。
func (c *Client) FetchOpaque(ctx context.Context, method, endpoint string, query url.Values, body io.Reader) (Opaque, error)

// FetchOpaqueList 请求并返回 envelope.data 作为 OpaqueList。
// 适用场景：列表型接口（users / depts / products ...）。
func (c *Client) FetchOpaqueList(ctx context.Context, method, endpoint string, query url.Values, body io.Reader) (OpaqueList, error)

// BuildURL 拼接 baseURL + endpoint + query。
func (c *Client) BuildURL(endpoint string, query url.Values) string
```

### 4.2 HeaderProvider 接口

```go
// pkg/extapi/headers.go
package extapi

// HeaderProvider 在每次请求前注入请求级 header。
//
// 典型实现：
//   - BearerFromContext：从 ctx 拿 token → "Authorization: Bearer ..."
//   - TenantIDFromContext：从 ctx 拿 tenantID（自动字符串→int 转换）
//   - StaticHeaderProvider：固定 header（不依赖 ctx）
type HeaderProvider interface {
    Headers(ctx context.Context) (map[string]string, error)
}

// HeaderProviderFunc 函数适配器（避免每次写 struct）。
type HeaderProviderFunc func(ctx context.Context) (map[string]string, error)
func (f HeaderProviderFunc) Headers(ctx context.Context) (map[string]string, error) { return f(ctx) }

// StaticHeaderProvider 固定 header（zone / user-agent / ...）。
type StaticHeaderProvider struct{ Headers map[string]string }
func (p *StaticHeaderProvider) Headers(ctx context.Context) (map[string]string, error) {
    return p.Headers, nil
}

// BearerFromContext 通用 Bearer header 提取器。
// 要求 ctx 里有 authn.SecurityUser 或自定义 ctxKey。
// 由调用方在 NewClient 时通过工厂函数注入（本包不依赖 authn.SecurityUser 的具体形态）。
type BearerFromContext struct {
    // ExtractToken 从 ctx 取 Bearer token。
    ExtractToken func(ctx context.Context) (string, error)
}
func (p *BearerFromContext) Headers(ctx context.Context) (map[string]string, error) {
    token, err := p.ExtractToken(ctx)
    if err != nil { return nil, err }
    if token == "" { return nil, nil }  // 静默跳过（适用于无 auth 场景）
    return map[string]string{"Authorization": "Bearer " + token}, nil
}

// IntHeaderProvider 通用「字符串字段→int header」提取器。
// 适用场景：Spring Cloud 系 API 的 tenant-id / companyId 等数字 header。
type IntHeaderProvider struct {
    HeaderName string                           // "tenant-id" / "companyId"
    ExtractString func(ctx context.Context) (string, error)
}
func (p *IntHeaderProvider) Headers(ctx context.Context) (map[string]string, error) {
    s, err := p.ExtractString(ctx)
    if err != nil { return nil, err }
    if s == "" { return nil, nil }
    n, err := strconv.ParseInt(s, 10, 64)
    if err != nil {
        // 不阻断：异常 tenantId 原样写入；qua 端 401/403 由 HTTP 错误层处理
        return map[string]string{p.HeaderName: s}, nil
    }
    return map[string]string{p.HeaderName: strconv.FormatInt(n, 10)}, nil
}
```

### 4.3 ResponseDecoder 与业务错误

```go
// pkg/extapi/decoder.go
package extapi

// ResponseDecoder 解释 HTTP 响应。
type ResponseDecoder interface {
    // DecodeStatus 解析 envelope；返回 (status, bodyShouldDecode)。
    // bodyShouldDecode=false 时 Fetch/FetchOpaque 直接返回 nil。
    DecodeStatus(resp *http.Response) (*ResponseStatus, error)
    // DecodePayload 把 resp.Body 解码到 out。
    DecodePayload(resp *http.Response, out any) error
}

// ResponseStatus 是 envelope 解析结果。
type ResponseStatus struct {
    Code      int32
    Message   string
    Retryable bool
    Ok        bool  // envelope.code==0 时 true
}

// BusinessErrorMapper 把外部业务码映射到本工具错误（kratos errors）。
type BusinessErrorMapper func(status *ResponseStatus) error

// EnvelopeResponseDecoder 是默认 decoder。
// 假设响应形态：{"code":0, "msg":"ok", "data":{...}} 或 {"code":0, "data":[...]}。
type EnvelopeResponseDecoder struct {
    // BusinessError 把 envelope.code != 0 转为 kratos error。
    BusinessError BusinessErrorMapper
    // EnvelopeCodeField / EnvelopeMsgField / EnvelopeDataField 可定制字段名（默认 "code"/"msg"/"data"）。
    EnvelopeCodeField string
    EnvelopeMsgField  string
    EnvelopeDataField string
}

// JSONResponseDecoder 是 decoder 基础（envelope 外层 + 内层 data）。
// 解析逻辑：
//   1. ReadAll(body)
//   2. unmarshal to envelope struct
//   3. 检查 envelope.code：==0 → ok；!=0 → 调 BusinessError
//   4. 二次 unmarshal to out（仅取 data 字段）
type JSONResponseDecoder struct {
    EnvelopeResponseDecoder
}

func (d *JSONResponseDecoder) DecodeStatus(resp *http.Response) (*ResponseStatus, error) { ... }
func (d *JSONResponseDecoder) DecodePayload(resp *http.Response, out any) error { ... }
```

### 4.4 错误类型

```go
// pkg/extapi/errors.go
package extapi

import "github.com/go-kratos/kratos/v2/errors"

// 错误码（与现有 evie/tool 的 v1.ErrorQuaXxx 风格一致；用通用名以便任何外部系统复用）
const (
    CodeUnreachable    = "EXTERNAL_UNREACHABLE"     // HTTP 请求失败 / 超时
    CodeInvalidResponse = "EXTERNAL_INVALID_RESPONSE" // 响应非 JSON / envelope 缺失
    CodeBusinessError   = "EXTERNAL_BUSINESS_ERROR"   // envelope.code != 0
)

func ErrorUnreachable(format string, args ...any) *errors.Error {
    return errors.New(502, CodeUnreachable, fmt.Sprintf(format, args...))
}
func ErrorInvalidResponse(format string, args ...any) *errors.Error {
    return errors.New(502, CodeInvalidResponse, fmt.Sprintf(format, args...))
}
// 业务错误不预设，由 BusinessErrorMapper 注入
```

### 4.5 Retry

```go
// pkg/extapi/retry.go
package extapi

// RetryPolicy 决定请求失败时是否重试。
type RetryPolicy interface {
    // NextDelay 返回 (shouldRetry, delay)；shouldRetry=false 表示放弃。
    NextDelay(attempt int, err error) (bool, time.Duration)
}

// NoRetry 默认策略：不重试。
type NoRetry struct{}
func (NoRetry) NextDelay(int, error) (bool, time.Duration) { return false, 0 }

// ExponentialBackoff 指数退避（attempt 从 1 开始）。
// 1→100ms, 2→200ms, 3→400ms, ...，最多 MaxAttempts 次；HTTP 5xx 或网络错误时重试。
type ExponentialBackoff struct {
    MaxAttempts int
    BaseDelay   time.Duration  // 默认 100ms
    MaxDelay    time.Duration  // 默认 5s
    Retryable   func(err error) bool  // 默认：网络错误或 5xx
}
```

### 4.6 Logger 接口（避免依赖 kratos）

```go
// pkg/extapi/logger.go
package extapi

// Logger 极简接口（包级小鸭子类型，避免直接依赖 kratos）。
type Logger interface {
    Warnf(format string, args ...any)
    Errorf(format string, args ...any)
    Debugf(format string, args ...any)
}

// DiscardLogger 静默实现（用于测试 / 不需要日志的场景）。
type DiscardLogger struct{}
func (DiscardLogger) Warnf(string, ...any)  {}
func (DiscardLogger) Errorf(string, ...any) {}
func (DiscardLogger) Debugf(string, ...any) {}
```

### 4.7 Option 集合

```go
// pkg/extapi/client.go

func WithTimeout(d time.Duration) Option
func WithHTTPClient(hc *http.Client) Option
func WithHeaderProviders(hps ...HeaderProvider) Option
func WithResponseDecoder(rd ResponseDecoder) Option
func WithBusinessError(mapper BusinessErrorMapper) Option  // 便捷：包装默认 JSONDecoder
func WithRetry(rp RetryPolicy) Option
func WithLogger(l Logger) Option
```

### 4.8 测试覆盖

| 测试 | 验证点 |
|---|---|
| `TestClient_FetchOpaque_Success` | envelope 正确解包，data 字段返回 |
| `TestClient_FetchOpaqueList_Success` | 列表 envelope 解包 |
| `TestClient_HeaderProviders_Merge` | 多 provider 同名 header 后注册覆盖先注册 |
| `TestClient_ContextCancel` | ctx 取消后请求立即停止 |
| `TestClient_BusinessError_Mapping` | envelope.code=401 走 mapper |
| `TestClient_Retry_5xx` | 5xx 触发指数退避重试 |
| `TestClient_Timeout` | 慢响应触发 ErrorUnreachable |
| `TestClient_InvalidJSON` | 非 JSON 响应返回 ErrorInvalidResponse |
| `TestIntHeaderProvider_Conversion` | "158" → "158"（已 int）；"abc" → "abc"（透传）|
| `TestIntHeaderProvider_Missing` | 空值不写入 header |

---

## 五、`pkg/expr` 详细设计

### 5.1 目标

把 `biz/vocab_normalizer.go` 里的 `lookupPath` / `evalCondition` / `toInt32` / `isTruthy` 抽到 pkg，使任何规则型 mapping 都能复用。

### 5.2 核心类型

```go
// pkg/expr/path.go
package expr

// Path 按 dot-path 在嵌套 map 中查找。
//
//   "realName"             → data["realName"]
//   "user.realName"        → data["user"]["realName"]
//
// 返回 string 值（非 string 用 fmt.Sprint 转）+ ok。
// nil/缺字段 → ("", false)。
func Path(data map[string]any, path string) (string, bool)

// Set 按 dot-path 在嵌套 map 中写入（用于测试 fixture）。
// 中间 map 不存在则自动创建。
func Set(data map[string]any, path string, value any) error

// MustPath 同 Path，但缺字段时 panic（仅测试使用）。
func MustPath(data map[string]any, path string) string
```

```go
// pkg/expr/condition.go
package expr

// EvalCondition 评估简单条件。
//
// 语法：
//   ""                 → true（空 = 总是通过）
//   "field"            → 真值判断（lookup + isTruthy）
//   "field==value"     → 字符串相等（右侧字面量支持 'foo' / "foo" 自动去引号）
//   "field!=value"     → 不等
//
// 错误：语法错（不支持的运算符）。
// 字段缺失：==false / !=true（更安全的默认）。
func EvalCondition(expr string, data map[string]any) (bool, error)

// IsTruthy 判断字符串是否代表 truthy。
// 规则：空 / "0" / "false" / "null" / "nil"（不区分大小写）= false；其他 = true。
func IsTruthy(s string) bool

// ToInt32 统一字符串/数字/布尔为 int32。
// 无法解析返回 0。
func ToInt32(v any) int32
```

### 5.3 与 Normalizer 的关系

重构后 `biz/vocab_normalizer.go` 改为薄包装：

```go
// 简化后
import "backend-service/pkg/expr"

func lookupPath(data map[string]any, path string) (string, bool) {
    return expr.Path(data, path)
}

func evalCondition(expr string, data map[string]any) (bool, error) {
    return expr.EvalCondition(expr, data)
}

// toInt32 / isTruthy 直接调 pkg
```

**好处**：
- Normalizer 测试覆盖到的 edge case 全部转给 `pkg/expr` 测试
- 未来任何规则型 mapping（不只是 vocab）直接复用

### 5.4 测试覆盖

| 测试 | 验证点 |
|---|---|
| `TestPath_OneLevel` | `data["name"]` |
| `TestPath_TwoLevel` | `data["user"]["name"]` |
| `TestPath_NotFound` | 缺字段返 ("", false) |
| `TestPath_NonStringValue` | int/bool 走 fmt.Sprint |
| `TestSet_AutoCreate` | 中间 map 自动建 |
| `TestEvalCondition_Empty` | 空表达式 = true |
| `TestEvalCondition_Equals_String` | 'foo' 自动去引号 |
| `TestEvalCondition_NotEquals` | != 通过 |
| `TestEvalCondition_Truthy` | 单 token 真值判断 |
| `TestEvalCondition_FieldMissing` | 缺字段 = false |
| `TestToInt32_AllTypes` | int/int32/int64/float64/string/bool 全覆盖 |
| `TestIsTruthy` | 真值表 |

---

## 六、对现有代码的重构迁移

### 6.1 `data/qua_client.go` 迁移前后

| 维度 | 当前（迁移前） | 迁移后 |
|---|---|---|
| 文件行数 | ~200 | ~80 |
| HTTP client | 手工创建 | `extapi.NewClient` |
| Header 注入 | 手工 `applyCommonHeaders` | `HeaderProvider` 链 |
| 响应解析 | 手工 `do()` + envelope 反序列化 | `Client.FetchOpaque` |
| 错误映射 | `mapQuaBusinessError` 函数 | 注入 `extapi.WithBusinessError` |
| TenantID int 转换 | 内部 if-else | `IntHeaderProvider` 复用 |
| Qua-specific 代码 | 散落 | 集中到 `quaClient` struct 内的 endpoint |

**关键不变量**：quaClient 仍实现 `QuaFetcher` 接口；上游 `qua_source.go` 不需要改。

### 6.2 `data/qua_source.go` 迁移

无需迁移——`quaSource` 是 opaque → RawEntity 的 adapter，依赖 `map[string]any`，与 HTTP 层解耦。但可以**同时演进**：

- 引入 `pkg/transform`（如 M5 决定要做规则框架）后，quaSource 仍可继续工作
- adapter 的 "extractStringID" 等工具方法可考虑迁到 `pkg/extract`（如果别处也用得到）

### 6.3 `biz/vocab_normalizer.go` 迁移

| 内部函数 | 迁移后位置 |
|---|---|
| `lookupPath` | `pkg/expr.Path` |
| `evalCondition` | `pkg/expr.EvalCondition` |
| `toInt32` | `pkg/expr.ToInt32` |
| `isTruthy` | `pkg/expr.IsTruthy` |
| `unquoteLiteral` | `pkg/expr.unquoteLiteral`（私有 → 公开）|

Normalizer 本身保留（它负责组装规则 + 处理业务逻辑；不抽到 pkg）。

### 6.4 依赖关系重构

```text
迁移前:
  biz/vocab_normalizer.go   → data/qua_client.go
                            → data/qua_source.go

迁移后:
  pkg/expr  ←── biz/vocab_normalizer.go
       ↑
  pkg/extapi ←── data/qua_client.go（仅配置层）
                    ↓
              data/qua_source.go（不变）
```

---

## 七、可复用性矩阵

| 外部系统 | 集成成本（当前） | 集成成本（迁移后） | 节省 |
|---|---|---|---|
| qua | 200 行 | 30 行 + YAML | 85% |
| 飞书（自建应用）| 同样 200 行 | 30 行 + 自定义 HeaderProvider | 85% |
| 钉钉 | 同样 | 30 行 | 85% |
| OIDC userinfo | 同样 | 30 行 | 85% |
| LDAP | 不适用（不同协议）| 不适用；但规则映射可复用 `pkg/expr` | - |
| CSV 文件 | 不适用（不同协议）| 写个 `FileSource` adapter + 规则 YAML | 60% |
| 飞书 webhook | 同 qua | 30 行 | 85% |

**核心节省点**：HTTP 样板 + header 处理 + 错误映射 + retry 全部归一。

---

## 八、与现有架构的一致性

| 规范 | 本设计的遵循情况 |
|---|---|
| `.agents/AGENTS.md` 公共函数复用 | `pkg/extapi` + `pkg/expr` 直接落到 pkg 公共层 |
| `.agents/AGENTS.md` 公共包索引 | README 中添加新包；后续项目可复用 |
| kratos skill 错误模式 | 用 `errors.New` 工厂；HTTP 错误统一 502；业务码可注入 |
| kratos skill Wire DI | 不引入新的 wire 概念（Client 是 data 层内部依赖）|
| kratos skill context 传播 | 所有方法第一个参数是 `context.Context` |
| Q13 决定（工具不耦合外部）| `pkg/extapi` 命名零外部系统痕迹；qua / 飞书名字只出现在 business layer |
| 三大禁止事项 | pkg/extapi 是无状态配置对象；无全局变量；零继承 |

---

## 九、风险与依赖

| 风险 | 缓解 |
|---|---|
| `pkg/extapi` 接口设计过于通用导致难用 | 限制为「单层 envelope + opaque payload」；不引入 streaming / GraphQL |
| `pkg/expr` 被滥用做完整表达式 | 文档明确「仅 dot-path + `==/!=/真值`」；M9 评估是否升级 |
| 迁移期间 qua 客户端出现回归 | 保留原 qua_client.go 单元测试（10 个 case）；extapi 测试用相同场景 |
| 性能：HeaderProvider 每次请求调一遍 | 单次请求 < 5 个 provider × O(1) map 合并；可忽略 |
| 与 platform service client 风格冲突 | platform client 是 gRPC；extapi 是 HTTP；互补不替代 |

---

## 十、请你确认的设计取舍

| # | 决策 | 我的默认 | 你的选择 |
|---|---|---|---|
| 1 | `pkg/extapi` 是否包含 retry | **包含**（默认 NoRetry，调用方按需开启 ExponentialBackoff）| ☐ 包含 ☐ 暂不实现 retry |
| 2 | `pkg/extapi` 是否包含 circuit breaker | **不包含**（M9 收口期再加；与 NG4 一致）| ☐ 不包含 ☐ 必须包含 |
| 3 | `pkg/expr` 是否单独成包 | **是**（dot-path + 简单条件是通用能力）| ☐ 是 ☐ 与 extapi 合并 |
| 4 | `pkg/extapi` 是否暴露 `Opaque` / `OpaqueList` 公开类型 | **是**（让 adapter 直接复用）| ☐ 是 ☐ 用匿名类型 |
| 5 | 是否同时迁移 `qua_client.go` / `vocab_normalizer.go` | **是**（一次性重构；测试覆盖原行为）| ☐ 是 ☐ 分两阶段 |
| 6 | HeaderProvider 是否支持请求级 body 注入 | **不**（body 在 Fetch 时传；HeaderProvider 只管 header）| ☐ 不支持 ☐ 必须支持 |
| 7 | retry 触发条件默认值 | **网络错误 + HTTP 5xx**；4xx 不重试（业务错误）| ☐ 默认值 ☐ 全部错误 |
| 8 | pkg/extapi 是否暴露 Logger 接口 | **是**（避免依赖 kratos；调用方传适配器）| ☐ 是 ☐ 直接用 kratos log |

---

## 十一、若确认后的实施计划

```
Pkg-1 · pkg/expr（1 个 PR）
  ├─ expr/path.go + condition.go + convert.go
  ├─ expr/*_test.go（12 个 case 全绿）
  └─ 验收：go build + go test -race

Pkg-2 · pkg/extapi（1 个 PR）
  ├─ extapi/client.go + headers.go + decoder.go + errors.go + retry.go + logger.go
  ├─ extapi/client_test.go（10+ 个 httptest case）
  └─ 验收：go build + go test -race

Pkg-3 · 重构 qua_client.go 使用 pkg/extapi（1 个 PR）
  ├─ data/qua_client.go 改造为薄包装
  ├─ 保留原 10 个测试 case 全绿（验证零行为变化）
  └─ 验收：go test -race

Pkg-4 · 重构 vocab_normalizer.go 使用 pkg/expr（1 个 PR）
  ├─ biz/vocab_normalizer.go 改为薄包装
  ├─ 保留原 12 个测试 case 全绿
  └─ 验收：go test -race

Pkg-5 · wire 装配更新 + README + 文档（1 个 PR）
  ├─ extapi/expr 包 README
  ├─ docs/services/evie-platform/development/13-… 更新
  └─ 验收：make wire + make build
```

预计净收益：未来加新外部系统（飞书/钉钉/OIDC/LDAP）节省 60~85% 集成代码；Normalizer 减少 ~100 行 boilerplate。

确认后我按 Pkg-1 → Pkg-2 → Pkg-3 → Pkg-4 → Pkg-5 顺序执行，每步跑通 `go build + go test -race` 后进入下一步。