# Ark Tech Platform 指南

本文件是 Claude Code、Codex 等 coding agent 进入项目的统一入口。修改代码或文档前必须先读本文件。

## 项目概述

Ark Tech Platform 是面向多产品 SaaS 的技术平台与业务承载底座，提供多租户、认证授权、数据隔离、菜单权限、业务套餐、资源配额、操作审计、参数配置、异步任务、文件、通知和产品服务接入能力。

GEO Engine、AI Agent Management、App Version Management 等是平台之上的 **Ark Product Services**，不代表平台本身。

## 仓库结构

```text
ark-tech-platform/
├── backend-service/          # Go + go-kratos 后端工作区（子仓库）
├── frontend-service/         # Vue Vben Admin pnpm monorepo（子仓库）
├── docs/architecture/        # 当前架构决策、服务边界和平台路线图
├── docs/services/            # Ark Product Services 定义和资料入口
├── docs/product/             # 产品需求、字段、验收标准和迭代规划
├── docs/vibe-coding/         # 代码规范与工程约定
├── docs/archive/             # 历史文档归档，不作为默认实现依据
├── backend-service-pkg-bakup/# 备份/参考包，不作为活跃开发目标
└── .agents/                  # 统一项目配置源（Claude Code + Codex 共用）
```

## 必读入口

1. `.agents/AGENTS.md`（本文件）
2. `.agents/RULES.md` — 结构与开发规则
3. `.agents/DESIGN.md` — 产品与 UI 设计规则
4. `.agents/REVIEW.md` — Code Review 检查清单（安全/架构/契约/风格）
5. `docs/architecture/README.md`
6. `docs/architecture/0-0-架构总览-架构总览.md` — 架构第一入口
7. `docs/architecture/0-3-架构总览-后端底座架构决策.md`
8. `docs/services/README.md`

实现类任务的推荐阅读顺序：

1. `.agents/AGENTS.md`
2. `.agents/RULES.md`
3. `.agents/DESIGN.md`
4. `docs/architecture/README.md`
5. `docs/architecture/0-0-架构总览-架构总览.md`
6. `docs/architecture/0-1-架构总览-平台分层设计.md`
7. `docs/architecture/0-2-架构总览-技术栈与工程基线.md`
8. `docs/architecture/0-3-架构总览-后端底座架构决策.md`
9. `docs/services/README.md`
10. `docs/architecture/4-6-治理-开发功能清单.md` — 当前开发状态和断点
11. `docs/architecture/4-7-治理-代码功能清单.md` — 代码落点和人工验证状态
12. 同一后端服务或前端应用中最接近的现有代码
13. `docs/product/README.md`
14. `docs/vibe-coding/*/README.md`
15. `docs/archive/*` 仅用于追溯历史需求来源

当前代码、`.agents/`、`docs/architecture/`、`docs/services/` 和 `docs/product/` 是事实来源。

## 子仓库提交规则

`backend-service` 和 `frontend-service` 是独立子仓库。

推荐提交顺序：

1. 在 `backend-service` 或 `frontend-service` 内完成代码提交。
2. 回到根仓库确认对应子仓库指针变化。
3. 在根仓库提交子仓库指针更新和相关文档。

根仓库只提交文档变更、子仓库指针更新和根级配置变更。

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端 | Go 1.24.6 + go-kratos v2（大仓 + 模块化服务边界） |
| API | Protobuf + gRPC + HTTP annotations + Buf |
| ORM | Ent v0.14.5 |
| DI | Wire v0.7.0 |
| 前端 | Vue 3 + TypeScript + Vben Admin + Ant Design Vue |
| 构建 | Vite + pnpm workspace + Turbo |
| 状态管理 | Pinia |
| 数据库 | MySQL / PostgreSQL |
| 缓存 | Redis |
| 认证鉴权 | pkg/auth（JWT/OIDC 本地认证 + Casbin 鉴权 + Redis 会话，详见 `backend-service/pkg/auth/README.md`） |

## 活跃开发区域

