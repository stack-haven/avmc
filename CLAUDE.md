# 项目开发底座指南

## 项目概述

本项目是一个 SaaS 多租户项目开发底座，提供认证授权、项目边界、数据隔离、菜单权限、操作审计、数据字典、租户生命周期等基础治理能力。底座之上可承载多个可扩展的业务项目服务。

## 仓库结构

```
saas-base/
├── backend-service/          # Go + go-kratos 后端工作区 (子模块)
├── frontend-service/         # Vue Vben Admin pnpm monorepo (子模块)
├── docs/product/             # 当前产品需求和迭代开发主文档
├── docs/vibe-coding/         # 代码规范与架构约定
├── docs/archive/             # 历史文档归档，不作为默认实现依据
├── backend-service-pkg-bakup/# 备份/参考包，不作为活跃开发目标
```

## 子仓库提交规则

`backend-service` 和 `frontend-service` 是独立子仓库。

推荐提交顺序：
1. 在 `backend-service` 或 `frontend-service` 内完成代码提交
2. 回到根仓库确认对应子仓库指针变化
3. 在根仓库提交子仓库指针更新和相关文档

根仓库只提交文档变更、子仓库指针更新和根级配置变更。

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端 | Go 1.24.6 + go-kratos v2（大仓 + 微服务模式） |
| API | Protobuf + gRPC + HTTP (Google HTTP annotations) + Buf |
| ORM | Ent v0.14.5 |
| DI | Wire v0.7.0 |
| 前端 | Vue 3 + TypeScript + Vben Admin 5.7 + Ant Design Vue |
| 构建 | Vite + pnpm 11.5.2 workspace + Turbo |
| 状态管理 | Pinia |
| 数据库 | MySQL / PostgreSQL |
| 缓存 | Redis（可选） |
| 认证 | JWT + Casbin |
| Node.js | ^22.18.0 |

## 活跃开发区域

### 后端
- `backend-service/app/platform/admin` — 底座管理后台基础服务（认证、用户、角色、菜单、权限、租户管理、字典、审计、会话；默认开发目标）
- `backend-service/app/ai/service` — AI/chat 通用能力服务
- `backend-service/app/version/service` — 历史版本发布服务雏形（当前冻结，待复审）

当前阶段采用"大仓 + 模块化单服务优先"策略，不要因为新增业务模块就默认创建新的 Kratos service。

### 前端
- `frontend-service/apps/web-antd-admin` — 底座管理后台前端（当前默认开发目标）
- 其他 Vben 应用 (`web-antd`, `web-ele`, `web-naive`, `web-tdesign`, `playground`) 只作为示例或参考

## 后端开发规则

### API 契约流程

```
proto -> api(生成) -> internal/service -> internal/biz -> internal/data -> ent/schema
```

- `backend-service/proto` 下的 Protobuf 文件是 API 事实来源
- `backend-service/api` 下的生成文件不要手工编辑
- 对外暴露 HTTP endpoint 时使用 Google HTTP annotations
- 优先复用 `proto/common`、`proto/common/pagination`、`proto/common/enum`、`proto/core/service/v1` 下的公共消息

### Kratos 目录结构（每个服务）

```
cmd/server/       # 可执行入口、Wire 启动
configs/          # 服务配置
internal/conf/    # 生成的配置结构
internal/server/  # HTTP/gRPC server 注册
internal/service/ # RPC 方法实现
internal/biz/     # usecase 和 repository interface
internal/data/    # repository、Data 容器、Ent client
```

### 业务规则
- 业务编排和校验放在 `internal/biz` usecase 中
- repository interface 放在 `internal/biz`，具体实现放在 `internal/data`
- 数据库结构使用 `internal/data/ent/schema` 下的 Ent schema 表达
- ID、status、timestamps、soft delete 等通用字段优先复用现有 mixins
- 新增 usecase、repo 或 service 依赖时，同步更新 Wire provider set

### 必守约束
- 权限控制必须在后端执行，不能只依赖前端隐藏
- 项目级资源数据访问都必须验证项目访问边界
- 认证失败、无权限和资源不存在应返回可区分的错误
- 生成代码（`backend-service/api`、`internal/data/ent/gen`、Swagger UI bundle）不手工修改

