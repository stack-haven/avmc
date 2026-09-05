# Evie Tool — 独立轻量语音识别增强工具 开发计划

日期：2026-09
状态：📋 开发计划（Q1~Q12 已确认）
事实来源：本文件
依赖：[8-词库中心与文本增强引擎开发计划](./8-词库中心与文本增强引擎开发计划.md)、[1-ASR语音识别服务](./1-ASR语音识别服务.md)

> **本计划的目的**：把 `app/evie/service` 已落地的「ASR + 8 层文本增强」核心能力**抽取并瘦身**为可独立运行的轻量级工具 `app/evie/tool`，对接**外部 qua 系统**（bdksim-pro-qua，Spring Cloud 风格 HTTP API）获取租户用户/部门，自动构建租户级运行时词库。
>
> **不重复**：菜单、后台管理页、Ent/数据库、操作审计、文件中心上传、Casbin 鉴权——这些都不在本工具范围内。

---

## 〇、Q1~Q12 确认结果汇总

| # | 决策 | 影响 |
|---|---|---|
| Q1 | qua = **外部 HTTP 系统** | tool 调用 qua 用 HTTP client，不引入 gRPC dep |
| Q2 | token value JSON 结构：`tenantId` / `id` / `accessToken` / `refreshToken` / `userId` / `userType` / `userInfo.nickname` / `userInfo.deptId` / `expiresTime` | 见 §3.1 `AuthInfo` |
| Q3 | 同时收 `nickname` + `realname`，**新增 `alias` 自定义字段**作为别名关系来源 | qua API 缺 alias → 透传 nickname+realname 合并；tool 内部新增 alias 来源标记 |
| Q4 | 全量 `no_paging=true` 拉取 | qua 用户接口需传 `selectAll=true`；部门接口不需要分页参数 |
| Q5 | 用户/部门接口**端点配置在 YAML**（确认的端点）： `GET /admin-api/system/dept/list`、`POST /admin-api/qua/member-extended/page?&selectAll=true` | qua.users_endpoint / qua.depts_endpoint 字段 |
| Q6 | qua 使用 **HTTP**（确认的请求头：authorization + tenant-id(数字) + zone） | `qua_client.go` 用 `net/http` + `qua.extra_headers` 静态透传 |
| Q7 | funasr（整段）+ xunfei（流式），配置开关。已确认讯飞凭证：host=iat-api.xfyun.cn / uri=/v2/iat / app_id=2d8c3dd7 | `asr.providers.{funasr,xunfei,whisper,aliyun}.enabled` |
| Q8 | 系统静态词条在 `backend-service/app/evie/tool/configs/dictionaries/system.json`，**热加载** | `system_dict.go` 监听 fsnotify |
| Q9 | **租户首次访问落地持久化** + 启动预加载 + 5min 周期同步 | `tenant_registry.go`（本地文件 `tenants.json`）+ 启动 warmup + ticker |
| Q10 | proto 独立在 `backend-service/proto/evie/tool/v1/` | `asr.proto` + `enhancement.proto` |
| Q11 | 音频永久保留 | 第一期不开发清理逻辑 |
| Q12 | **不落库**，仅日志 + 音频文件 | 无 Ent/MySQL/SQLite |
| Q13 | **外部解耦**：工具保持公共复用性，业务数据入口统一以**规则匹配**转换为**通用词条** NormalizedEntry，不与具体外部 API 字段耦合。未来业务接口变化或换其他系统（飞书/LDAP/CSV）可零核心代码复用 | VocabularySource 通用接口 + Normalizer（biz）+ YAML 规则（conf）；adapter（data）只负责包 RawEntity |

### 0.1 Q1~Q12 后续追加确认（联调后的精确化）

#### Q5 精确端点（qua 生产环境）

| 接口 | 方法 | URL | 说明 |
|---|---|---|---|
| 部门列表 | GET | `/admin-api/system/dept/list` | 一次返回该租户全部部门；不需要分页参数 |
| 用户列表 | POST | `/admin-api/qua/member-extended/page` | query: `selectAll=true`，一次返回全部成员 |
| 用户详情 | GET | `/admin-api/system/user/get`（预留） | 单用户查询 |
| 部门详情 | GET | `/admin-api/system/dept/get`（预留） | 单部门查询 |

**必需 header**（除 authorization 外）：

| Header | 取值 | 来源 |
|---|---|---|
| `tenant-id` | 数字（如 `158`） | `AuthInfo.TenantID`（字符串转 int64） |
| `zone` | `Asia/Shanghai`（静态） | `qua.extra_headers.zone` |

#### Q7 讯飞凭证已启用（默认值可直接启动联调）

| 字段 | 值 |
|---|---|
| host | `iat-api.xfyun.cn` |
| uri | `/v2/iat` |
| app_id | `2d8c3dd7` |
| api_key | `641cdc25afd21421685c6ec2ce24149c` |
| api_secret | `MWEyMzg2ODhiMThhY2E2MWJmZWQ4YjQ4` |

> **环境区分**：未来应通过 `conf.Asr.Providers.Xunfei.AppId/ApiKey/ApiSecret` 从环境变量覆写，不要在生产仓库提交真实凭证。当前值仅为联调样例。

### 0.2 路由策略

- 整段批量（≤60s）：走 `conf.Asr.DefaultBatchProvider` = `funasr`
- 实时流式（双向流）：走 `conf.Asr.DefaultStreamProvider` = `xunfei`
- 若首选 Provider `enabled=false`，降级到 `Providers` 中第一个 enabled

---

## 一、模块定位与边界

### 1.1 在 Ark Tech Platform 中的位置

