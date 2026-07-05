# 应用版本管理中心服务模块划分与工具分析

版本：v1.0  
日期：2026-06-03  
依据：`docs/product/00-AVMC-产品需求总览.md`、`docs/product/00-AVMC-迭代开发规划.md`、`docs/architecture/00-AVMC-后端底座架构决策.md`、`.codex` 项目规则、当前代码结构

## 1. 文档定位

本文档用于把应用版本管理中心（AVMC）服务的后续开发拆成稳定模块，并明确每个模块的当前代码基础、主要开发目标、推荐工具链和验证方式。

本文档不替代产品需求总览和迭代开发规划：

- 产品范围、字段和验收标准以 `00-AVMC-产品需求总览.md` 为准。
- 迭代顺序和开发流程以 `00-AVMC-迭代开发规划.md` 为准。
- 架构决策、服务边界和冻结清单以 `docs/architecture` 为准。
- 模块归类和入口状态以 `docs/product/modules/README.md` 为准。
- 代码实现规则以 `.codex/RULES.md` 和 `.codex/DESIGN.md` 为准。

## 2. 当前代码现状

### 2.1 后端现状

当前后端主工作区为 `backend-service`。

架构判断：

- 后端采用 go-kratos 大仓模式，`backend-service/app` 下保留多服务拆分能力。
- `backend-service/app/platform/admin` 当前升级为底座管理后台基础服务，不再继续承接 AVMC 新业务模块。
- 微服务拆分作为后续演进方向，而不是早期每新增一个模块就新建一个服务。

已具备基础：

- `backend-service/app/platform/admin` 已有认证、用户、角色、菜单、部门、岗位等基础管理能力，归入底座管理后台。
- `backend-service/proto/avmc/admin/v1` 已有 `i_auth.proto`、`i_user.proto`、`i_role.proto`、`i_menu.proto`、`i_dept.proto`、`i_post.proto`、`i_project.proto`。
- 项目管理后端 MVP 已在 `backend-service/app/platform/admin` 内实现，后续作为底座项目服务边界能力继续收敛。
- `backend-service/app/version/service` 已有 `ReleaseService` 雏形。
- `backend-service/proto/version/service/v1/release.proto` 已有基础 Release proto，但字段还不满足当前产品 Release 发布需求。
- `backend-service/app/version/service` 当前冻结，不能作为迭代 1/2 的新增业务落点。

明显缺口：

- 项目管理仍缺少更细粒度的项目角色/权限配置和操作日志。
- 缺少完整版本管理模块。
- Release 尚未绑定项目和版本，也缺少草稿、待发布、已发布、已撤回等产品状态。
- 缺少灰度策略、客户端版本检查、下载页、反馈、协议、推送和发布统计等模块。

### 2.2 前端现状

当前底座管理后台主应用为 `frontend-service/apps/web-antd-admin`。

已具备基础：

- 已有系统管理路由：角色、菜单、部门、用户。
- 已新增项目管理页面：列表、筛选、创建/编辑 drawer、状态切换。
- 已有 Vben CRUD 页面模式：`Page + useVbenVxeGrid + useVbenDrawer + useVbenForm`。
- 已有 API 目录、request client、i18n 目录。

明显缺口：

- 项目权限配置入口和细粒度成员角色仍待补充。
- 缺少版本管理、Release 管理、灰度发布、下载页、反馈、协议、推送、看板等业务页面。
- 缺少这些模块对应的 API wrapper 和 locale key。

## 3. 模块划分

### 3.1 基础平台模块

范围：

- 认证
- 用户
- 角色
- 菜单
- 部门
- 岗位
- 权限
- 项目权限
- 操作日志

当前基础：

- 后端已有 `User/Role/Menu/Dept/Post/Auth` 相关 usecase、repo、service。
- 后端已有项目管理 MVP 和项目成员关系基础。
- 前端已有系统管理页面。

后续重点：

