---
description: |
  为 Ark Tech Platform 后端生成完整 CRUD 全链路代码。当需要新增业务模块并走完 proto → service → biz → data → ent → wire 完整链路时触发。

  触发场景：
  - "新增 XXX 管理的 CRUD" / "为 XXX 创建后端接口"
  - "创建版本管理的 proto 定义和实现"
  - "给 XXX 加一个列表/创建/编辑/删除接口"
  - 任何需要后端六层骨架生成的任务

  需要用户提供的输入：模块名称、字段列表及其类型、权限要求。
name: avmc-backend-crud
---

# Ark Tech Platform 后端 CRUD 生成

生成后端 CRUD 六层代码，确保所有分层一致且符合项目约定。

## 输入要求

开始前向用户确认以下信息：

| 项目 | 说明 | 示例 |
|------|------|------|
| **模块名** | 英文单数名词 | `version` |
| **所属服务** | admin/ai/version | `admin` |
| **字段列表** | 每个字段的名称、类型、校验规则 | name(string,required), code(int32,unique) |
| **权限控制** | 是否需要项目隔离 / 角色限制 | 项目级隔离，仅 admin 可写 |
| **列表接口** | 需要哪些筛选/排序/分页维度 | 按项目筛选、按状态筛选、按创建时间排序 |
| **关联关系** | 是否关联现有数据模型（用户、项目等） | 关联 project |
| **特殊行为** | 回滚、灰度发布等业务逻辑 | 支持状态变更记录 |

**功能清单确认（必须）：**

生成代码前，读取 `docs/architecture/4-7-治理-代码功能清单.md`。在对应模块下追加新的功能行（状态 `[~]`、对应优先级），或在已有行上确认范围。代码生成完成后，将功能行状态更新为 `[x]` 并填写生成的 Proto、Service、UseCase、Schema 等源文件路径。

## 生成

### 1. Protobuf 契约（`backend-service/proto/platform/admin/v1/`）

生成以下消息和 RPC 定义：

```protobuf
service IXxx {
    rpc CreateXxx(CreateXxxRequest) returns (CreateXxxResponse) { option (google.api.http) = { post: "/admin/v1/xxx" body: "*" }; }
    rpc GetXxx(GetXxxRequest) returns (GetXxxResponse) { option (google.api.http) = { get: "/admin/v1/xxx/{id}" }; }
    rpc UpdateXxx(UpdateXxxRequest) returns (UpdateXxxResponse) { option (google.api.http) = { put: "/admin/v1/xxx/{id}" body: "*" }; }
    rpc DeleteXxx(DeleteXxxRequest) returns (DeleteXxxResponse) { option (google.api.http) = { delete: "/admin/v1/xxx/{id}" }; }
    rpc ListXxx(ListXxxRequest) returns (ListXxxResponse) { option (google.api.http) = { get: "/admin/v1/xxx" }; }
}
```

优先复用 `proto/common/` 下的分页、枚举、空消息。

### 2. Ent Schema（`internal/data/ent/schema/`）

使用现有 mixins 处理通用字段：
- `internal/data/ent/mixins/v1` 中的 `StatusMixin`、`TimeMixin`、`SoftDeleteMixin`
- ID 生成策略与现有 schema 保持一致
- 通用字段不要重复定义

### 3. Repository Interface（`internal/biz/`）

定义在 biz 层，与现有 xxx_repo.go 风格一致：

```go
type XxxRepo interface {
    Save(ctx context.Context, xxx *Xxx) (*Xxx, error)
    Update(ctx context.Context, xxx *Xxx) (*Xxx, error)
    Delete(ctx context.Context, id int64) error
    FindByID(ctx context.Context, id int64) (*Xxx, error)
    List(ctx context.Context, params *XxxListParams) ([]*Xxx, int64, error)
}
```

### 4. Usecase（`internal/biz/`）

业务编排和校验放在 usecase 中。包括：
- 创建/更新前的字段校验
- 状态变更的业务规则
- 项目权限检查（如需）
- 操作日志记录（如需）

### 5. Repository 实现（`internal/data/`）

遵循现有 repo 模式：
- 分页使用现有 `paging` 工具
- 筛选使用 AIP 标准风格（保持与现有接口兼容）
- 事务使用 Ent 的 Tx API

### 6. Service 实现（`internal/service/`）

在 service 层处理：
- 请求参数校验
- Protobuf 消息到业务模型的转换
- 业务模型到 Protobuf 响应的组装
- 错误转换为 gRPC/HTTP 错误

### 7. Wire Provider（`cmd/server/wire.go`）

在 wire provider set 中添加新依赖。**必须**同步更新 wire_gen.go——运行 `make wire` 重新生成。

### 8. 基础测试

为 usecase 和 repo 添加表驱动测试：
- 正常创建/查询/更新/删除流程
- 参数校验失败
- 资源不存在
- 权限拒绝
- 列表分页/筛选/排序

## 验证

```bash
cd backend-service/app/platform/admin
go build ./...
go test ./...
```

## 参考现有实现

创建前先阅读相似复杂度的现有模块作为模板：
- **简单 CRUD（无项目关联）**：参考 `post` 或 `dept` 模块
- **项目级 CRUD**：参考 `project` 模块
- **级联关系 CRUD**：参考 `menu` 模块（父子关系）