```
┌──────────────────────────────────────────────────────────────┐
│        外部 qua 系统（bdksim-pro-qua，HTTP + Redis）           │
│  提供：Bearer Token 校验 + 租户用户列表 + 租户部门列表            │
└──────────────────────────────────────────────────────────────┘
                ▲ HTTP                    ▲ Redis (oauth2_access_token:<token>)
                │                         │
┌───────────────┴─────────────────────────┴────────────────────┐
│  Evie Tool（backend-service/app/evie/tool）                  │
│  作用：                                                         │
│    1) 校验 Bearer Token（Redis 查 oauth2_access_token:<token>）  │
│    2) 调用 qua API 拉租户用户/部门 → 构建运行时词库               │
│    3) 提供 ASR 同步 + 流式识别（funasr 整段 / xunfei 流式）       │
│    4) 8 层文本增强 Pipeline（清洗→口水词→别名→确定性→拼音→模糊→ │
│       上下文→LLM 保留位）                                        │
│    5) 原始音频落盘到 upload/audio/<tenant>/<session>.<ext>      │
└──────────────────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────────────┐
│        ASR Provider（pkg/asr，funasr / xunfei / 其它）        │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 边界

| 本工具**做** | 本工具**不做** |
|---|---|
| Bearer Token 校验（Redis 查 qua session） | 用户/角色/菜单/权限管理 |
| ASR 同步/流式识别（多 Provider 路由） | 后台管理页面（Vben） |
| 8 层文本增强（确定性 + 推断） | 字典/词条的 CRUD 后台 |
| 原始音频本地落盘 | 文件中心上传（S3/MinIO/OSS） |
| qua 用户/部门 → 运行时词库（定时同步） | 数据库（Ent/MySQL） |
| 系统静态词条（JSON 热加载） | Casbin 鉴权 / OpenAPI 文档发布 |
| 启动时全量预加载 + 5min 周期同步 | 跨服务调用鉴权 / 多服务会话 |

### 1.3 与 `app/evie/service` 的关系

- **不复用 `app/evie/service` 代码**（避免引入 Ent/proto `evie/service/v1`/后台业务依赖）
- 8 层 pipeline 与 `pkg/asr` 接口**算法级复用**：复制 `app/evie/service/internal/biz/enhancement*.go` 与 `vocabulary.go`，删除 Ent/Casbin/PlatformClient 相关分支
- 共用底层包：`pkg/asr/*`、`pkg/asr/audio`、`pkg/pinyin`、`pkg/auth/authn`（仅 `ContextWith*`/`GetAuthUserID`/`GetAuthUserTenantID`/`SecurityUser` 接口，不引 JWT 库）

### 1.4 与外部系统的耦合边界（Q13 重要约束）

**工具核心不依赖任何具体外部系统的字段名**。

- 数据进入：仅接受 opaque `map[string]any`（adapter 产出 RawEntity，不解释字段）
- 数据处理：Normalizer 按 YAML 规则把 RawEntity → NormalizedEntry（业务无关）
- 数据消费：VocabularyBuilder / EnhancementEngine 只看 NormalizedEntry，不知道来源
- 加新来源：`data/<name>_source.go` + YAML 规则；零核心代码变更
- 变更保护：外部 API 调整只改 YAML 或 adapter；工具不需重新发布

---

## 二、目录与文件清单

### 2.1 落地结构

```text
backend-service/
├── proto/evie/tool/v1/                    # 独立 proto
│   ├── asr.proto                          # Recognize/StreamRecognize + records
│   ├── enhancement.proto                  # EnhanceText + 同步状态接口
│   └── buf.openapi.gen.yaml               # OpenAPI v3 生成配置（可选）
│
├── app/evie/tool/
│   ├── cmd/server/
│   │   ├── main.go                        # 入口（替换示例）
│   │   ├── wire.go                        # DI 声明
│   │   ├── wire_gen.go                    # wire 生成
│   │   └── assets.go                      # OpenAPI assets embed（Kratos 标准）
│   │
│   ├── configs/
│   │   ├── config.yaml                    # 主配置（qua/redis/asr/enhancement/tenant_vocab/system_dict）
│   │   └── dictionaries/
│   │       └── system.json                # 系统静态词条（热加载）
│   │
│   ├── internal/
│   │   ├── conf/                          # protoc 生成（conf.proto + conf.pb.go）
│   │   │
│   │   ├── biz/                           # 业务用例层
│   │   │   ├── biz.go                     # ProviderSet
│   │   │   ├── asr.go                     # ASRUsecase.Recognize（同步）
│   │   │   ├── asr_stream.go              # ASRUsecase.StreamRecognize（双向流）
│   │   │   ├── asr_record.go              # 识别记录查询（仅日志查询）
│   │   │   ├── audio_store.go             # 本地 upload/audio 落盘
│   │   │   ├── enhancement.go             # EnhancementEngine + 5 个确定性 Step
│   │   │   ├── enhancement_inference.go   # PinyinCorrection/Fuzzy/Context/LLM 保留
│   │   │   ├── vocabulary.go              # VocabularyContext/Builder（精简版）
│   │   │   ├── vocab_sync.go              # qua → 词库同步 worker（ticker）
│   │   │   └── tenant_registry.go         # 持久化已访问租户（去重）
│   │   │
│   │   ├── data/                          # 基础设施层
│   │   │   ├── data.go                    # Redis/Provider 装配
│   │   │   ├── token_cache.go             # oauth2_access_token:<token> 查询
│   │   │   ├── token_auth.go              # 自定义 SecurityUser + ctxKey
│   │   │   ├── qua_client.go              # qua 用户/部门 HTTP client
│   │   │   ├── system_dict.go             # system.json 加载 + 热重载
│   │   │   └── providers.go               # ASR Provider 工厂 + 配置驱动开关
│   │   │
│   │   ├── server/                        # Kratos transport
│   │   │   ├── server.go                  # ProviderSet
│   │   │   ├── http.go                    # HTTP 注册 + middleware 链
│   │   │   ├── grpc.go                    # gRPC 注册
│   │   │   └── middleware.go              # Bearer → Redis → ctx 中间件
│   │   │
│   │   └── service/                       # transport ↔ biz 桥接
│   │       ├── service.go                 # ProviderSet
│   │       ├── asr_service.go             # ASRService 实现
│   │       ├── enhancement_service.go     # EnhancementService 实现
│   │       └── admin_service.go           # AdminService（同步状态查询 + 触发同步）
│   │
│   ├── upload/audio/                      # 运行时音频目录（首次运行自动创建）
│   └── Makefile                           # proto/config/wire/run/test
│
└── docs/services/evie-platform/development/
    └── 11-evie-tool独立轻量语音识别增强工具开发计划.md   # 本文档
```

### 2.2 关键依赖

```go
// go.mod 新增/复用（已存在不重复 require）
github.com/redis/go-redis/v9            // 已有
github.com/fsnotify/fsnotify             // 新增（系统词条热加载）
github.com/mozillazg/go-pinyin           // 已有 indirect → 直接 require
github.com/go-kratos/kratos/v2           // 已有
google.golang.org/grpc                   // 已有（kratos 依赖）
```

---

## 三、关键设计决策

### 3.1 认证：从 `Authorization: Bearer <token>` 到 ctx（Q2 决定）

qua 系统 token value 形态（确认样本）：
```json
{
  "tenantId":    "1889501240003497986",
  "id":          "2094623134267203585",
  "accessToken": "68aa8a4a9cf14b149164a9f451b2893c",
  "refreshToken":"2a5c4a6fc052457f8da558f55ff8b654",
  "userId":      "2031552504886435841",
  "userType":    2,
  "userInfo": {
    "nickname": "测试账号",
    "deptId":   "1904450235179954177"
  },
  "clientId":    "default",
  "scopes":      null,
  "expiresTime": 1788491296083
}
```

**实现要点**：
- Redis key：`oauth2_access_token:<token>`（前缀在 `conf.Data.Redis.TokenKeyPrefix` 配置，默认 `oauth2_access_token:`）
- value 反序列化到 `AuthInfo`（`data/token_auth.go`）：
  ```go
  type AuthInfo struct {
      TenantID     string `json:"tenantId"`     // 字符串避免 uint32 溢出
      UserID       string `json:"userId"`
      AccessToken  string `json:"accessToken"`  // 调用 qua 时的 token
      RefreshToken string `json:"refreshToken"`
      UserType     int32  `json:"userType"`
      Nickname     string `json:"-"`            // 嵌套
      DeptID       string `json:"-"`
      ExpiresTime  int64  `json:"expiresTime"`  // epoch ms
  }
  type authInfoPayload struct { /* 对应 JSON 字段 */ }
  ```
- 因为 ID 超过 `uint32` 范围（1.8e18 > 4.3e9），**新增 ctxKey**：tool 内部一律使用 `GetAuthInfo(ctx).TenantID/UserID`（字符串），不复用 `GetAuthUserID/TenantID` 的 `uint32` 返回。
- ctx 注入：保留 `authn.ContextWithAuthUser`，`SecurityUser` 自实现（`subject=userId, tenant=tenantId`），使 `authn.GetAuthUserID`/`GetAuthUserTenantID` 也能拿到字符串值——但**接受 uint32 截断**；tool 业务代码统一走 `GetAuthInfo(ctx)`。

### 3.2 qua HTTP client（Q5/Q6）

- qua API 端点配置在 `qua.yaml`：
  ```yaml
  qua:
    base_url: "http://127.0.0.1:48080"
    endpoints:
      list_users: "/admin-api/system/user/page"
      list_depts: "/admin-api/system/dept/list"
    timeout: 5s
    forward_user_token: true   # 调用 qua 时复用当前用户的 Authorization 头
    page_size: 500             # 单页拉多少（qua 默认 10，全量时分页）
  ```
- HTTP 调用时**透传 Bearer Token**（qua 自带鉴权，避免重复登录）
- `no_paging=true`：qua 通常需要传 `pageSize` + `pageNo=1` 全量；具体参数与 qua 接口约定（实施时需 qua 文档支持）

### 3.3 租户级持久化（Q9）

```text
backend-service/app/evie/tool/configs/
└── tenants.json            # 运行期生成（git 忽略）：已发现租户 ID 列表
```

```json
{
  "tenants": [
    {"tenant_id": "1889501240003497986", "first_seen": "2026-09-01T10:00:00Z"},
    {"tenant_id": "1940000111122223333", "first_seen": "2026-09-02T08:30:00Z"}
  ]
}
```

**生命周期**：
1. **运行时**——任意请求进入 `TokenAuthMiddleware`，从 ctx 拿到 `tenantId` → 调 `TenantRegistry.Ensure(tenantId)`（如已存在跳过；否则加锁写入 + 触发该租户一次立即同步）。
2. **启动**——`main.go` 调 `TenantRegistry.Warmup()`：遍历 `tenants.json` → 并发（worker pool, 限制并发数）拉取每个租户的全量 user+dept → 灌入 `VocabularyBuilder`。
3. **周期**——`vocab_sync.go` 启动后 `time.NewTicker(tenantVocab.SyncInterval)`，每次对**所有已知租户**做一次全量增量同步（先清空旧词条 → 拉新 → 重建）。

**去重**：`TenantRegistry` 用 `map[string]struct{}` + 文件原子写入（`tmp + rename`）。

### 3.4 系统静态词条（Q8）

```text
backend-service/app/evie/tool/configs/dictionaries/
└── system.json
```

```json
{
  "version": "2026-09-01",
  "entries": [
    {
      "standard_text": "金种籽",
      "category": "PRODUCT",
      "priority": 100,
      "aliases":     ["金种子"],
      "corrections": [],
      "homophones":  ["金中子"]
    }
  ],
  "phrase_rules": [
    {"from": "个种籽", "to": "颗种籽"}
  ]
}
```

- 启动加载 + `fsnotify` 监听文件 `WRITE/RENAME`，变更后重新加载到 `VocabularyBuilder.ReplaceSystemEntries(...)`
- 加载时**自动派生拼音同音条目**：对每个 `standard_text` 调 `pkg/pinyin.Convert`，与已有 `homophones` 合并

### 3.5 ASR Provider 路由（Q7）

```yaml
asr:
  default_batch_provider: funasr   # 整段识别首选
  default_stream_provider: xunfei  # 流式识别首选
  upload:
    audio_dir: "./upload/audio"
    retention_days: 0              # 0=永久
  providers:
    funasr:
      enabled: true
      addr: "http://127.0.0.1:18000"
      stream_addr: ""              # 空则不流式
      sample_rate: 16000
      language: zh
    xunfei:
      enabled: false               # 第一期需配置后启用
      app_id: ""
      api_key: ""
      api_secret: ""
      sample_rate: 16000
    whisper:
      enabled: false               # 预留
    aliyun:
      enabled: false               # 预留