## 前端开发规则

### 页面结构

```
views/<module>/
├── list.vue      # 页面壳、表格、工具栏、行操作
├── data.ts       # table columns、filter schema、form schema
├── modules/      # drawer/modal/detail components
├── api/          # request wrappers
└── locales/      # zh-CN 和 en-US labels
```

### CRUD 页面模式

```text
Page
  + useVbenVxeGrid  处理表格、筛选表单、工具栏、分页
  + useVbenDrawer   处理创建/编辑/详情表单
  + useVbenForm     处理 schema-driven forms
  + ant-design-vue  message/Modal 处理用户反馈
```

### 前端约束
- 应用内部使用 `#/` imports；共享 Vben 依赖使用 workspace package imports
- 新增可见文案时，同时添加中文和英文 locale key
- 路由模块放在 `src/router/routes/modules`
- 菜单标题使用 i18n key，不硬编码可见字符串
- 破坏性操作必须确认（删除、发布、撤回、回滚等）

## 文档规则
- 使用 `docs/product`，不使用 `doc/product`
- 使用 `docs/vibe-coding`，不使用 `doc/vibe-coding`
- 旧产品文档和当前代码冲突时，以当前代码和当前 `docs/product` 为准
- 文档说明优先使用中文；技术标识、路径、命令、API 名称保持英文原样

## 默认避免修改的区域
- `backend-service-pkg-bakup`
- `frontend-service` 下的 `apps/web-antd`、`web-ele`、`web-naive`、`web-tdesign`、`playground`
- 生成代码目录（api、ent/gen 等）

## 验证命令

### 后端（根目录 `backend-service/`）

```bash
# 根 Makefile 目标
make check              # fmt-check + go vet + go test + git diff-check（质量门禁）
make fmt-check          # gofmt 格式检查
make build              # 编译所有包到 bin/
make generate           # go generate ./... + go mod tidy
make proto              # buf 生成 protobuf Go 代码
make proto-lint         # buf lint 检查
make contract-check     # proto-lint + generate-check（CI 契约检查）
make admin-migrate      # 运行 admin 数据库迁移
make ai-migrate         # 运行 ai 数据库迁移
make admin-policy       # 注入 admin Casbin 策略

# 通用 Go 命令
go test ./...           # 运行所有测试
go vet ./...            # 静态分析
go mod tidy             # 整理依赖
buf lint                # protobuf lint（契约变更时）
buf breaking --against '<基准>'  # breaking change 检查
```

### 前端
```bash
cd frontend-service
pnpm -F @vben/web-antd-admin run dev       # 启动开发服务器
pnpm -F @vben/web-antd-admin run typecheck # 类型检查
pnpm -F @vben/web-antd-admin run build     # 构建
```

## 底座治理能力开发进度（当前）

底座多租户能力已基本完成：

### ✅ 已完成的底座能力
| 能力 | 状态 |
|------|------|
| 租户生命周期（5 状态状态机） | ✅ 已完成 |
| 租户业务套餐（菜单权限组） | ✅ 已完成 |
| 租户原子开通事务 | ✅ 已完成 |
| 数据字典（租户隔离） | ✅ 已完成 |
| 操作审计日志（Middleware 自动捕获） | ✅ 已完成 |
| 登录安全日志（LoginLog） | ✅ 已完成 |
| Token 会话化（多设备支持） | ✅ 已完成 |
| 会话管理（列表/强制下线） | ✅ 已完成 |
| 用户/角色/菜单/部门/岗位管理 | ✅ 已完成 |
| 项目管理 | ✅ MVP 已完成 |
| 认证安全（JWT + 失败锁定） | ✅ 已完成 |

### ⏳ 待补充的底座能力
| 能力 | 状态 |
|------|------|
| 参数配置中心 | P1 计划 |
| 数据权限 | P1 计划 |
| 文件与对象存储 | P1 计划 |
| 通知中心 | P1 计划 |

### 📋 下一步
底座基础治理能力完成后，可启动业务项目服务的定义和开发。
