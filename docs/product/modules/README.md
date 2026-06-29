# 应用版本管理中心服务模块归类

本文件用于给应用版本管理中心（AVMC）服务后续开发提供模块入口，避免把产品需求、架构决策和代码落点混在一起。项目服务定义以 `docs/services/app-version-management/README.md` 为准；架构边界以 `docs/architecture` 为准；字段和验收标准以 `docs/product/00-AVMC-产品需求总览.md` 为准。

## 模块状态说明

- `active`：已有实现基础，可以继续补齐。
- `planned`：已进入路线图，尚未完整实现。
- `deferred`：后续扩展，不作为近期默认任务。
- `frozen`：保留现状，暂不继续开发。

## 模块总览

| 模块组 | 模块 | 状态 | 默认后端落点 | 默认前端落点 | 下一步入口 |
| --- | --- | --- | --- | --- | --- |
| 底座与权限 | 认证、用户、角色、菜单、部门、岗位 | active | `backend-service/app/platform/admin` | `frontend-service/apps/web-antd-admin` | 作为底座管理后台基础能力继续收敛 |
| 底座配置 | 中台权限菜单分配、业务中台基础配置、项目服务配置入口 | planned | `backend-service/app/platform/admin` | `frontend-service/apps/web-antd-admin` | 补菜单权限分配、基础配置、操作日志 |
| 项目管理能力 | 项目管理、项目成员、项目权限 | active | `backend-service/app/platform/admin` | `frontend-service/apps/web-antd-admin` | 作为底座项目服务边界能力继续收敛 |
| 版本主链路 | 版本管理 MVP | planned | 待定义 AVMC 业务服务 | 待定义 | 不再进入 `app/platform/admin` |
| 发布主链路 | Release 管理后台 | planned | 待定义 AVMC 业务服务 | 待定义 | 不再进入 `app/platform/admin` |
| 发布主链路 | 客户端版本检查 API | planned | 迭代 3 复审 | 按需 | 决定是否升级 `version/service` |
| 发布策略 | 灰度发布 | planned | 待定义 AVMC 业务服务 | 待定义 | MVP 先支持百分比和用户 ID 白名单 |
| 分发配置 | 下载页配置 | planned | 待定义 AVMC 业务服务 | 待定义 | 建立草稿、预览、发布模型 |
| 运营闭环 | 用户反馈 | planned | 待定义 AVMC 业务服务 | 待定义 | 支持反馈列表、详情、处理状态 |
| 合规内容 | 协议管理 | planned | 待定义 AVMC 业务服务 | 待定义 | 支持多语言、历史版本、生效状态 |
| 触达能力 | 推送通知 | deferred | 待定义 AVMC 业务服务 | 待定义 | 先记录任务和状态，第三方集成后置 |
| 智能辅助 | AI 运营能力 | deferred | `backend-service/app/ai/service` + 待定义 AVMC 业务接入 | 待定义 | AI 只生成建议，不直接执行发布 |
| 已存在雏形 | `version/service` Release 雏形 | frozen | `backend-service/app/version/service` | 无默认页面 | 迭代 3 复审，不在迭代 1/2 扩展 |

## 近期执行顺序

1. 补齐底座管理后台基础能力：菜单权限分配、中台基础配置、项目服务配置入口、操作日志。
2. 确认 AVMC 业务服务后端和前端落点。
3. 在新的 AVMC 业务服务边界内实现版本管理 MVP。
4. 在新的 AVMC 业务服务边界内实现 Release 管理后台。
5. 迭代 3 前复审客户端版本检查 API 的服务边界。

## 新模块落点规则

- 底座基础能力默认落在 `backend-service/app/platform/admin` 和 `frontend-service/apps/web-antd-admin`。
- AVMC 业务能力不再默认落入 `backend-service/app/platform/admin`。
- 只有 `docs/architecture/00-AVMC-后端底座架构决策.md` 中的拆分条件满足时，才提出新服务。
- 后端新增 API 必须从 `backend-service/proto` 开始。
- 前端新增管理页必须走 `router -> views -> data.ts -> modules -> api -> locales`。
- 不使用 `backend-service-pkg-bakup`、Vben 示例应用或 `docs/archive` 作为默认实现目标。