```

**路由策略**（`biz/asr.go`）：
- `Recognize`（整段）：按 `default_batch_provider` 取，若 disabled 则按 `providers` 中第一个 enabled 兜底
- `StreamRecognize`（流式）：按 `default_stream_provider` 取，要求 `caps.Streaming=true`

### 3.6 文本增强 8 层 Pipeline

复用 `app/evie/service/internal/biz/enhancement*.go` 的**算法实现**，复制为本地代码并删除 Ent/Platform/Casbin 依赖：

| 步骤 | Step | 类型 | 默认启用 | 备注 |
|---|---|---|---|---|
| ① | `TextCleaningStep` | 确定性 | ✅ | 多空格/重复标点/控制字符 |
| ② | `FillerStep` | 确定性 | ✅ | 句首/标点后强口水词删除 |
| ③ | `VocabularyMatchingStep` | 索引 | ✅ | 命中标准词后**锁定片段** |
| ④ | `AliasResolutionStep` | 确定性 | ✅ | ALIAS 关系 → 标准词 |
| ⑤ | `DeterministicReplacementStep` | 确定性 | ✅ | CORRECTION 关系 → 标准词 |
| ⑥ | `PinyinCorrectionStep` | 推断 | ✅ | HOMOPHONE 关系 → 标准词（conf 0.85） |
| ⑦ | `FuzzyMatchingStep` | 推断 | ✅ | 编辑距离 1~2，复用词库 |
| ⑧ | `ContextCorrectionStep` | 推断 | ✅ | 上下文窗口规则 |
| ⑨ | `LLMReservedStep` | 预留 | ⛔ 默认 false | no-op，配置开关 |

锁定机制：确定性步骤（④⑤）+ 词库匹配（③）替换的片段写入 `c.lockedSpans`，后续推断步骤跳过。

### 3.7 音频落盘

- 目录：`upload/audio/<tenant_id>/<session_id>.<ext>`
- `<session_id>`：`UUIDv4`（不依赖 qua）
- 格式：
  - 整段识别：客户端上传的原始字节按 `format.encoding` 保存；若 PCM 自动包 WAV 头（复用 `pkg/asr/audio.PCMToWAV`）
  - 流式识别：所有 `PCMChunk` 拼接为完整 PCM → 包 WAV 头
- 路径返回 `audio_path`（相对工具工作目录）

### 3.8 外部系统解耦架构（Q13 决定）

**分层契约**：

```text
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1 · fetcher（data）                                        │
│   HTTP/DB/gRPC 调用，仅返回 opaque `[]map[string]any`                │
│   例：quaClient.fetchUsersRaw() → []map[string]any               │
│   不解释字段语义                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2 · VocabularySource Adapter（data）                       │
│   实现 biz.VocabularySource（Name + Fetch）                       │
│   把 opaque map 包成 RawEntity{source_id, entity_type, source, data} │
│   例：QuaVocabularySource.Fetch() → []RawEntity                 │
│   仍不解释字段语义                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3 · Normalizer（biz）                                      │
│   按 RuleSet（YAML）把 RawEntity → NormalizedEntry                │
│   支持 dot-path 访问（user.realName）与简单条件（status==1）        │
│   业务无关、可单测                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Layer 4 · VocabularyBuilder（biz）                              │
│   只接收 NormalizedEntry，不知道来源                                │
│   与现有 evie/service 算法复用（10 个 case 的测试）                    │
├─────────────────────────────────────────────────────────────────┤
│ Layer 5 · EnhancementEngine（biz）                               │
│   8 层 Pipeline，输入为原始文本 + VocabularyContext                  │
│   不知道外部系统存在                                                │
└─────────────────────────────────────────────────────────────────┘
```

**关键类型**：

```go
// biz/vocab_source.go
type VocabularySource interface {
    Name() string
    Fetch(ctx context.Context) ([]RawEntity, error)
}

