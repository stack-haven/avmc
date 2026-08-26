# HTTP API 设计规范（AIP 对齐）

日期：2026-08-04
状态：草案（待评审）
范围：Ark Tech Platform 所有后端服务的对外 HTTP 接口
依据：Google AIP（API Improvement Proposals）+ Buf 生态 + go-kratos 实现机制

---

## 一、背景与目标

当前后端 HTTP 接口存在规范不一致，典型症状：

- 自定义动作分隔符混乱：`POST /files/{id}/replace`（❌ 斜杠）vs `POST /asr/records/{id}:re-recognize`（✅ 冒号）
- 动作位置反模式：`PUT /users/status-update/{id}`（❌）vs `PUT /users/{id}:status-update`（✅）
- 服务前缀重复：`/ai/v1/ai/chats`（❌）vs `/evie/v1/asr/records`（✅）

本规范以 Google AIP 为基准，结合 go-kratos 的实现机制，统一 HTTP 接口的路径、方法与参数传递规则。

**核心原则：**
1. **资源导向**（Resource-oriented）——路径围绕资源，动作用自定义方法表达
2. **标准优先**——能用标准方法（CRUD）就不用自定义方法
3. **冒号语义**——自定义动作用 `:`，子资源用 `/`，二者不可混淆

---

## 二、术语定义

| 术语 | 英文 | 定义 | AIP |
|------|------|------|-----|
| **集合** | Collection | 一类资源的集合，复数名词 | AIP-121 |
| **资源** | Resource | 集合中的单个实例，由 ID 寻址 | AIP-121 |
| **标准方法** | Standard Method | List/Get/Create/Update/Delete | AIP-131~135 |
| **自定义方法** | Custom Method | 无法用标准方法表达的动作，用 `:` 分隔 | AIP-136 |
| **子资源** | Sub-resource | 依附于父资源、有独立生命周期的资源 | AIP-122 |
| **数据面** | Data Plane | 从 JWT context 提取身份的资源访问 | — |

---

## 三、服务前缀规范

```
/{service-name}/{version}/{resource-path}

示例:
  /platform/v1/...  # platform/service 服务（原 platform/admin）
  /evie/v1/...      # evie 产品服务
  /ai/v1/...        # ai 服务
```

**规则：**
- 每个服务一个前缀，格式 `/{service-name}/{version}`，版本用 `v1`、`v2`
- **禁止重复服务名**：`/ai/v1/ai/chats` ❌，`/ai/v1/chats` ✅
- 前缀一经发布不可变更（破坏性）
- 平台服务前缀为 `/platform/v1`；产品服务按服务名独立（如 `/evie/v1`、`/ai/v1`）

| 服务 | 前缀 | 现状 |
|------|------|:---:|
| platform/service | `/platform/v1` | ✅ |
| evie | `/evie/v1` | ✅ |
| ai | `/ai/v1` | ❌ 现为 `/ai/v1/ai/` |

---

## 四、资源命名规范（AIP-121 / AIP-122）

### 4.1 集合与资源

```
集合:  /{prefix}/{resources}           # 复数 kebab-case
资源:  /{prefix}/{resources}/{id}      # id 为字符串或数字
```

**规则：**
- 资源名用**复数 + kebab-case**：`storage-providers`、`tenant-menu-permission-groups`
- 禁止单数：`/user` ❌，`/users` ✅
- 禁止驼峰/下划线：`/tenantMenuPermissionGroups` ❌，`/tenant-menu-permission-groups` ✅

### 4.2 子资源（AIP-122）

子资源是**有独立 ID 和生命周期**的资源，嵌套在父资源下：

```
GET /{prefix}/{resources}/{id}/{sub-resources}          # 列表
GET /{prefix}/{resources}/{id}/{sub-resources}/{sid}    # 单个
```

**示例：**
- `GET /platform/v1/files/{id}/parts` — 分片是文件的子资源（有独立 partNumber）✅
- `GET /platform/v1/files/{file_id}/access-logs` — 访问日志是子资源 ✅
- `GET /platform/v1/tenants/{tenant_id}/admins` — 租户管理员是子资源 ✅

**反模式：** 把"动作"伪装成子资源
- `POST /platform/v1/files/{id}/replace` ❌（replace 是动作，不是子资源；正确写法 `:replace`）

---

## 五、标准方法规范（AIP-131 ~ AIP-135）