### 后端

- `backend-service/app/platform/service`：Ark Platform Foundation 基础管理后台服务，负责租户、认证、用户、角色、菜单、权限、套餐、配置、审计、会话、任务、文件、通知等平台基础能力。
- `backend-service/app/ai/service`：AI/chat 通用能力服务。
- `backend-service/app/evie/service`：Evie ASR 产品服务，负责语音识别、词库中心、文本增强引擎（gRPC + HTTP 合一，`/evie/v1`）。
- `backend-service/app/version/service`：历史版本发布服务雏形，当前冻结，待复审。

当前阶段采用"大仓 + 模块化服务边界优先"策略：
- `backend-service/app/platform/service` 只承接平台基础能力，不承接 GEO、AI Agent、App Version Management 等具体产品业务。
- 产品服务需要先在 `docs/services` 定义后端落点；在服务边界确认前，不把新业务写入 `app/platform/service`。
- 不要因为新增业务模块就默认创建新的 Kratos service。
- 只有模块需要独立部署、独立扩缩容、独立公共 API、独立数据生命周期或清晰业务域时，才考虑拆出独立服务。

### 前端

- `frontend-service/apps/web-antd-admin`：Ark Tech Platform 管理后台前端默认开发目标。
- 其他 Vben 应用 `web-antd`、`web-ele`、`web-naive`、`web-tdesign`、`playground` 只作为示例或参考。

`frontend-service/packages` 下的共享前端包只用于跨应用的 Vben 公共能力。不要把一次性的产品服务页面逻辑放进去。

## 后端开发规则

### API 契约流程

```text
backend-service/proto
  → backend-service/api（生成，勿手改）
  → app/*/internal/service
  → app/*/internal/biz
  → app/*/internal/data
  → app/*/internal/data/ent/schema
```

- `backend-service/proto` 是 API 事实来源。
- `backend-service/api` 下的生成文件不要手工编辑。
- 对外暴露 HTTP endpoint 时使用 Google HTTP annotations。
- 优先复用 `proto/common`、`proto/common/pagination`、`proto/common/enum`、`proto/platform/service/v1` 下的公共消息。

### 业务规则

- 业务编排和校验放在 `internal/biz` usecase 中。
- repository interface 放在 `internal/biz`，具体实现放在 `internal/data`。
- 数据库结构使用 `internal/data/ent/schema` 下的 Ent schema 表达。
- ID、status、timestamps、soft delete 等通用字段优先复用现有 mixins。
- 新增 usecase、repo 或 service 依赖时，同步更新 Wire provider set。

### 必守约束

- 权限控制必须在后端执行，不能只依赖前端隐藏。
- 租户级和项目级资源访问必须验证边界。
- 认证失败、无权限和资源不存在应返回可区分的错误。
- 生成代码（`backend-service/api`、`internal/data/ent/gen`、Swagger UI bundle）不手工修改。

## 前端开发规则

### 标准管理页模式

```text
Page + useVbenVxeGrid + useVbenDrawer + useVbenForm + ant-design-vue message/Modal
```

文件组织：

```text
list.vue      # 页面壳、表格、工具栏、行操作
data.ts       # table columns、filter schema、form schema
modules/      # drawer/modal/detail components
api/          # request wrappers
locales/      # zh-CN 和 en-US labels
```

### 前端约束

- 应用内部使用 `#/` imports；共享 Vben 依赖使用 workspace package imports。
- 新增可见文案时，同时添加中文和英文 locale key。
- 路由模块放在 `src/router/routes/modules`。
- 菜单标题使用 i18n key，不硬编码可见字符串。
- 破坏性操作必须确认，例如删除、发布、撤回、回滚。
- 状态切换在提交到服务端前应确认用户意图。

## 文档规则