- 补项目权限关系。
- 补操作日志基础能力。
- 梳理系统管理页面与后端 API 的字段一致性。

### 3.2 项目管理模块

范围：

- 项目资料
- 项目负责人
- 项目状态
- 项目成员权限
- 项目级数据边界

开发目标：

- 后端已新增项目管理 proto、Ent schema、repo、usecase、service。
- 前端已新增项目管理列表、筛选、创建/编辑 drawer、状态切换。
- 后续补项目权限配置入口和更细粒度的项目成员角色。
- 后续版本、Release、下载页、协议、反馈、推送都必须绑定 `project_id`。

建议优先级：最高。没有项目边界，后续版本发布链路无法稳定扩展。

### 3.3 版本管理模块

范围：

- 版本资料
- 更新包
- 整包/资源包
- 强制更新、静默更新、可选更新
- 文件大小、MD5、SHA256
- 版本回滚

开发目标：

- 新增版本管理 proto 和数据模型。
- 建立项目内版本号唯一约束。
- 建立更新包信息记录能力。
- 为 Release 发布提供可选择的版本来源。

### 3.4 Release 发布模块

范围：

- Release 草稿
- 待发布
- 已发布
- 已撤回
- 灰度发布
- 全量发布
- 发布统计

当前基础：

- `backend-service/app/version/service` 已有 `ReleaseService` 雏形。
- 当前 `release.proto` 只有基础字段，需要扩展为产品定义。

开发目标：

- Release 管理后台不再归属 `backend-service/app/platform/admin`，需等待 AVMC 业务服务边界确认。
- 将 Release 绑定项目和版本。
- 补齐发布状态和发布动作。
- 前端新增 Release 管理页面。
- 迭代 3 前再复审客户端版本检查 API 是否需要独立服务边界。

默认决策：

- 迭代 1 优先在 `backend-service/app/platform/admin` 内补齐底座管理后台基础能力；版本管理等待 AVMC 业务服务边界确认。
- `backend-service/app/version/service` 暂时保留，不做删除或重构。
- Release 管理后台契约和实现不再进入 `backend-service/app/platform/admin`。
- 迭代 3 开始客户端版本检查时，再判断公开检查 API 和 Release 主链路继续留在 `avmc/admin`，还是升级 `version/service` 为独立服务。

### 3.5 灰度发布模块

范围：

- 百分比灰度
- 用户 ID 白名单
- 设备标签
- 地区
- 活跃度
- 逐步扩量

开发目标：

- 建立灰度策略模型。
- 将灰度策略接入客户端版本检查 API。
- 前端可在 Release 内配置或独立管理灰度策略。

默认决策：

- MVP 先支持百分比和用户 ID 白名单。
- 设备、地区、活跃度作为 P1/P2 扩展。

### 3.6 客户端版本检查模块

范围：

- 客户端请求版本检查。
- 服务端根据项目、当前版本、平台、用户、设备和灰度策略返回更新结果。
- 返回更新类型、强制更新、下载地址、更新说明、协议提示。

开发目标：

- 后端新增客户端版本检查 API。
- API 不直接依赖后台 UI。
- 灰度策略和 Release 状态必须参与判断。

### 3.7 下载页模块

范围：

- 模板
- 草稿
- 预览
- 发布
- 应用信息
- 下载链接
- 推广内容

开发目标：

- 后端提供下载页配置 API 和公开数据 API。
- 前端提供下载页配置列表、内容编辑、预览、发布。
- 下载页管理后台保持工具型布局，不做营销式后台界面。

### 3.8 反馈与协议模块

范围：

- 用户反馈
- Bug/建议/评分
- 反馈附件
- 协议版本
- 多语言协议
- 协议生效状态

开发目标：

- 反馈支持列表、详情、状态处理和筛选。
- 协议支持版本历史、生效状态和客户端获取当前协议。
- 后续 AI 反馈归类可接入反馈模块。