| 方法 | HTTP | 路径 | RPC 命名 |
|------|------|------|---------|
| List | GET | `/{prefix}/{resources}` | `List{Resources}` |
| Get | GET | `/{prefix}/{resources}/{id}` | `Get{Resource}` |
| Create | POST | `/{prefix}/{resources}` | `Create{Resource}` |
| Update | PUT | `/{prefix}/{resources}/{id}` | `Update{Resource}` |
| Delete | DELETE | `/{prefix}/{resources}/{id}` | `Delete{Resource}` |

**示例：**

```proto
rpc ListFileObjects(...) returns (...) {
  option (google.api.http) = {get: "/platform/v1/files"};
}
rpc GetFileObject(...) returns (...) {
  option (google.api.http) = {get: "/platform/v1/files/{id}"};
}
rpc CreateFileUploadSession(...) returns (...) {
  option (google.api.http) = {
    post: "/platform/v1/files/upload-sessions"
    body: "*"
  };
}
rpc UpdateFileObject(...) returns (...) {
  option (google.api.http) = {
    put: "/platform/v1/files/{id}"
    body: "*"
  };
}
rpc DeleteFileObject(...) returns (...) {
  option (google.api.http) = {delete: "/platform/v1/files/{id}"};
}
```

**规则：**
- Update 统一用 `PUT`（全量更新语义，kratos 惯用）
- 列表必须支持分页（见第八节）

---

## 六、自定义方法规范（AIP-136）⭐ 核心

自定义方法用于**无法用标准方法表达的动作**（如状态切换、批量操作、特殊计算）。

### 6.1 语法

```
资源级自定义方法:  POST /{prefix}/{resources}/{id}:{verb}
集合级自定义方法:  POST /{prefix}/{resources}:{verb}
```

**关键：动词用冒号 `:` 分隔，不是斜杠 `/`。**

### 6.2 动词命名

- 用 **kebab-case 动词**（描述动作，非名词）
- 例：`cancel`、`retry`、`set-default`、`transfer-and-delete`、`re-recognize`

### 6.3 正反例对照

| ✅ 正确 | ❌ 错误 | 错误类型 |
|--------|--------|---------|
| `POST /platform/v1/files/{id}:replace` | `POST /platform/v1/files/{id}/replace` | 斜杠分隔动作 |
| `POST /platform/v1/files/{id}:confirm` | `POST /platform/v1/files/{id}/confirm` | 斜杠分隔动作 |
| `POST /platform/v1/async-tasks/{id}:cancel` | `POST /platform/v1/async-tasks/cancel/{id}` | 动作位置错误 |
| `POST /platform/v1/async-tasks:stats` | `GET /platform/v1/async-tasks/stats` | 集合级动作用错 |
| `PUT /platform/v1/users/{id}:status-update` | `PUT /platform/v1/users/status-update/{id}` | 动作位置错误 + 分隔符错误 |

### 6.4 自定义方法的 HTTP 方法选择

| 副作用 | HTTP | 示例 |
|--------|------|------|
| 有副作用（修改状态） | POST | `:cancel`、`:retry`、`:replace` |
| 无副作用（纯查询） | GET | `:stats`、`:unread-count` |

---

## 七、数据面规范（用户级 vs 租户级）

数据面接口从 JWT context 提取身份，不接受客户端传 tenant_id。

**两种数据面语义，必须区分：**

| 类型 | 前缀 | 语义 | RPC 命名 | 示例 |
|------|------|------|---------|------|
| **用户级** | `/my/` | 当前登录用户自己的资源 | `ListMy{Resources}` | `/platform/v1/my/devices`、`/platform/v1/my/notifications` |
| **租户级** | `/current-tenant/` | 当前租户的共享资源 | `ListCurrentTenant{Resources}` | `/platform/v1/current-tenant/parameters` |

**规则：**
- `my/*` = 当前用户（user-scoped）：我的设备、我的通知、我的会话
- `current-tenant/*` = 当前租户（tenant-scoped）：当前租户的参数、有效菜单
- 二者不可混用：当前租户的参数不能用 `/my/parameters`

**现状问题：**
- RPC 命名混用：`ListMyDevices`（✅ 用户级）vs `ListCurrentTenantParameters`（✅ 租户级）——语义本不同，但需在文档明确
- 文档 3-0 只写了 `current-tenant`，遗漏了 `my`，需补充

---

## 八、参数传递规范

### 8.1 路径参数（Path Params）

