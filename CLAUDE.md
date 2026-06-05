# AVMC 项目指南

## 项目概述

AVMC (App Version Management Center) 是一套为多项目应用提供版本控制、灰度发布、用户反馈、推送通知与用户管理的开源系统平台。

## 仓库结构

```
avmc/
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
| 后端 | Go + go-kratos v2（大仓 + 微服务模式） |
| API | Protobuf + gRPC + HTTP (Google HTTP annotations) + Buf |
| ORM | Ent |
| DI | Wire |
| 前端 | Vue 3 + TypeScript + Vben Admin + Ant Design Vue |
| 构建 | Vite + pnpm workspace |
| 状态管理 | Pinia |
| 数据库 | MySQL / PostgreSQL |
| 缓存 | Redis（可选） |
| 认证 | JWT + Casbin |

## 活跃开发区域

### 后端
- `backend-service/app/avmc/admin` — AVMC 管理后台和核心管理 API（迭代 1、2 的默认目标）
- `backend-service/app/avmc/ai` — AI/chat 相关服务
- `backend-service/app/version/service` — 版本发布服务

当前阶段采用"大仓 + 模块化单服务优先"策略，不要因为新增业务模块就默认创建新的 Kratos service。

### 前端
- `frontend-service/apps/admin-antd-avmc` — AVMC 业务管理后台（默认开发目标）
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

### 后端
```bash
cd backend-service
go test ./...
buf lint                          # 契约变更时
buf breaking --against '<基准>'    # breaking change 检查
```

### 前端
```bash
cd frontend-service
pnpm -F @vben/admin-antd-avmc run dev       # 启动开发服务器
pnpm -F @vben/admin-antd-avmc run typecheck # 类型检查
pnpm -F @vben/admin-antd-avmc run build     # 构建
```

## 迭代开发进度（当前）

当前处于 **迭代 1**（基础权限与项目管理）收尾阶段：
- ✅ 项目管理后端 MVP 完成（proto、Ent schema、repo、usecase、service）
- ✅ 项目管理前端基础页面完成（列表、筛选、创建/编辑 drawer）
- ⏳ 项目权限配置入口、项目级成员角色和操作日志仍待补充

下一步计划：**迭代 2**（版本管理 MVP）