type RawEntity struct {
    SourceID   string         // 外部唯一 ID
    EntityType string         // user / department / product ...
    Source     string         // qua / feishu / ldap ...
    Data       map[string]any // 不透明负载
}

// biz/vocab_normalizer.go
type NormalizedEntry struct {
    StandardText string   // 标准词
    Category     string   // PERSON / ORGANIZATION / ...
    Aliases      []string // ALIAS 关系源
    PinyinHint   string   // 拼音派生源
    Priority     int32
    Source       string   // 追溯
    SourceID     string
}

type RuleSet struct {
    Sources map[string]*SourceRules // key = source name
}

type Normalizer struct{ rules *RuleSet }
func (n *Normalizer) Normalize(raw RawEntity) (*NormalizedEntry, bool, error)
```

**规则 YAML 样例**（参考 §四 配置中的 `vocab_rules` 块）：

```yaml
vocab_rules:
  sources:
    qua:
      entity_mappings:
        - match: {entity_type: "user"}
          emit:
            standard_text: "realName"          # dot-path 从 RawEntity.Data 访问
            category: "PERSON"
            aliases: ["nickname", "alias"]      # 多个 dot-path 作为别名
            pinyin_hint: "realName"
            priority: "50"
            include_when: "status==1"          # 简单条件，不满足则跳过
        - match: {entity_type: "department"}
          emit:
            standard_text: "name"
            category: "ORGANIZATION"
            pinyin_hint: "name"
```

**新增 source 的成本**（验证复用性）：

| 场景 | 代码变更 | 配置变更 |
|---|---|---|
| qua 字段名调整 | 0 | 改 YAML dot-path 即可 |
| 换飞书/LDAP/CSV | 1 个新 adapter（~100 行） | 新 YAML 规则 |
| 外部 API 整体更换 | 同上 | 同上 |
| 工具升级需重新发布 | 仅规则变更 → 无需；adapter 变更 → 需 | — |

**关键不变量**：

- `VocabularySource`、`RawEntity`、`NormalizedEntry`、`RuleSet`、`Normalizer` 是**唯一稳定 API**
- 所有 adapter 不得绕过 Normalizer 直接给 VocabularyBuilder 灌数据
- 规则 YAML 是工具运维接口（未来考虑 `GET /evie/tool/v1/admin/rules` 查看）

---

## 四、配置：`configs/config.yaml`

```yaml
server:
  http:
    addr: 0.0.0.0:8100
    timeout: 30s
  grpc:
    addr: 0.0.0.0:9100
    timeout: 30s

data:
  redis:
    network: tcp
    addr: 127.0.0.1:6379
    password: ""
    db: 0
    read_timeout: 200ms
    write_timeout: 200ms
    token_key_prefix: "oauth2_access_token:"   # Q2 决定

qua:                                            # Q1/Q5/Q6
  base_url: "http://127.0.0.1:48080"
  timeout: 5s
  forward_user_token: true
  endpoints:
    list_users: "/admin-api/system/user/page"
    list_depts: "/admin-api/system/dept/list"
  page_size: 500

asr:                                            # Q7
  default_batch_provider: funasr
  default_stream_provider: xunfei
  upload:
    audio_dir: "./upload/audio"
    retention_days: 0
  providers:
    funasr:
      enabled: true
      addr: "http://127.0.0.1:18000"
      stream_addr: ""
      sample_rate: 16000
      language: zh
    xunfei:
      enabled: false
      app_id: ""
      api_key: ""
      api_secret: ""
      sample_rate: 16000
    whisper:
      enabled: false
    aliyun:
      enabled: false

enhancement:                                    # Pipeline 步骤 + 阈值
  pipeline:
    - cleaning
    - filler
    - vocabulary_matching
    - alias_resolution
    - deterministic_replacement
    - pinyin_correction
    - fuzzy_matching
    - context_correction
    # - llm_reserved
  pinyin_threshold: 0.85
  fuzzy_auto_threshold: 0.80
  fuzzy_suggest_threshold: 0.60
  llm_enabled: false

tenant_vocab:                                   # Q9
  sync_interval: 5m
  initial_warmup: true
  concurrency: 4
  include_departments: true
  include_user_nickname: true                   # Q3
  include_user_realname: true                   # Q3
  custom_alias_field: "alias"                   # Q3：qua 透传时使用的字段名（预留）

system_dict:                                    # Q8
  path: "./configs/dictionaries/system.json"
  hot_reload: true

tenant_registry:                                # Q9
  path: "./configs/tenants.json"

# Q13：外部系统词汇规则（YAML 配置，零代码接入新 source）
# Normalizer 按这里的 mapping 把 RawEntity → NormalizedEntry。
vocab_rules:
  sources:
    qua:
      entity_mappings:
        # 用户实体映射
        - match:
            entity_type: "user"
          emit:
            standard_text: "realName"          # dot-path 从 RawEntity.Data 访问
            category: "PERSON"
            aliases:
              - "nickname"
              - "alias"                        # Q3：qua 预留 alias 字段
            pinyin_hint: "realName"
            priority: "50"
            include_when: "status==1"          # 只取启用用户
        # 部门实体映射
        - match:
            entity_type: "department"
          emit:
            standard_text: "name"
            category: "ORGANIZATION"
            pinyin_hint: "name"
            priority: "30"
            # 部门默认全取（不设 include_when）
```

---

## 五、Proto 契约

### 5.1 `backend-service/proto/evie/tool/v1/asr.proto`

```protobuf
syntax = "proto3";
package evie.tool.v1;
option go_package = "backend-service/api/evie/tool/v1;v1";

import "google/api/annotations.proto";
import "gnostic/openapi/v3/annotations.proto";
import "buf/validate/validate.proto";

// ASRService 同步 + 流式语音识别
service ASRService {
  rpc Recognize(RecognizeRequest) returns (RecognizeResponse) {
    option (google.api.http) = { post: "/evie/tool/v1/asr:recognize", body: "*" };
  }
  rpc StreamRecognize(stream AudioChunk) returns (stream StreamResult) {
    // 流式（HTTP/2 或 gRPC），不开 gateway
  }
  rpc ListRecords(ListAsrRecordsRequest) returns (ListAsrRecordsResponse) {
    option (google.api.http) = { get: "/evie/tool/v1/asr/records" };
  }
  rpc GetRecordAudio(GetRecordAudioRequest) returns (GetRecordAudioResponse) {
    option (google.api.http) = { get: "/evie/tool/v1/asr/records/{id}/audio" };
  }
  rpc GetRecord(GetRecordRequest) returns (AsrRecord) {
    option (google.api.http) = { get: "/evie/tool/v1/asr/records/{id}" };
  }
}