- 使用 `docs/product`，不使用 `doc/product`。
- 使用 `docs/vibe-coding`，不使用 `doc/vibe-coding`。
- 当前事实来源以 `.agents/`、`docs/architecture/`、`docs/services/` 为准。
- `docs/archive/` 只作历史来源，不作为当前实现依据。
- 文档说明优先使用中文；技术标识、路径、命令、API 名称保持英文原样。
- 如果旧产品文档和当前代码冲突，把旧产品文档视为历史资料。

### 文档保鲜

- 代码 PR 涉及架构变更时，同步检查对应架构文档
- 文档中引用的路径、命令必须与当前 Makefile/CI 一致
- 状态为"设计阶段"的架构文档超过 6 个月自动标记 `🔴 待复审`
- `4-3-治理-能力路线图` 和 `4-6-治理-开发功能清单` 必须在每个迭代完成后更新

### 开发工作流

- **第一原则：需求和文档先于开发**。开始或继续任何功能前，必须先明确需求、验收标准、边界和非目标，并更新对应设计文档及 `4-6`/`4-7` 清单；文档未收口时不得进入下一功能开发。
- **开始新功能** → 先查 `4-6-治理-开发功能清单` 明确需求、状态和优先级，再查 `4-7-治理-代码功能清单` 确认代码落点
- **功能完成** → 代码完成先标记 `[~]`；自动化验证和人工功能验证均完成后才更新为 `[x]`，并同步设计文档和验证证据
- **人工测试或重构后** → 先修复文档与清单偏差，未验证项保持 `[~]`，不得用“代码存在”代替“已完成并验证”
- **调整优先级** → 直接编辑清单中的 P0/P1/P2/P3 标记
- **新增小功能** → 在对应模块下追加一行
- **中断后恢复** → 读清单「当前断点」→ 读对应设计文档 → 开发

## Agent 决策权限分级

> Agent（Claude Code / Codex 等）必须按以下三档执行。`autonomous` 可独立完成；`requires-confirmation` 必须取得用户/架构师确认；`forbidden` 不得自行决定。人读总纲见 `docs/architecture/0-4-架构总览-工程治理总纲.md`。

### autonomous（可自主完成）

- 已确认方案的具体代码实现
- 单元测试、契约测试编写
- 常规重构（不改变公共契约、不跨服务边界）
- 文档更新（路径、命令、状态、清单状态）
- 静态检查、格式化、lint 修复
- 常规错误修复（错误码、日志、租户隔离细节）
- 已设计文档确认的 schema/接口字段调整
- 复用已有公共包、SKILL、模板的同类任务

### requires-confirmation（必须用户或架构师确认）

| 触发条件 | 确认对象 |
|---|---|
| 新增核心基础设施（如新公共包、新中间件、新数据库迁移机制） | 架构师 |
| 修改租户隔离模型（mixin / privacy / SQL 过滤层） | 架构师 |
| 修改认证授权架构（JWT、OIDC、Casbin、session 协议） | 架构师 + 安全负责人 |
| 改变公共 API 契约（含 `/platform/v1`、`/evie/v1`、`/ai/v1` 等面向多产品或对外的 API） | 架构师 |
| 大规模数据库迁移（影响 ≥1 张表的全量/结构迁移） | DBA + 架构师 |
| 引入新的核心框架或运行时（替换 Gin/Kratos/Ent/Vben 等） | 架构师 |
| 修改 Platform-Product 边界（哪些能力归中台、哪些归产品） | 架构师 + 产品负责人 |
| 可能影响多产品的公共能力（pkg/、公共 proto、跨服务客户端） | 架构师 |

### forbidden（不得自行决定）

- 产品核心定位（目标用户、市场、价值主张）
- 业务规则（状态机、权限矩阵、审批流、配额策略）
- 商业模式、定价、订阅/计费策略
- 产品优先级、迭代排序
- 未经讨论的架构方向（如新增拆分、合并模块）
- 破坏性 API 变更（字段删除/重命名、字段类型修改、语义变更）
- 跨租户/跨产品数据可见性策略

> 触发上述任一项时，Agent 必须停止编码，回到「Explore 模式」或等待用户重新确认。

## 协作模式