```proto
rpc GetFileObject(GetFileObjectRequest) returns (...) {
  option (google.api.http) = {get: "/platform/v1/files/{id}"};
}
```

- 路径变量 `{id}` 由 kratos `BindVars` 自动绑定到 request 的对应字段
- 字段名与路径变量名一致（`{id}` ↔ `id`）

### 8.2 查询参数（Query Params）

```proto
rpc ListFileObjects(ListFileObjectsRequest) returns (...) {
  option (google.api.http) = {get: "/platform/v1/files"};
}
```

- 分页：`page_size`、`page_token`（AIP-158）
- 筛选：`filter`（AIP-160 标准语法）
- 排序：`order_by`（`field desc` / `-field`）
- 绑定：kratos `BindQuery`

### 8.3 请求体（Body）

```proto
rpc CreateFileUploadSession(CreateFileUploadSessionRequest) returns (...) {
  option (google.api.http) = {
    post: "/platform/v1/files/upload-sessions"
    body: "*"     # 整个 message 作为 body
  };
}
```

- 有 body 的 POST/PUT 必须显式写 `body: "*"`（或 `body: "field"`）
- GET/DELETE 禁止 body

### 8.4 幂等性

- 写操作支持 `idempotency_key` 时，通过 body 字段或 header 传递
- 破坏性操作（Delete）必须能通过 idempotency key 防重

---

## 九、反模式清单（禁止项）

| # | 反模式 | 禁止原因 | 正确写法 |
|---|--------|---------|---------|
| 1 | `/{id}/{verb}` 斜杠动作 | 与子资源混淆 | `/{id}:{verb}` |
| 2 | `/{verb}/{id}` 动作前置 | 路径顺序错误 | `/{id}:{verb}` |
| 3 | 服务名重复 `/ai/v1/ai/` | 冗余 | `/ai/v1/` |
| 4 | 单数资源名 `/user` | 不符合 AIP | `/users` |
| 5 | 驼峰路径 `/tenantMenuGroup` | 不符合 AIP | `/tenant-menu-permission-groups` |
| 6 | 动作伪装子资源 | 语义混乱 | 用 `:` 自定义方法 |
| 7 | `my` 与 `current-tenant` 混用 | 语义混淆 | 按用户级/租户级区分 |

---

## 十、与技术底座的映射（kratos 实现机制）

> 关键结论：**后端鉴权与 HTTP 路径解耦**，改路径不影响 action 解析。

### 10.1 Operation 解析机制

```
请求进入 kratos http server
  ↓
gorilla/mux 匹配路由，得到 path template（如 /platform/v1/files/{id}:replace）
  ↓
生成的 http handler 执行 http.SetOperation(ctx, OperationXxx)
  ↓
operation 被覆盖为 gRPC 方法路径（如 /platform.service.v1.FileCenterService/ReplaceFileContent）
  ↓
鉴权中间件 / 白名单 / Casbin / authzpolicy 全部使用 gRPC 方法路径
```

### 10.2 影响面结论

| 变更内容 | 影响后端 action | 影响路由注册 | 影响前端 |
|---------|:---:|:---:|:---:|
| 改 HTTP 路径（`/replace` → `:replace`） | ❌ 不影响 | ✅ 影响 | ✅ 影响 |
| 改 RPC 方法名 | ✅ 影响 | ❌ 不影响 | ❌ 不影响 |
| 改 proto message 字段 | 可能影响 | ❌ | ✅ |

**因此：** HTTP 路径规范化是**低风险变更**，后端鉴权逻辑零改动。

---

## 十一、合规检查（Buf 生态）

### 11.1 buf lint（已有）

`buf.yaml` 已启用 `STANDARD` 规则，覆盖：
- `RPC_REQUEST_RESPONSE_UNIQUE`、`SERVICE_SUFFIX` 等命名规则
- `PACKAGE_VERSION_SUFFIX` 等包规则

**局限：** buf 无法检查 AIP 的 HTTP 路径自定义方法规范（冒号 vs 斜杠）。

### 11.2 自定义合规脚本（已实现）

已提供 `backend-service/scripts/check-http-path-convention.sh`，检查三项违规：

```bash
# 手动运行
cd backend-service && ./scripts/check-http-path-convention.sh

# Makefile target
cd backend-service && make http-convention-check
```

