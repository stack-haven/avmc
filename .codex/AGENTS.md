# AVMC Codex 代理指南

本文件是 Codex 代理进入 AVMC 项目后的第一份项目指南。修改代码或文档前应先阅读本文件。

## 项目定位

AVMC 是 App Version Management Center（应用版本管理中心）。它是一个面向多项目的管理平台，用于移动应用版本发布、Release 发布、灰度发布、下载页配置、用户反馈、协议文档、用户、角色、权限、推送通知，以及后续 AI 辅助运营能力。

当前仓库是一个前后端一体工作区：

- `backend-service`：Go、go-kratos v2、gRPC + HTTP、Protobuf、Buf、Ent、Wire。
- `frontend-service`：Vue 3、TypeScript、Vben Admin monorepo、pnpm、Vite。
- `docs/product`：当前产品需求和迭代开发主文档。
- `docs/archive`：历史产品、规划和 UI 资料归档。
- `docs/vibe-coding`：项目代码规范与结构约定。
- `.codex`：面向 Codex 代理的项目规则。

## 阅读顺序

处理实现类任务时，按以下顺序阅读：

1. `.codex/AGENTS.md`
2. `.codex/RULES.md`
3. `.codex/DESIGN.md`
4. 同一后端服务或前端应用中最接近的现有代码。
5. `docs/product/README.md`
6. `docs/product/00-AVMC-产品需求总览.md`
7. `docs/product/00-AVMC-迭代开发规划.md`
8. `docs/vibe-coding/*/README.md`
9. `docs/archive/*` 仅用于追溯历史需求来源。

`docs/archive` 里的历史产品文档可能包含较早期的通用架构描述。当前代码、`.codex` 和 `docs/product` 当前主文档才是框架、目录和 API 实现规则的事实来源。

## 默认工作目标

后端业务开发通常优先落在以下服务中：

- `backend-service/app/avmc/admin`
- `backend-service/app/avmc/ai`
- `backend-service/app/version/service`

前端 AVMC 业务开发通常优先落在：

- `frontend-service/apps/admin-antd-avmc`

`frontend-service/packages` 下的共享前端包只用于跨应用的 Vben 公共能力。不要把一次性的 AVMC 页面逻辑放进去。

## 默认避免修改的区域

除非任务明确要求，否则不要修改以下区域：

- `backend-service-pkg-bakup`：备份/参考代码。
- `frontend-service/apps/web-antd`
- `frontend-service/apps/web-ele`
- `frontend-service/apps/web-naive`
- `frontend-service/apps/web-tdesign`
- `frontend-service/playground`
- `backend-service/api` 下的后端生成代码
- `internal/data/ent/gen` 下的 Ent 生成代码
- Swagger UI bundle 和嵌入式生成资源。

如果生成文件已经过期，先修改源文件并运行正确的生成命令，不要手工编辑生成结果。

## 后端事实来源

后端 API 契约从 `backend-service/proto` 开始。生成的 Go API 代码位于 `backend-service/api`。服务实现按以下分层推进：

`service -> biz/usecase -> data/repo -> ent schema`

新增或修改业务行为时，按以下流程处理：

1. 在 `backend-service/proto/...` 定义或更新 Protobuf 契约。
2. 使用对应服务的 Makefile 或 Buf 命令重新生成 API/OpenAPI 输出。
3. 在 `internal/service` 实现传输层处理逻辑。
4. 在 `internal/biz` 实现业务编排。
5. 在 `internal/data` 实现持久化逻辑。
6. 数据库结构变化时，更新 Ent schemas/mixins。
7. 依赖变化时，更新 Wire provider。

## 前端事实来源

`frontend-service/apps/admin-antd-avmc` 是 AVMC 管理后台。使用该应用已有的 Vben 模式：

- 路由放在 `src/router/routes/modules`
- 页面放在 `src/views`
- 页面数据 schema 放在 `data.ts`
- 抽屉/弹窗表单放在 `modules/form.vue`
- API 封装放在 `src/api`
- 请求客户端来自 `#/api/request`
- i18n key 放在 `src/locales/langs`

标准 CRUD 页面模式是：

`Page + useVbenVxeGrid + useVbenDrawer + useVbenForm`

## 文档规则

更新文档时：

- 使用 `docs/product`，不要使用 `doc/product`。
- 使用 `docs/vibe-coding`，不要使用 `doc/vibe-coding`。
- 如果旧产品文档和当前代码冲突，把旧产品文档视为规划资料。
- 文档说明优先使用中文，方便当前团队阅读；技术标识、路径、命令和 API 名称保持英文原样。
- 优先写简洁、可执行的操作规则，少写泛泛而谈的建议。

## 验证

纯文档改动至少运行：

```bash
rg "doc/vibe-coding|doc/product|Spring Boot|Django|React/Vue" README.md docs/vibe-coding .codex
rg "admin-antd-avmc|backend-service/app/avmc/admin|service -> biz -> data" .codex docs/vibe-coding README.md
git diff -- .codex README.md docs/vibe-coding
```

代码改动使用最近的服务或应用检查。优先使用：

- 后端：在 `backend-service` 或具体服务目录运行 `go test ./...`。
- 前端：在 `frontend-service` 运行 `pnpm -F @vben/admin-antd-avmc run typecheck`，以及相关 lint/build 命令。