### 3.9 推送通知模块

范围：

- 推送内容
- 目标范围
- 发送记录
- 成功率统计

开发目标：

- 支持创建推送任务。
- 支持按项目、分组、Release 或灰度用户选择范围。
- 先记录发送任务和状态，第三方推送服务集成可后置。

### 3.10 监控与 AI 扩展模块

范围：

- 多项目看板
- 发布指标
- 反馈趋势
- 操作审计
- AI 反馈分类
- Release notes 生成
- 发布风险提示

开发目标：

- 监控先做聚合看板和操作日志。
- AI 只作为辅助建议，不直接执行发布操作。

## 4. 工具分析

### 4.1 后端工具链

使用范围：

- `backend-service`
- `backend-service/app/platform/admin`
- `backend-service/app/ai/service`
- `backend-service/app/version/service` 仅用于迭代 3 服务边界复审，不作为当前新增业务开发范围。

核心工具：

- Go：后端语言。
- go-kratos v2：服务框架。
- Protobuf：API 契约源头。
- Buf：proto 生成。
- Ent：数据库模型和查询。
- Wire：依赖注入。
- OpenAPI annotations：接口文档输出。

推荐命令：

```bash
cd backend-service
make proto
go test ./...
```

服务级命令：

```bash
cd backend-service/app/platform/admin
make config
make doc
make ts
```

`backend-service/app/version/service` 当前冻结，除非执行迭代 3 服务边界复审，不运行该服务的生成或开发命令。

使用规则：

- 新增 API 先改 `backend-service/proto`。
- 生成代码只通过 Makefile 或 Buf 生成。
- 不手工修改 `backend-service/api`、`internal/conf`、`internal/data/ent/gen` 等生成结果。
- 新增实体时先建 Ent schema，再生成 Ent 代码。
- 底座基础模块默认进入 `backend-service/app/platform/admin`；AVMC 业务模块需要先确认服务边界，不再默认写入 admin。

### 4.1.1 后端阶段性架构决策

当前采用“大仓 + 模块化单服务优先”的开发策略。

含义：

- `backend-service` 保持 go-kratos 大仓结构。
- `backend-service/app` 保留未来微服务拆分空间。
- `backend-service/app/platform/admin` 是底座管理后台基础能力的主要后端落点。
- 新增业务先在 `admin` 服务内部按 proto、service、biz、data、ent schema 建立模块边界。
- 不在早期为了目录看起来更像微服务而拆分运行进程。

满足以下条件之一时，再考虑拆出独立服务：

- 需要独立部署、独立发布或独立回滚。
- 需要独立扩缩容。
- 与后台管理服务的流量、性能、存储压力明显不同。
- 对外提供独立公共 API，且不只服务于管理后台。
- 已形成清晰业务域，继续放在 `admin` 会造成强耦合。

当前服务边界建议：

| 服务 | 当前定位 | 当前策略 |
|---|---|---|
| `backend-service/app/platform/admin` | 底座管理后台基础服务 | 认证、用户、角色、菜单、权限、中台基础配置、项目服务配置入口 |
| `backend-service/app/version/service` | 已有 ReleaseService 雏形 | frozen，迭代 3 前只做边界复审 |
| `backend-service/app/ai/service` | 底座 AI/chat 能力 | 业务接入时定义边界 |
| 新 Kratos service | 后续微服务演进点 | 早期不主动新增 |

### 4.2 前端工具链

使用范围：

- `frontend-service/apps/web-antd-admin`

核心工具：

- Vue 3 + TypeScript。
- Vite。
- Vben Admin。
- Ant Design Vue。
- Pinia。
- Vue Router。
- `@vben/request`。
- pnpm workspace。

推荐命令：

```bash
cd frontend-service
pnpm install
pnpm -F @vben/web-antd-admin run dev
pnpm -F @vben/web-antd-admin run typecheck
pnpm -F @vben/web-antd-admin run build
```

