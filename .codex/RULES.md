# 项目开发底座结构与开发规则

本文件描述当前仓库的真实结构。如果这里的规则和较早的产品文档存在冲突，以这里和当前代码为准。

## 顶层定义

当前仓库是项目开发底座，不等同于单一业务系统。应用版本管理中心（AVMC）是当前底座上的一个项目服务，后续可以继续承载其他业务服务。

## 仓库结构

```text
avmc/
├── backend-service/          # Go + go-kratos 后端工作区
├── frontend-service/         # Vue Vben Admin pnpm monorepo
├── docs/architecture/        # 当前架构决策、服务边界和冻结清单
├── docs/services/            # 项目服务目录和服务资料入口
├── docs/product/             # 当前项目服务产品需求和迭代开发主文档
├── docs/vibe-coding/         # 代码规范与架构约定
├── docs/archive/             # 历史文档归档，不作为默认实现依据
├── backend-service-pkg-bakup/# 备份/参考包，不作为活跃开发目标
└── .codex/                   # 面向 Codex 的项目规则
```


## 子仓库提交规则

`backend-service` 和 `frontend-service` 是独立子仓库。后续产品迭代涉及后端或后台代码变更时，需要分别维护子仓库提交，再回到根仓库更新子仓库指针。

规则：

- 后端代码变更在 `backend-service` 内提交。
- 前端后台代码变更在 `frontend-service` 内提交。
- 根仓库只提交文档变更、子仓库指针更新和根级配置变更。
- 不要只在根仓库提交而忽略子仓库内部提交。
- 查看状态时需要分别执行：
  - 根仓库：`git status`
  - 后端子仓库：`cd backend-service && git status`
  - 前端子仓库：`cd frontend-service && git status`

推荐提交顺序：

1. 在 `backend-service` 或 `frontend-service` 内完成代码提交。
2. 回到根仓库确认对应子仓库指针变化。
3. 在根仓库提交子仓库指针更新和相关文档。

## 后端规则

### 活跃服务

后端开发优先使用以下服务根目录：

- `backend-service/app/platform/admin`：项目开发底座管理后台基础服务，负责认证、用户、角色、菜单、权限、中台基础配置和项目服务配置入口。
- `backend-service/app/ai/service`：项目开发底座 AI/chat 能力服务。
- `backend-service/app/version/service`：已存在的版本发布服务雏形，当前冻结，迭代 3 前不继续扩展。

当前阶段采用“大仓 + 模块化单服务优先”策略：

- `backend-service` 保持 go-kratos 大仓模式，`app` 下保留未来微服务拆分能力。
- `backend-service/app/platform/admin` 只承接底座管理后台基础能力，不再继续承接 AVMC 版本、Release、灰度、下载页、反馈、协议、推送等业务能力。
- AVMC 业务服务需要另行定义后端落点；在服务边界确认前，不把新业务继续写入 `app/platform/admin`。
- 不要因为新增业务模块就默认创建新的 Kratos service。
- 只有模块需要独立部署、独立扩缩容、独立公共 API，或已经形成清晰业务域时，才考虑拆出独立服务。
- `backend-service/app/version/service` 暂时保留，Release 和客户端版本检查的最终边界在迭代 3 前重新确认。

每个服务遵循 Kratos 目录结构：

```text
cmd/server/       # 可执行入口、Wire 启动、assets
configs/          # 服务配置
internal/conf/    # 生成的配置结构
internal/server/  # HTTP/gRPC server 注册
internal/service/ # RPC 方法实现
internal/biz/     # usecase 和 repository interface
internal/data/    # repository、Data 容器、Ent client
```

### API 契约流程

后端契约流转顺序是：

```text
backend-service/proto
  -> backend-service/api
  -> app/*/internal/service
  -> app/*/internal/biz
  -> app/*/internal/data
  -> app/*/internal/data/ent/schema
```

规则：