message AudioFormat {
  string encoding = 1;       // pcm/wav/mp3/opus
  int32 sample_rate = 2;
  int32 bit_depth = 3;       // 默认 16
  int32 channels = 4;        // 默认 1
}

message RecognizeRequest {
  AudioFormat format = 1;
  bytes audio_data = 2 [(buf.validate.field).bytes.max_len = 10485760]; // 10MB
  string session_id = 3;     // 可选；空则服务端生成 UUID
  bool enable_enhancement = 4;
}

message RecognizeResponse {
  string request_id = 1;
  string session_id = 2;
  string raw_text = 3;
  string enhanced_text = 4;
  float  confidence = 5;
  int64  duration_ms = 6;
  bool   is_final = 7;
  string provider_name = 8;
  string audio_path = 9;
  repeated EnhanceChange changes = 10;
  int32  status = 11;          // 1=SUCCESS 2=DEGRADED
  int64  processing_time_ms = 12;
  int64  cleaning_time_ms = 13;
  int64  filler_time_ms = 14;
  int64  vocab_match_time_ms = 15;
  int64  alias_time_ms = 16;
  int64  deterministic_time_ms = 17;
  int64  pinyin_time_ms = 18;
  int64  fuzzy_time_ms = 19;
  int64  context_time_ms = 20;
  string error_message = 21;
}

message AudioChunk {
  bytes  data = 1;
  int64  timestamp_ms = 2;
}

message StreamResult {
  string request_id = 1;
  string session_id = 2;
  string text = 3;             // 增量或累积
  bool   is_final = 4;
  float  confidence = 5;
  int64  timestamp_ms = 6;
  string audio_path = 7;       // 仅 is_final=true 时填充
}

message AsrRecord {
  string id = 1;               // session_id
  string user_id = 2;
  string tenant_id = 3;
  string raw_text = 4;
  string enhanced_text = 5;
  string audio_path = 6;
  string provider_name = 7;
  string created_at = 8;
}

message ListAsrRecordsRequest {
  int32  page_size = 1;
  string page_token = 2;
}
message ListAsrRecordsResponse {
  repeated AsrRecord records = 1;
  int32  total = 2;
  string next_page_token = 3;
}
message GetRecordRequest  { string id = 1 [(buf.validate.field).string.min_len = 1]; }
message GetRecordAudioRequest { string id = 1 [(buf.validate.field).string.min_len = 1]; }
message GetRecordAudioResponse {
  bytes  audio_data = 1;
  string content_type = 2;
}

// 复用 evie/service 的 EnhanceChange（简化版）
message EnhanceChange {
  string from = 1;
  string to = 2;
  string action = 3;        // KEEP/REPLACE/DELETE/SUGGEST/RESOLVE
  string type = 4;          // CLEAN/FILLER/ALIAS/CORRECTION/PINYIN/FUZZY/CONTEXT/PHRASE
  string source = 5;        // SYSTEM/TENANT_DICTIONARY/QUANTENANT_USER/QUA_TENANT_DEPT
  float  confidence = 6;
  bool   locked = 7;
  string reason = 8;
}
```

### 5.2 `backend-service/proto/evie/tool/v1/enhancement.proto`

```protobuf
syntax = "proto3";
package evie.tool.v1;
option go_package = "backend-service/api/evie/tool/v1;v1";

import "google/api/annotations.proto";
import "evie/tool/v1/asr.proto"; // EnhanceChange 共用

service EnhancementService {
  rpc EnhanceText(EnhanceTextRequest) returns (EnhanceTextResponse) {
    option (google.api.http) = { post: "/evie/tool/v1/enhance", body: "*" };
  }
}

message EnhanceTextRequest {
  string text = 1 [(buf.validate.field).string.min_len = 1];
}
message EnhanceTextResponse {
  string original_text = 1;
  string enhanced_text = 2;
  repeated EnhanceChange changes = 3;
  int32  status = 4;
  int64  processing_time_ms = 5;
  int64  cleaning_time_ms = 6;
  int64  filler_time_ms = 7;
  int64  vocab_match_time_ms = 8;
  int64  alias_time_ms = 9;
  int64  deterministic_time_ms = 10;
  int64  pinyin_time_ms = 11;
  int64  fuzzy_time_ms = 12;
  int64  context_time_ms = 13;
  string error_message = 14;
}

// 内部运维接口（不需要对外暴露时禁用）
service AdminService {
  rpc GetVocabSyncStatus(GetVocabSyncStatusRequest) returns (GetVocabSyncStatusResponse) {
    option (google.api.http) = { get: "/evie/tool/v1/admin/vocab/status" };
  }
  rpc TriggerVocabSync(TriggerVocabSyncRequest) returns (TriggerVocabSyncResponse) {
    option (google.api.http) = { post: "/evie/tool/v1/admin/vocab:sync", body: "*" };
  }
}

