# Ark Tech Platform 结构与开发规则

本文件描述当前仓库的真实结构。如果这里的规则和较早的归档文档存在冲突，以这里和当前代码为准。

## 顶层定义

当前仓库是 **Ark Tech Platform**，不等同于单一业务系统。GEO Engine、AI Agent Management、App Version Management 等是平台之上的 Ark Product Services。

## 仓库结构

```text
ark-tech-platform/
├── backend-service/          # Go + go-kratos 后端工作区
├── frontend-service/         # Vue Vben Admin pnpm monorepo
├── docs/architecture/        # 当前架构决策、服务边界和平台路线图
├── docs/services/            # Ark Product Services 目录和服务资料入口
├── docs/product/             # 产品需求、字段、验收标准和迭代规划
├── docs/vibe-coding/         # 代码规范与架构约定
├── docs/archive/             # 历史文档归档，不作为默认实现依据
├── backend-service-pkg-bakup/# 备份/参考包，不作为活跃开发目标
└── .agents/                  # 统一项目配置源（Claude Code + Codex 共用）
```

## 子仓库提交规则

`backend-service` 和 `frontend-service` 是独立子仓库。后续迭代涉及后端或后台代码变更时，需要分别维护子仓库提交，再回到根仓库更新子仓库指针。

规则：

- 后端代码变更在 `backend-service` 内提交。
- 前端后台代码变更在 `frontend-service` 内提交。
- 根仓库只提交文档变更、子仓库指针更新和根级配置变更。
- 不要只在根仓库提交而忽略子仓库内部提交。

## 后端规则

### 活跃服务

- `backend-service/app/platform/admin`：Ark Platform Foundation 基础管理后台服务，负责认证、用户、角色、菜单、权限、租户、套餐、配置、审计、会话、任务、文件、通知和产品服务配置入口。
- `backend-service/app/ai/service`：AI/chat 通用能力服务。
- `backend-service/app/version/service`：已存在的版本发布服务雏形，当前冻结，恢复前必须复审。

当前阶段采用"大仓 + 模块化服务边界优先"策略：

- `backend-service` 保持 go-kratos 大仓模式，`app` 下保留未来微服务拆分能力。
- `backend-service/app/platform/admin` 只承接平台基础能力，不承接 GEO、AI Agent、App Version Management 等具体产品业务。
- 产品服务需要先在 `docs/services` 定义后端落点；在服务边界确认前，不把新业务继续写入 `app/platform/admin`。
- 不要因为新增业务模块就默认创建新的 Kratos service。
- 只有模块需要独立部署、独立扩缩容、独立公共 API、独立数据生命周期或清晰业务域时，才考虑拆出独立服务。

### API 契约流程

```text
backend-service/proto
  -> backend-service/api
  -> app/*/internal/service
  -> app/*/internal/biz
  -> app/*/internal/data
  -> app/*/internal/data/ent/schema
```

- `backend-service/proto` 下的 Protobuf 文件是 API 事实来源。
- `backend-service/api` 下的生成文件不要手工编辑。
- 对外暴露 HTTP endpoint 时，使用 Google HTTP annotations 和 OpenAPI operation annotations。
- 创建重复消息前，优先复用 `proto/common`、`proto/common/pagination`、`proto/common/enum`、`proto/core/service/v1` 下已有的公共消息。

### 持久化与业务分层

- 业务编排和校验放在 `internal/biz` usecase 中。
- repository interface 放在 `internal/biz`，具体实现放在 `internal/data`。
- 数据库结构使用 `internal/data/ent/schema` 下的 Ent schema 表达。
- ID、status、timestamps、soft delete 等通用字段优先复用现有 mixins。
- 新增 usecase、repo 或 service 依赖时，同步更新 Wire provider set。

### 公共函数复用规则（先搜索，再生成）

> 目的：防止各模块重复实现等价工具函数。历史教训：曾出现 26 个功能相同、命名各异的指针辅助函数（`fileStringPtr`/`notificationStringPtr`/`auditStringPtr`/`deviceStringPtr`/`stringPtr` 等），已统一收敛到 `convert` 包。

- 新增任何**转换类/工具类**辅助函数前，必须先搜索公共包确认是否已有等价实现，不要直接生成。
- 常用公共包索引：
  - 类型转换：`backend-service/pkg/utils/convert`（`ToPointer[T]` / `EmptyToNil[T]` / `ToValue[T]` / `SliceToAny` / `StringToUint32` / `TimeValueToString` / `SliceContains` / `SliceUnique` 等）
  - 认证授权：`backend-service/pkg/auth`（`authn` / `authz` / `middleware`）
  - 分页与过滤：`backend-service/pkg/aip`、`backend-service/pkg/entgo/paging`
  - 对象存储：`backend-service/pkg/objectstorage`、`backend-service/pkg/filecenter`
  - 幂等：`backend-service/pkg/idempotency`；健康检查：`backend-service/pkg/health`
- **禁止**在业务模块内手写 `xxxPtr` / `xxxStringPtr` 等命名各异的重复指针辅助函数。一律使用 `convert.ToPointer[T]` 或 `convert.EmptyToNil[T]`。
- **语义区分（不可混用）**：
  - 纯取指针 → `convert.ToPointer[T]`（如 `convert.ToPointer("hello")` 返回 `*string`）
  - 空值/零值返回 nil → `convert.EmptyToNil[T]`（如 `convert.EmptyToNil("")` 返回 `nil`）
