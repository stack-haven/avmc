# Mobile Desktop Service 多端应用服务

日期：2026-09-14
状态：planning → implementing skill 准备阶段

> **定位说明**：mobile-desktop-service 是 Ark Tech Platform 的**多端应用承载层**，不是具体业务产品。它负责承载各 Ark Product Service（GEO、Evie、App Version Management 等）的桌面端、移动端和小程序端产物。

## 定位

Ark Tech Platform 多端应用 monorepo：

- 桌面端（macOS / Windows / Linux，Flutter Desktop / Tauri / Electron）
- 移动端（iOS / Android，Flutter / React Native / uni-app）
- 小程序端（微信 / 支付宝 / 抖音 / 百度，uni-app）

**与 frontend-service 的边界：**

| 维度 | frontend-service | mobile-desktop-service |
|------|------------------|------------------------|
| 交付形态 | 浏览器 Web 应用 | 原生/跨端 App、小程序 |
| 技术栈 | Vue 3 + Vben Admin（单一） | Flutter / RN / uni-app（多栈共存） |
| 构建工具 | Vite + pnpm | 各自独立（Melos / npm / HBuilderX） |
| 发布渠道 | CDN / Nginx | App Store / Google Play / 小程序平台 |

## 服务边界

- **子仓库**：`mobile-desktop-service/`（独立 Git 子仓库，GitHub: `stack-haven/avmc-mobile-desktop-service`）
- **承载产品**：
  - Evie（Flutter 移动端 + Flutter 桌面端）
  - GEO Engine（uni-app 移动端 + uni-app 小程序端）
  - Workbench（RN 移动端 / Tauri 桌面端）
  - 未来其他 Ark Product Service
- **不负责**：Web 后台（→ `frontend-service`）、后端 API（→ `backend-service`）

## 依赖的 Ark Platform Foundation 能力

- 认证授权：复用 `backend-service/pkg/auth` 的 JWT 协议，通过 backend-service gRPC/HTTP 接口获取 token 和会话状态
- 多租户隔离：所有调用从 JWT claims 提取 `tenant_id`，不接受客户端传入
- 后端 API：通过 `backend-service/proto` 生成的客户端调用 `/evie/v1`、`/geo/v1`、`/platform/v1` 等 endpoint
- 菜单/权限：复用 platform 的 Casbin 策略，不在客户端内维护独立权限表

## 依赖的 Ark Business Platform 能力

- 当前未依赖业务中台。如未来客户端需要展示订阅/账单信息，按 `docs/services/{product}/` 接入规范调用 `/platform/v1` billing 接口。

## 技术栈矩阵

| 技术栈 | 适用端 | Monorepo 工具 | 客户端语言 |
|--------|--------|--------------|------------|
| Flutter | iOS / Android / macOS / Windows / Linux | Melos / very_good_cli | Dart |
| React Native | iOS / Android | npm workspaces | TypeScript |
| uni-app | iOS / Android / 微信小程序 / 抖音小程序 / 支付宝小程序 / 百度小程序 / H5 | HBuilderX / CLI | Vue 3 + TypeScript |

**Monorepo 策略**：各自独立，不强求统一。不引入 Turborepo/Nx 跨栈调度工具。

## 资料入口

- 技术规范：`docs/services/mobile-desktop/SERVICE.md`（目录结构、Monorepo 策略、API 集成、CI/CD）
- 项目级 Skill：
  - `avmc-mobile-desktop-monorepo` — 子仓库整体规范
  - `avmc-flutter-app` — Flutter 项目脚手架
  - `avmc-react-native-app` — React Native 项目脚手架
  - `avmc-uniapp-app` — uni-app 项目脚手架
- 平台分层：`docs/architecture/0-1-架构总览-平台分层设计.md`（六、端维度）

## 状态与变更追溯

- 当前代码落点：暂未初始化（待 skill 准备完成后开工）
- 平台侧关联：`docs/architecture/4-6-治理-开发功能清单.md` 四、工程治理 → 4.6 多端服务
- 子仓库指针：暂未登记（待 GitHub 仓库创建后更新 `.gitmodules`）

## 接入检查

新端应用进入 mobile-desktop-service 时，按以下清单执行：

| # | 项目 | 要求 |
|:---:|------|------|
| 1 | 命名规范 | 应用目录使用 `<product>-<platform>` 格式（kebab-case） |
| 2 | API 客户端 | 优先复用 `mobile-desktop-service/packages/api-client` 生成的客户端 |
| 3 | 认证复用 | 复用 platform JWT 协议，不自建登录 |
| 4 | 租户隔离 | `tenant_id` 从 JWT claims 提取，不接受客户端传入 |
| 5 | 共享代码 | 跨应用复用代码必须放 `packages/`，禁止 apps/ 之间直接拷贝 |
| 6 | 文档同步 | 在本 README 「承载产品」章节追加新应用，登记产品/端/技术栈 |
| 7 | 端应用 Skill | 选择对应的 `avmc-{tech}-app` skill 执行脚手架 |

## 与其他产品服务的关系

mobile-desktop-service **不直接实现任何业务逻辑**，它只是各产品的端应用承载层。具体业务的接口定义在 `backend-service/proto/{product}/` 下，前端 Web 实现在 `frontend-service/apps/web-antd-admin/src/views/{product}/` 下。

```
backend-service/proto/{product}/        ← API 契约
        ↓
backend-service/app/{product}/service/  ← 业务实现
        ↓
frontend-service/apps/web-antd-admin/   ← Web 后台  +  mobile-desktop-service/apps/  ← 多端应用
```