检查规则：
1. 动作前置反模式：`/{resource}/{verb}/{id}`（如 `/users/status-update/{id}`）
2. 斜杠动作：`/{resource}/{id}/{verb}`（如 `/files/{id}/replace`）
3. 服务名重复：`/{service}/v1/{service}/`（如 `/ai/v1/ai/`）

### 11.3 buf breaking

路径变更不触发 `FILE` 级 breaking（注解不影响 wire 格式），但需：
1. 跑 `buf breaking` 确认
2. 前端同步更新后联调

---

## 十二、迁移映射表

> **迁移状态（2026-08 更新）**：
> - 平台层（platform/service）已统一为 `/platform/v1/` 前缀 + AIP-136 冒号自定义方法（12.1、12.2 全部完成）
> - AI 服务仍遗留 `/ai/v1/ai/` 重复服务名（12.3 待迁移）

### 12.1 文件中心（8 处）

| 原状（迁移前 ❌） | 目标（✅ 已迁移） | RPC（不变） |
|-----------|-----------|------------|
| `POST /platform/v1/files/{id}/replace` | `POST /platform/v1/files/{id}:replace` | `ReplaceFileContent` |
| `POST /platform/v1/files/{id}/confirm` | `POST /platform/v1/files/{id}:confirm` | `ConfirmFileUpload` |
| `POST /platform/v1/files/{id}/complete` | `POST /platform/v1/files/{id}:complete` | `CompleteFileUpload` |
| `POST /platform/v1/files/{id}/abort` | `POST /platform/v1/files/{id}:abort` | `AbortFileUpload` |
| `GET /platform/v1/files/{id}/download` | `GET /platform/v1/files/{id}:download` | `DownloadFileContent` |
| `GET /platform/v1/files/{id}/download-url` | `GET /platform/v1/files/{id}:download-url` | `PresignFileDownload` |
| `POST /platform/v1/files/{id}/content` | `POST /platform/v1/files/{id}:content` | `UploadFileContent` |
| `POST /platform/v1/files/upload-sessions` | `POST /platform/v1/files:upload-sessions`（集合级自定义） | `CreateFileUploadSession` |

### 12.2 status-update 反模式（8 处）

| 原状（迁移前 ❌） | 目标（✅ 已迁移） |
|-----------|-----------|
| `PUT /platform/v1/users/status-update/{id}` | `POST /platform/v1/users/{id}:status-update` |
| `PUT /platform/v1/menus/status-update/{id}` | `POST /platform/v1/menus/{id}:status-update` |
| `PUT /platform/v1/depts/status-update/{id}` | `POST /platform/v1/depts/{id}:status-update` |
| `PUT /platform/v1/roles/status-update/{id}` | `POST /platform/v1/roles/{id}:status-update` |
| `PUT /platform/v1/posts/status-update/{id}` | `POST /platform/v1/posts/{id}:status-update` |
| `PUT /platform/v1/projects/status-update/{id}` | `POST /platform/v1/projects/{id}:status-update` |
| `PUT /platform/v1/tenant-menu-permission-groups/status-update/{id}` | `POST /platform/v1/tenant-menu-permission-groups/{id}:status-update` |

### 12.3 AI 服务待迁移（服务名重复 + status-update）

| 原状（迁移前 ❌） | 目标（待迁移 ✅） |
|-----------|-----------|
| `PUT /ai/v1/ai/chats/status-update/{id}` | `POST /ai/v1/chats/{id}:status-update` |
| `/ai/v1/ai/chats` | `/ai/v1/chats` |
| `/ai/v1/ai/chats/{id}` | `/ai/v1/chats/{id}` |
| `/ai/v1/ai/chats/simple` | `/ai/v1/chats/simple` |
| `/ai/v1/ai/chats/stream` | `POST /ai/v1/chats:stream` |

---

## 十三、待评审决策点

| # | 决策点 | 建议 | 影响 |
|---|--------|------|------|
| 1 | `my` vs `current-tenant` 是否都保留？ | 保留两者，明确区分用户级/租户级 | 文档澄清 |
| 2 | Update 用 PUT 还是 PATCH？ | PUT（保持现状） | 无变更 |
| 3 | status-update 从 PUT 改 POST？ | 是（有副作用，AIP-136） | 前端 method 变更 |
| 4 | 是否允许破坏性变更（直接切换路径）？ | 需确认是否有生产调用方 | 迁移策略 |
| 5 | 是否新增 CI 合规脚本？ | 是 | 工程化 |