页面开发规则：

- 路由放在 `src/router/routes/modules`。
- 页面放在 `src/views/<module>`。
- 表格和表单 schema 放在 `data.ts`。
- 抽屉或弹窗组件放在 `modules/`。
- API wrapper 放在 `src/api/<domain>`。
- 可见文案放在 `src/locales/langs/zh-CN` 和 `src/locales/langs/en-US`。

### 4.3 文档工具链

使用范围：

- `docs/product`
- `docs/vibe-coding`
- `.codex`

文档维护规则：

- 产品范围变化更新 `docs/product/00-AVMC-产品需求总览.md`。
- 迭代顺序和流程变化更新 `docs/product/00-AVMC-迭代开发规划.md`。
- 模块划分、工具链、执行策略变化更新本文档。
- 旧资料只放 `docs/archive`。

### 4.4 Git 与子仓库工具规则

`backend-service` 和 `frontend-service` 是独立子仓库。

提交规则：

- 后端代码变更在 `backend-service` 内提交。
- 前端后台代码变更在 `frontend-service` 内提交。
- 根仓库只提交文档、根级配置、子仓库指针。

状态检查：

```bash
git status
cd backend-service && git status
cd frontend-service && git status
```

推荐顺序：

1. 先提交子仓库代码。
2. 回根仓库确认子仓库指针变化。
3. 根仓库提交文档和子仓库指针。

## 5. 当前推荐开发顺序

### 5.1 第一阶段：项目管理

原因：

- 当前系统管理基础已存在。
- 产品后续所有业务模块都依赖 `project_id`。
- 项目权限会影响版本、Release、下载页、反馈、协议、推送。

建议任务：

- 项目 proto、Ent schema、repo/usecase/service 已完成。
- 前端项目管理页面和 locale key 已完成。
- 后续补项目权限配置入口、项目成员角色和操作日志。

### 5.2 第二阶段：版本管理

原因：

- Release 必须基于版本。
- 客户端版本检查必须返回版本信息和下载地址。

建议任务：

- 补版本 proto 和 Ent schema。
- 支持更新包信息。
- 前端补版本管理页面。

### 5.3 第三阶段：Release 与客户端版本检查

原因：

- 这是最小可用发布主链路。
- 后续灰度、推送和统计都依赖 Release。

建议任务：

- 扩展 `release.proto`。
- 支持发布状态。
- 新增版本检查 API。
- 前端补 Release 页面。

### 5.4 第四阶段：灰度发布

原因：

- 灰度发布是版本管理中心区别于普通下载系统的核心能力。

建议任务：

- MVP 先支持百分比和用户 ID 白名单。
- 后续扩展设备、地区、活跃度。

### 5.5 后续阶段

按以下顺序推进：

1. 下载页配置。
2. 反馈与协议。
3. 推送通知。
4. 监控与审计。
5. AI 扩展。

## 6. 每个模块的最小交付件

每个模块进入开发时，至少交付：

- 后端 proto 契约。
- Ent schema 或明确无需新增数据模型。
- repo/usecase/service 实现。
- 前端 route。
- 前端 list 页面。
- 前端 create/edit drawer 或 detail drawer。
- API wrapper。
- `zh-CN/en-US` locale key。
- 核心成功路径和关键失败路径验证。
- 子仓库提交和根仓库指针提交。

## 7. 当前默认决策

- 从“迭代 1：基础权限与项目管理”开始开发。
- 早期采用“大仓 + 模块化单服务优先”策略。
- `backend-service/app/platform/admin` 承载底座管理后台基础 API，不再继续承接 AVMC 业务模块。
- `backend-service/app/version/service` 保留为版本发布服务候选边界，当前冻结，迭代 3 前只做边界复审。
- `frontend-service/apps/web-antd-admin` 是当前底座管理后台默认开发目标。
- `docs/archive` 只作为历史资料，不作为默认实现依据。