- 若公共包缺少该能力且确属跨模块通用场景，应把实现补到对应公共包（附单元测试），而不是写进单个业务模块。
- 复用前先确认签名与语义：`rg "func 函数名" backend-service/pkg`。

## 前端规则

`frontend-service/apps/web-antd-admin` 当前作为 Ark Tech Platform 管理后台前端。它使用 Vue 3、TypeScript、Vite、Vben Admin、Ant Design Vue、Pinia、Vue Router、`@vben/request` 和 pnpm workspace。

除非任务明确指定，以下 Vben 应用只作为示例或参考实现：

- `apps/web-antd`
- `apps/web-ele`
- `apps/web-naive`
- `apps/web-tdesign`
- `playground`

管理类 CRUD 页面遵循现有模式：

```text
Page + useVbenVxeGrid + useVbenDrawer + useVbenForm
```

## 命名与生成输出

- 前端 Vue 和 TypeScript 文件使用 kebab-case。
- 后端 Go 文件使用 snake_case。
- 文档描述用中文，路径、命令、API 名称、字段名保持英文。
- 不要手工修改生成的 Go、生成的 TypeScript、OpenAPI 输出、嵌入的 Swagger UI bundle 或 `node_modules`。
- 普通功能开发不要改示例、备份和 vendor-like assets。

## API 设计硬规则

> 违反以下规则的 PR 不得合并。详见 `docs/architecture/3-0-跨领域-API边界与通信契约.md`。

- **RPC 命名**: List/Get/Create/Update/Delete + CurrentTenant 区分控制面/数据面
- **HTTP 路径**: 控制面 `/admin/v1/{resource}`，数据面 `/admin/v1/current-tenant/{resource}`
- **分页**: 全部使用 `pagination.PagingRequest/PagingResponse`，默认 page_size=20
- **错误码**: kratos errors + UPPER_SNAKE_CASE（`PARAMETER_KEY_INVALID`）
- **枚举**: 首个值必须 `*_UNSPECIFIED = 0`
- **契约**: 每次 PR 运行 `buf lint` + `buf breaking`

## 数据库变更硬规则

> 违反以下规则的迁移不得执行。详见 `docs/architecture/0-3-架构总览-后端底座架构决策.md`。

- Schema 修改从 `ent/schema/*.go` 开始 → `make generate` → Atlas 迁移
- 删除字段：先废弃一个大版本，再物理删除
- 修改类型：新增字段 → 数据迁移 → 切换代码 → 删除旧字段
- 不手工改 `ent/gen/` 下生成代码

## Feature Flag 规则

> 详见 `docs/architecture/1-2-技术中台-套餐与配额设计.md`。

- Flag key: `snake_case`，不包含租户特定 ID
- 生命周期: 创建 → 灰度 → 全量 → 废弃 → 清理
- **Feature Flag 不替代权限校验**——后端必须独立授权

## 开发功能清单维护规则

> Ark Tech Platform 有两份功能清单，互为补充：
> - `docs/architecture/4-6-治理-开发功能清单.md` — 规划级清单，手动维护，按迭代和模块组织，记录设计文档引用和当前断点
> - `docs/architecture/4-7-治理-代码功能清单.md` — 代码级清单，代码扫描 + 人工维护，每个功能行包含源码追溯（Proto、Service、Schema 等文件路径）

### 两份清单的关系

- **4-6（规划清单）**：描述"要做什么"，按业务模块和迭代规划组织，是 PM/架构视角
- **4-7（代码清单）**：描述"代码里有什么"，按代码模块和 RPC 方法组织，是开发者视角
- 开发前：先读 4-6 确认业务范围和断点 → 再读 4-7 确认代码落点和已有实现
- 开发后：两份清单同步更新

### 开发前文档门禁（第一原则）

- 需求、验收标准、业务边界、非目标和代码落点未在文档中明确前，不开始或继续功能开发。
- 人工测试、重构或缺陷修复改变了实际行为时，先更新设计文档和两份清单，再决定是否进入下一功能。
- 代码已存在但尚未完成自动化验证或人工功能验证的条目统一标记为 `[~]`，不得标记为 `[x]`。
- `[x]` 只表示“实现完成 + 自动化验证通过 + 人工功能验证通过 + 文档已同步”。
- 文档与代码冲突时暂停扩展开发，先根据当前代码和验证结果完成文档收口。

### 4-7 代码功能清单维护规则

- 每个功能必须在清单中有对应条目，标注状态、优先级和源码追溯
- 开始开发 → `[ ]` 改为 `[~]`（进行中）
- 完成并验证 → `[~]` 改为 `[x]`，填写源码追溯列
- 调整优先级 → 修改 P 标记
- 暂停开发 → `[~]` 改为 `[.]`，注明原因
- 新增功能 → 在对应模块下追加一行，附源码追溯
- 代码删除/重构 → 更新对应行的源码追溯，无法匹配时标记 `<!-- orphan -->`
- 自动扫描（`make checklist-scan`）可发现新增的 RPC/Schema/页面，但不会覆盖人工修改的状态和优先级

### 4-6 规划清单维护规则（同原规则）

- 每个功能必须在清单中有对应条目，标注状态和优先级
- 开始开发 → `[ ]` 改为 `[~]`（进行中）
- 完成并验证 → `[~]` 改为 `[x]`
- 暂停开发 → `[~]` 改为 `[.]`，注明原因
- 新增功能 → 在对应模块下追加一行，附设计文档链接
- 每个迭代结束后更新「变更记录」
- 「当前断点」始终指向下一个待开始的任务