- `backend-service/proto` 下的 Protobuf 文件是 API 事实来源。
- `backend-service/api` 下的生成文件不要手工编辑。
- 对外暴露 HTTP endpoint 时，使用 Google HTTP annotations 和 OpenAPI operation annotations。
- 创建重复消息前，优先复用 `proto/common`、`proto/common/pagination`、`proto/common/enum`、`proto/core/service/v1` 下已有的公共消息。
- 如果相邻服务已经使用 AIP filtering、ordering、pagination 风格，列表接口应保持兼容。

### 持久化与业务分层

- 业务编排和校验放在 `internal/biz` usecase 中。
- repository interface 放在 `internal/biz`，具体实现放在 `internal/data`。
- 数据库结构使用 `internal/data/ent/schema` 下的 Ent schema 表达。
- ID、status、timestamps、soft delete 等通用字段优先复用现有 mixins，不要重复定义。
- 新增 usecase、repo 或 service 依赖时，同步更新 Wire provider set。

### 后端工具链

- 语言/框架：Go、go-kratos v2。
- API：Protobuf、gRPC、HTTP annotations、Buf。
- ORM：Ent。
- DI：Wire。
- 校验/OpenAPI：按已有配置从 proto 生成。
- 配置：服务 `configs/config.yaml` 和生成的 `internal/conf` 结构。

生成和检查命令从最近的后端根目录运行。存在 Makefile target 时优先使用 Makefile。

## 前端规则

### 活跃前端应用

`frontend-service/apps/web-antd-admin` 当前作为底座管理后台前端。它使用：

- Vue 3 + TypeScript
- Vite
- Vben Admin
- Ant Design Vue
- Pinia
- Vue Router
- `@vben/request`
- pnpm workspace

除非任务明确指定，以下 Vben 应用只作为示例或参考实现：

- `apps/web-antd`
- `apps/web-ele`
- `apps/web-naive`
- `apps/web-tdesign`
- `playground`

### 前端目录规则

`apps/web-antd-admin/src` 内部结构：

```text
adapter/       # Vben form/table/component adapters
api/           # typed API wrappers and request client
layouts/       # auth/basic layouts
locales/       # i18n messages
router/        # route modules, access guard, route generation
store/         # app-level stores
views/         # pages and page-local modules
```

规则：

- 底座管理后台页面放在 `src/views/<module>`。项目服务业务页面在服务边界确认后再确定是否进入该应用、独立应用或独立模块包。
- 路由模块放在 `src/router/routes/modules`。
- 页面局部 table/form schema 放在 `data.ts`。
- 抽屉/弹窗表单组件放在 `modules/`。
- API 封装放在 `src/api/<domain>`。
- 新增可见文案时，同时添加中文和英文 locale key。
- 应用内部使用 `#/` imports；共享 Vben 依赖使用 workspace package imports。

### 前端页面模式

管理类 CRUD 页面遵循现有模式：

```text
Page
  + useVbenVxeGrid 处理表格、筛选表单、工具栏、分页
  + useVbenDrawer 或 modal 处理创建/编辑/详情表单
  + useVbenForm 处理 schema-driven forms
  + ant-design-vue message/Modal 处理用户反馈
```

已有 adapter 能覆盖需求时，不要重新造自定义 table/form 基础组件。

### 前端工具链

- Node.js：`>=20.19.0`
- pnpm：`>=11.0.0`
- package manager：`pnpm@11.5.2`
- 当前底座管理后台前端应用包名：`@vben/web-antd-admin`

在 `frontend-service` 中常用命令：

```bash
pnpm install
pnpm -F @vben/web-antd-admin run dev
pnpm -F @vben/web-antd-admin run typecheck
pnpm -F @vben/web-antd-admin run build
```

## 命名与生成输出

- 前端 Vue 和 TypeScript 文件使用 kebab-case。
- 后端 Go 文件使用 snake_case。
- 不要手工修改生成的 Go、生成的 TypeScript、OpenAPI 输出、嵌入的 Swagger UI bundle 或 `node_modules`。
- 普通功能开发不要改示例、备份和 vendor-like assets。