message TenantVocabStatus {
  string tenant_id = 1;
  int64  last_sync_at_ms = 2;
  int64  entry_count = 3;
  int64  relation_count = 4;
  string status = 5;           // OK/SYNCING/FAILED
  string last_error = 6;
}
message GetVocabSyncStatusRequest  {}
message GetVocabSyncStatusResponse {
  repeated TenantVocabStatus tenants = 1;
  int64 system_entry_count = 2;
}
message TriggerVocabSyncRequest    { string tenant_id = 1; } // 空=全部
message TriggerVocabSyncResponse   { int32 triggered = 1; }
```

---

## 六、任务拆分（M0~M9）

每个 M 独立可编译、可运行、可验收。完成后再启动下一 M。

> **进度汇总**（2026-09）：
>
> | M | 状态 | 交付概要 |
> |---|:---:|---|
> | M0 | ✅ | proto / conf / 配置 / wire / 骨架启动 |
> | M1 | ✅ | pkg/asr Provider 装配（funasr + xunfei） |
> | M2 | ✅ | Bearer Token 中间件 + ctx 注入 |
> | M3 | 🚧 **重构中** | Q13 重构：fetcher (✅) + adapter (📋) + Normalizer (📋) + wire (📋) |
> | M4 | 📋 | 系统静态词条加载 + 热加载 |
> | M5 | 📋 | 租户注册表 + 预加载 + 周期同步（使用 Normalizer + SourceRegistry） |
> | M6 | 📋 | 8 层文本增强 Pipeline |
> | M7 | 📋 | 整段识别 + 音频落盘 |
> | M8 | ✅ | （与 M7 合并实现） |
> | M9 | 📋 | 收口（Makefile / 文档 / 健康检查） |

> **本次重构状态说明**：Q13 重构发布后，M3 已落地的 qua HTTP client 代码需重新调整为 opaque fetcher（`[]map[string]any` 返回值）+ 新增 adapter + Normalizer。详见 §六 M3。

---

### M0 · proto 契约 + 配置扩展 + 骨架可启动 ✅

**目标**：替换 greeter 模板，proto/conf 可生成，`make wire && make run` 通过，HTTP `/health` 200。

**交付**：
1. 上述 §5 两个 proto 文件 + `buf.gen.yaml`（已在 `proto/buf.gen.yaml` 追加 `./evie/tool/v1`）
2. `internal/conf/conf.proto` 扩展 `Data.Redis.TokenKeyPrefix` + 新增 `Qua` / Enhancement / TenantVocab / SystemDict / TenantRegistry / Asr 6 个 message + `Qua.ExtraHeaders` map（见 §四字段）
3. `app/evie/tool/cmd/server/main.go` 替换为接收 `*conf.Bootstrap`（全量注入）
4. `configs/config.yaml`（§四，Q5/Q7 准确填入）
5. `internal/biz/biz.go`、`internal/service/service.go`、`internal/server/server.go` 的 ProviderSet 留空
6. `Makefile`：proto / config / wire / run / test / lint / kill

**验收**：
```bash
cd backend-service/app/evie/tool
make proto && make config && make wire
make run &
curl -sS http://127.0.0.1:8100/evie/tool/v1/asr:recognize -X POST  # 应 401/400（无 token）
```

**状态**：✅ 完成（proto已生成、conf 已生成、构建 + go vet 全部通过）。

---

### M1 · `pkg/asr` Provider 装配 ✅

**目标**：根据 `asr.providers.*` 在启动时实例化已启用的 provider 并注册到 `asr.ProviderRegistry`。

**交付**：
1. `internal/data/providers.go`：
   ```go
   func NewASRRegistry(c *conf.Asr, log log.Logger) (*asr.ProviderRegistry, error)
   func ResolveProvider(reg, name, enabledNames) (asr.ASRProvider, error)
   func EnabledProviderNames(c) []string
   ```
2. ✅ 装配逻辑：funasr（HTTP 整段）+ xunfei（WebSocket 流式）；whisper/aliyun 启动时 warn。
3. 路由逻辑在 `biz/asr.go`（M7 阶段）使用 `ResolveProvider`。

**状态**：✅ 完成。Provider 启用后启动时打日志，已集成到 `cmd/server/wire_gen.go`。

---

### M2 · Bearer Token 中间件 + ctx 注入 ✅

**目标**：`Authorization: Bearer <token>` → Redis `oauth2_access_token:<token>` → ctx 注入 `AuthInfo`。

**交付**：
1. ✅ `internal/data/token_cache.go`：`AuthInfo`（Q2 JSON 结构体）+ `TokenCache.Get` + `ErrTokenNotFound` / `ErrTokenInvalid`
2. ✅ `internal/data/token_auth.go`：`TokenAuthMiddleware(cache, skipPath)` + `AuthInfoFromContext` + `MustAuthInfo` + `tokenSecurityUser` 实现 `authn.SecurityUser`
3. ✅ `internal/server/middleware.go`：`NewTokenAuthMiddleware(cache, skipPath)` 包装层
4. ✅ `internal/server/{http,grpc}.go`：在 middleware 链中注册（recovery + token auth）
5. ✅ `internal/data/errors.go`：401/400/500/503 错误工厂
6. ✅ `internal/data/token_cache_test.go`：Q2 JSON 反序列化单测 + Key 拼接单测（4 个 case，race 通过）

**接口使用**：
```go
// handler 内部拿 AuthInfo（首选）
info, ok := data.AuthInfoFromContext(ctx)
// info.TenantID / info.UserID / info.UserInfo.Nickname / info.UserInfo.DeptID / info.AccessToken