| 模式 | 目标 | 是否允许改代码 | 适用 skill |
|---|---|:--:|---|
| Explore 模式 | 现状发现、风险评估、影响矩阵、方案草拟 | ❌ 仅只读 | `avmc-feature-delivery`（分析侧）、`avmc-contract-first-backend`（调研侧） |
| Implement 模式 | 在已确认方案上完成编码、测试、文档、验证 | ✅ | `avmc-feature-delivery`、`avmc-contract-first-backend`、`avmc-backend-crud`、`avmc-frontend-page`、`avmc-submodule-sync` |
| Review 模式 | 功能完成后做架构/安全/测试/性能/可维护性/文档审查 | ⚠️ 仅修复审查发现 | `avmc-cross-repo-review`、`code-review-checklist`、`go-testing-code-review` |

**模式门禁**：

- 未完成 Explore 阶段并获得用户确认，不得进入 Implement。
- Implement 完成 + 自动化验证（make check / buf breaking / typecheck / build）通过 → `[~]`；人工功能验证 + 文档同步完成后 → `[x]`，再进入 Review。
- Review 阶段发现的缺陷一律回退到 Implement 修复，不得在 Review 模式直接改业务代码。

## API 设计规范

> 新增 API 时必须遵守，从 `backend-service/proto/` 实际代码提炼。

- **RPC 命名**: List/Get/Create/Update/Delete + CurrentTenant 前缀（租户数据面）
- **路径**:
  - 服务前缀 `/{service-name}/{version}`：平台 `/platform/v1`、产品服务 `/evie/v1`、`/ai/v1` 等
  - 平台控制面 `/platform/v1/{resource}`
  - 用户级数据面 `/platform/v1/my/{resource}`
  - 租户级数据面 `/platform/v1/current-tenant/{resource}`
- **分页**: 统一使用 `pagination.PagingRequest/PagingResponse`
- **错误码**: kratos errors UPPER_SNAKE_CASE（如 `PARAMETER_KEY_INVALID`）
- **枚举**: 首个值必须 `*_UNSPECIFIED = 0`
- **契约检查**: `buf lint` + `buf breaking`（每次 PR）
- 详见 `docs/architecture/3-0-跨领域-API边界与通信契约.md`、`docs/architecture/3-4-跨领域-HTTP-API设计规范.md`

## 数据库变更规范

- Schema 修改先改 `ent/schema/*.go`，再 `make generate`，再 Atlas 迁移
- 删除字段：先标记废弃，数据迁移后物理删除
- 修改类型：新增字段 → 迁移 → 切换 → 删除旧字段
- 详见 `docs/architecture/0-3-架构总览-后端底座架构决策.md`

## Feature Flag 规范

- Flag key 命名: `snake_case`，不含租户特定信息
- 前端通过 `usePlatformCapability().hasFeature()` 统一消费
- Feature Flag 不替代权限校验——后端必须独立授权
- 生命周期: 创建 → 灰度 → 全量 → 废弃 → 清理
- 详见 `docs/architecture/1-2-技术中台-套餐与配额设计.md`

## 默认避免修改的区域

- `backend-service-pkg-bakup`
- `frontend-service/apps/web-antd`
- `frontend-service/apps/web-ele`
- `frontend-service/apps/web-naive`
- `frontend-service/apps/web-tdesign`
- `frontend-service/playground`
- 生成代码目录，包括 API、Ent gen、OpenAPI、Swagger UI bundle

## 验证命令

### 后端

```bash
cd backend-service
make check
make proto-lint
go test ./...
```

### 前端

```bash
cd frontend-service
pnpm -F @vben/web-antd-admin run typecheck
pnpm -F @vben/web-antd-admin run build
```

### 契约兼容检查

```bash
cd backend-service
make contract-check    # proto-lint + generate-check
```

### 纯文档变更

```bash
rg "Ark Tech Platform" README.md .agents docs/README.md docs/architecture docs/services docs/product docs/vibe-coding
git diff -- .agents README.md docs
```