// 调 qua 时透传当前用户 token（不需要额外参数，从 ctx 取）
token := info.AccessToken
```

**验收**：redis-cli 注入样本 value → 任意带 token 接口打日志可看到 ctx.AuthInfo 完整

**状态**：✅ 完成。构建 + 单测 + race 检测全绿。

---

### M3 · 外部系统接入层（重构后：3a fetcher + 3b adapter + 3c normalizer + 3d wire）

> **Q13 重构**：M3 原设计为「qua HTTP client + QuaUser/QuaDept 强类型」，与具体外部系统耦合。按用户反馈重构为三层：
>
> - Layer 1 · fetcher：只拉 opaque map（不含语义解释）
> - Layer 2 · adapter：把 map 包成 RawEntity
> - Layer 3 · normalizer：按 YAML 规则做 RawEntity → NormalizedEntry
>
> 未来加飞书/LDAP/CSV 只动 fetcher + adapter + YAML；零核心代码变更。

#### M3a · HTTP fetcher（opaque 数据）✅

**目标**：`quaClient` 只返回 `[]map[string]any`，不带任何业务类型。

**交付**：
1. `internal/data/qua_client.go`（重构后）：
   ```go
   type quaClient struct {
       baseURL    string
       httpClient *http.Client
       endpoints  quaEndpoints
       timeout    time.Duration
       extraHdr   map[string]string
   }
   // 返回值是 map，不是结构体！
   func (c *quaClient) fetchUsersRaw(ctx) ([]map[string]any, error)
   func (c *quaClient) fetchDeptsRaw(ctx) ([]map[string]any, error)
   ```
   - 遵Q5/Q6 真实端点（`GET /admin-api/system/dept/list`、`POST /admin-api/qua/member-extended/page?selectAll=true`）
   - 透传 `Authorization: Bearer` + `tenant-id`（int 转换）+ `zone` 等静态头
   - qua 业务码 → proto 错误（v1.ErrorQuaXxx）
   - 错误语义与 HTTP 状态码映射统一
2. **删除**：原 `QuaUser` / `QuaDept` 强类型、原 `biz.QuaRepo` 接口、原 `toBiz()` 转换
3. **保留**：httptest mock qua 测试（重命名为 `TestQuaFetcher_*`，仍然 9 个 case 覆盖 token 透传 / tenant-id 转换 / 错误映射）

**验收**：`go test ./internal/data/...` 全绿（fetcher 不出现 qua-specific 类型）

---

#### M3b · VocabularySource Adapter

**目标**：`QuaVocabularySource` 实现 biz.VocabularySource，把 opaque map 包成 RawEntity。

**交付**：
1. `internal/data/qua_source.go`：
   ```go
   type quaSource struct {
       fetcher *quaClient // M3a 产出
       name    string
   }
   func NewQuaVocabularySource(c *conf.Qua, _ log.Logger, opts ...) (biz.VocabularySource, error)
   func (s *quaSource) Name() string { return "qua" }
   func (s *quaSource) Fetch(ctx) ([]biz.RawEntity, error) {
       users, _ := s.fetcher.fetchUsersRaw(ctx)
       depts, _ := s.fetcher.fetchDeptsRaw(ctx)
       out := make([]biz.RawEntity, 0, len(users)+len(depts))
       for _, u := range users {
           out = append(out, biz.RawEntity{
               SourceID:   stringID(u["id"]),
               EntityType: "user",
               Source:     s.name,
               Data:       u,
           })
       }
       for _, d := range depts {
           out = append(out, biz.RawEntity{
               SourceID:   stringID(d["id"]),
               EntityType: "department",
               Source:     s.name,
               Data:       d,
           })
       }
       return out, nil
   }
   ```

**验收**：单测覆盖 user/department 包装；不解释字段语义

---

#### M3c · Normalizer + RuleSet（Q13 核心）

**目标**：纯函数组件，按 YAML 规则做 RawEntity → NormalizedEntry。

**交付**：
1. `internal/biz/vocab_source.go`：
   ```go
   type VocabularySource interface {
       Name() string
       Fetch(ctx) ([]RawEntity, error)
   }
   type RawEntity struct {
       SourceID   string
       EntityType string
       Source     string
       Data       map[string]any
   }
   ```
2. `internal/biz/vocab_normalizer.go`：
   ```go
   type NormalizedEntry struct {
       StandardText, Category string
       Aliases                 []string
       PinyinHint             string
       Priority               int32
       Source, SourceID       string
   }
   type RuleSet struct { Sources map[string]*SourceRules }
   type SourceRules struct {
       Source         string
       EntityMappings []EntityMapping
   }
   type EntityMapping struct { Match MatchCondition; Emit EmitSpec }
   type MatchCondition struct { EntityType string }
   type EmitSpec struct {
       StandardText string
       Category     string
       Aliases      []string
       PinyinHint   string
       Priority     string
       IncludeWhen  string
   }
   type Normalizer struct{ rules *RuleSet }
   func NewNormalizer(rs *RuleSet) *Normalizer
   func (n *Normalizer) Normalize(raw RawEntity) (*NormalizedEntry, bool, error)
   func (n *Normalizer) NormalizeBatch(raws []RawEntity) ([]*NormalizedEntry, error)
   ```
3. 内部辅助（私有）：
   - `lookupPath(data map[string]any, path string) (string, bool)`：dot-path 访问
   - `evalCondition(expr string, data map[string]any) (bool, error)`：`==` / `!=` / 真值单 token
   - `toInt32(v any) int32`：统一转换
4. 配置新增（参见 §四）：
   ```yaml
   vocab_rules:
     sources:
       qua:
         entity_mappings:
           - match: {entity_type: "user"}
             emit:
               standard_text: "realName"
               category: "PERSON"
               aliases: ["nickname", "alias"]
               pinyin_hint: "realName"
               priority: "50"
               include_when: "status==1"
           - match: {entity_type: "department"}
             emit:
               standard_text: "name"
               category: "ORGANIZATION"
               pinyin_hint: "name"
   ```
5. `conf.proto` 扩展：`Bootstrap.VocabRules`（`VocabRules` message 嵌套）

**验收**：
- 单测覆盖 6 个 case：单 token / `==` / `!=` / 字段缺失 / 优先级字面量与 dot-path / 别名合并
- YAML 重载后 Normalizer 行为改变（热加载由 M4 fsnotify 提供机制；M9 阶段考虑 YAML 热加载）

---

#### M3d · Wire 装配

**目标**：把 fetcher + adapter + normalizer + rule_loader 接入 wire。

**交付**：
1. `internal/biz/biz.go` ProviderSet：`NewNormalizer`、`NewVocabularySourceRegistry`
2. `internal/data/data.go` ProviderSet：`NewQuaClient` (fetcher) + `NewQuaVocabularySource` (adapter)
3. `cmd/server/wire.go` / `wire_gen.go`：按顺序加入
4. `VocabularySourceRegistry`：map[name]VocabularySource，未来加新 source 只调 `Register`

**验收**：`make wire && make build` 通过；`go test ./...` 全绿

---

#### M3 总验收

- 加新 source 代码量 < 100 行 + 1 份 YAML 规则
- 工具代码不出现 `QuaUser`、`QuaDept`、`user.realName`、`qua.X` 等具体外部绑定
- 修改 qua 字段名 → 只改 YAML，零代码变更

---

### M4 · 系统静态词条加载 + 热加载

**目标**：system.json 启动加载 + fsnotify 热重载。

**交付**：
1. `internal/data/system_dict.go`：
   ```go
   type SystemDict struct {
       Version     string
       Entries     []SystemEntry
       PhraseRules []PhraseRule
   }
   type SystemEntry struct {
       StandardText string
       Category   string
       Priority   int
       Aliases    []string
       Corrections []string
       Homophones []string
   }
   type SystemDictLoader struct {
       path string
       log  *log.Helper
       mu   sync.RWMutex
       data *SystemDict
       watcher *fsnotify.Watcher
   }
   func NewSystemDictLoader(path string, log log.Logger) (*SystemDictLoader, error)
   func (l *SystemDictLoader) Snapshot() *SystemDict
   func (l *SystemDictLoader) Watch(ctx context.Context, onChange func(*SystemDict))
   ```
2. 加载时对每个 entry 调 `pkg/pinyin.Convert` 自动派生同音条目

**验收**：单测：写入 system.json → 触发 onChange 回调 → 校验词条数

---

### M5 · 租户注册表 + 启动预加载 + 周期同步

**目标**：Q9 全流程。

**交付**：
1. `internal/biz/tenant_registry.go`：
   ```go
   type TenantRegistry struct {
       path string
       mu   sync.Mutex
       tenants map[string]TenantInfo
   }
   func NewTenantRegistry(path string) (*TenantRegistry, error)
   func (r *TenantRegistry) Ensure(ctx, tenantID string) (existed bool, err error)   // 写文件 + 触发
   func (r *TenantRegistry) List() []string
   ```
2. `internal/biz/vocab_sync.go`（**Q13 重构后依赖 Normalizer + VocabularySource**）：
   ```go
   type VocabSyncer struct {
       registry      *TenantRegistry
       systemDict    *data.SystemDictLoader
       sourceReg     *data.VocabularySourceRegistry   // 多 source 聚合
       normalizer    *Normalizer                       // biz.Normalizer（使用注入）
       builder       *VocabularyBuilder
       interval      time.Duration
       concurrency   int
       log           *log.Helper
   }
   func (s *VocabSyncer) Warmup(ctx) error
   func (s *VocabSyncer) Run(ctx) error              // ticker 周期
   func (s *VocabSyncer) SyncTenant(ctx, tenantID) error
   ```
   **同步流程**（伪代码）：
   ```go
   for _, src := range s.sourceReg.All() {           // qua / 未来 feishu / ldap...
       raws, _ := src.Fetch(ctx)                       // RawEntity 列表
       entries, _ := s.normalizer.NormalizeBatch(raws) // 通用 NormalizedEntry 列表
       for _, e := range entries {
           s.builder.AddTenantEntry(tenantID, vocabEntryFrom(e)) // vocab 内部不关心来源
       }
   }
   ```
3. `internal/biz/vocabulary.go`（精简版 VocabularyBuilder）：
   - 不依赖 Ent；构造时接受 `[map[string]*VocabularyEntry + map[string][]*VocabularyRelation]`
   - `ReplaceTenant(tenantID, entries, relations)`：原子替换该租户
   - `Build(ctx, tenantID) *VocabularyContext`：取 system + tenant 合并
   - **`AddTenantEntry(tenantID, *NormalizedEntry)`**：M5 新增的便捷方法，内部负责 NormalizedEntry → VocabularyEntry/Relation 的映射

**验收**：
- 模拟首次访问 tenant_A → tenants.json 出现 tenant_A
- 重启 → 启动日志打印 Warmup tenant_A OK
- 5min 后日志打印 SyncTenant tenant_A OK
- 注入 qua mock 返回 5 用户 → 词库 entry 数 = 5（system 不变）
- **新 source（飞书 mock））不修改 M5 代码即可同步词库（仅调 sourceReg.Register(feishuSource)）**

---

---

### M6 · 8 层文本增强 Pipeline

**目标**：复制 `app/evie/service/internal/biz/enhancement*.go` 算法实现并精简。

**交付**：
1. `internal/biz/enhancement.go`：
   ```go
   type EnhancementEngine struct { vocab *VocabularyBuilder; steps []EnhancementStep; log *log.Helper }
   func NewEnhancementEngine(vocab *VocabularyBuilder, log log.Logger) *EnhancementEngine
   func (e *EnhancementEngine) Enhance(ctx, rawText string, p *PolicyContext) (*EnhanceResult, error)
   ```
   - `PolicyContext`：从 `conf.Enhancement` 读 enabled 列表 + 阈值
   - 9 个 Step 全部本地化（无外部依赖）
2. `internal/biz/enhancement_inference.go`：PinyinCorrection/Fuzzy/Context/LLM 4 个推断 Step
3. `internal/biz/enhancement_test.go`：单测覆盖：清洗/口水词/锁定/拼音/模糊阈值

**验收**：复制 evie/service 的 `enhancement_test.go` 10 个核心 case 全绿

---

### M7 · 整段识别 + 音频落盘

**目标**：`POST /evie/tool/v1/asr:recognize` 跑通 funasr。

**交付**：
1. `internal/biz/audio_store.go`：
   ```go
   type AudioStore struct { baseDir string; mu sync.Mutex }
   func NewAudioStore(baseDir string) (*AudioStore, error)
   func (a *AudioStore) Save(tenantID, sessionID string, audio []byte, ext string) (relPath string, err error)
   ```
2. `internal/biz/asr.go`：
   ```go
   func (uc *ASRUsecase) Recognize(ctx, req *v1.RecognizeRequest) (*v1.RecognizeResponse, error) {
       // 1) ctx 读 AuthInfo（取 tenantID/userId）
       // 2) 路由 provider：conf.Asr.DefaultBatchProvider
       // 3) provider.Recognize → raw_text
       // 4) AudioStore.Save（自动 PCM→WAV）
       // 5) vocab.Build(ctx, tenantID) → EnhancementEngine.Enhance
       // 6) 拼装响应 + 八层耗时
   }
   ```
3. `internal/service/asr_service.go`：transport ↔ biz 桥接

**验收**：funasr 服务在 18000 → curl 上传 16k mono pcm → 返回 raw_text + enhanced_text + audio_path，磁盘出现 wav

---

### M8 · 流式识别

**目标**：`StreamRecognize`（双向流，gRPC 或 HTTP/2）。

**交付**：
1. `internal/biz/asr_stream.go`：
   ```go
   func (uc *ASRUsecase) StreamRecognize(ctx, in <-chan asr.PCMChunk, out chan<- asr.ASRStreamResult) {
       // 1) ctx 读 AuthInfo
       // 2) 路由 stream provider
       // 3) 旁路拼接 PCM buffer
       // 4) 转发 in → provider.StreamRecognize
       // 5) provider 出 final=true → 落盘 + 增强 + 推最终 out
   }
   ```
2. `internal/service/asr_service.go` 双向流转换

**验收**：本地 5s PCM 分片推送 → 收到 final result 含 enhanced_text

---

### M9 · 收口

**目标**：Makefile / 文档 / 健康检查 / 错误码统一。

**交付**：
- `Makefile`：`proto / config / wire / run / test / lint / kill / diff-check`
- `internal/server/http.go`：注册 `/evie/tool/v1/asr:recognize`、`/evie/tool/v1/enhance`、`/evie/tool/v1/admin/vocab/status`、`/evie/tool/v1/admin/vocab:sync`
- `internal/server/grpc.go`：注册 `ASRService/EnhancementService/AdminService`
- 错误码：401 UNAUTHORIZED / 403 FORBIDDEN / 400 INVALID_ARGUMENT / 503 UNAVAILABLE
- README.md：使用说明（如何启动、如何联调 qua）

**验收 checklist**：
| 项 | 方式 |
|---|---|
| `make proto && make config && make wire` | CI |
| `make run` 启动无 panic | 手动 |
| 不带 token → 401 | curl |
| redis 注入合法 token → 通过 | curl |
| funasr 整段识别端到端 | 集成测试 |
| 修改 system.json → fsnotify 触发热加载 | 手动 |
| 5min 自动同步租户词库 | 手动观察日志 |
| tenants.json 持久化 | ls |
| `make diff-check` 通过 | CI |

---

## 七、风险与依赖

| 风险 | 应对 |
|---|---|
| qua HTTP API 具体路径/参数未确认 | M3 实施前需 qua 接口文档（OpenAPI/Swagger） |
| `pkg/asr/funasr` 当前 HTTP 实现**不支持流式** | 第一期流式只走 xunfei；funasr 流式待后续 Python 端支持 |
| qua token value 中 ID 超过 uint32 范围 | 全部走字符串 + `GetAuthInfo(ctx)`；不复用 `authn.GetAuthUserID` 的 uint32 返回 |
| 系统静态词条规模膨胀影响启动速度 | 启动只加载到内存 map（哈希查 O(1)），不做 Trie |
| Q9 周期同步期间旧词条不可用 | 同步使用「先 build 再 atomic swap」方式，零中断 |
| 多个实例同时跑本工具时的文件竞态 | tenants.json 写入加文件锁（`flock`）；第一期假设单实例，后续可加分布式锁 |
| LLM 步骤 | 保留 Step 注册 + 配置开关，不实现 |

---

## 八、开发顺序

```
M0 (proto+配置+骨架)  ──►  M1 (Provider 装配)  ──►  M2 (认证)
                                                            │
                                                            ▼
                              M9 (收口)  ◄──  M8 (流式)  ◄──  M7 (整段)
                                ▲                              │
                                │                              ▼
                          M6 (Pipeline)  ◄──  M5 (同步)  ◄──  M4 (静态词条)
                                                            ▲
                                                            │
                                                       (并行可启动)
```

每个 M 完成后：
1. `make proto && make config && make wire && make run` 全绿
2. 跑一遍该 M 的验收用例
3. 提交 backend-service 内
4. 更新 `4-6-治理-开发功能清单.md` 与 `4-7-治理-代码功能清单.md`
5. 进入下一 M

---

## 九、配套更新

完成后需同步：
1. `docs/architecture/4-6-治理-开发功能清单.md`：新增 §X.X `evie/tool` 模块 9 行
2. `docs/architecture/4-7-治理-代码功能清单.md`：标注代码文件落点
3. `docs/services/evie-platform/development/1-ASR语音识别服务.md`：补充「evie/tool 是其独立轻量化变体」
4. 本文件落档在 `development/` 目录，作为后续维护参考