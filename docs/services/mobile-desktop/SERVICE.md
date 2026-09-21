# Mobile Desktop Service 技术规范

日期：2026-09-14
状态：planning
适用范围：`mobile-desktop-service/` 子仓库全部应用

---

## 一、子仓库定位

`mobile-desktop-service` 是 Ark Tech Platform 的**多端应用承载层**，对应 GitHub 仓库 `stack-haven/avmc-mobile-desktop-service`。

| 维度 | 说明 |
|------|------|
| 子仓库路径 | `mobile-desktop-service/`（根仓库下的一级目录） |
| Git 仓库 | `github.com/stack-haven/avmc-mobile-desktop-service` |
| 子仓库关系 | 与 `backend-service`、`frontend-service` 平级 |
| 提交策略 | 子仓库内独立提交，根仓库更新指针 |

---

## 二、顶层目录结构

```
mobile-desktop-service/
├── apps/                  # 可独立发布的应用
├── packages/              # 跨应用共享代码
├── tooling/               # 构建脚本、CI/CD、代码生成
├── docs/                  # 子仓库内部文档
└── README.md              # 子仓库入口
```

### apps/ 应用目录

每个应用目录对应一个可独立发布的端应用产物：

```
apps/
├── evie-mobile/           # Flutter，iOS + Android
├── evie-desktop/          # Flutter，macOS + Windows + Linux
├── geo-mobile/            # uni-app，iOS + Android
├── geo-mini/              # uni-app，微信/支付宝/抖音/百度小程序
└── workbench-mobile/      # React Native，iOS + Android
```

**命名约定：**

| 端类型 | 后缀 | 示例 |
|--------|------|------|
| 移动 App | `-mobile` | `evie-mobile` |
| 桌面端 | `-desktop` | `evie-desktop` |
| 小程序 | `-mini` | `geo-mini` |
| 智能硬件 | `-device` | `watch-device`（预留） |

### packages/ 共享代码

```
packages/
├── api-client/            # 与 backend-service proto 对接的客户端（Dart / TS）
├── ui-kit-flutter/        # Flutter UI 组件库（预留）
├── ui-kit-react/          # React Native UI 组件库（预留）
├── evie-core/             # Evie 业务核心逻辑（Dart 跨移动/桌面共享）
└── geo-core/              # GEO 业务核心逻辑（TS 跨 RN/uni-app 共享）
```

**按技术栈分组：**

- Dart 共享代码：`packages/*/lib/`
- TypeScript 共享代码：`packages/*/src/`
- Vue 共享代码：uni-app 业务通常不抽 packages，跨端共享放 HBuilderX 项目内

### tooling/ 工具脚本

```
tooling/
├── ci/                    # CI/CD 配置
├── scripts/               # 内部工具脚本
└── codegen/               # 代码生成器
    └── buf-gen-dart.yaml  # proto → Dart 客户端生成
```

---

## 三、Monorepo 工具策略

**核心原则：各自独立，不强求统一。**

| 技术栈 | 推荐 Monorepo 工具 | 包管理 | 适用产品 |
|--------|-------------------|--------|----------|
| Flutter | Melos / very_good_cli | pub | Evie（移动 + 桌面同源码） |
| React Native | npm workspaces / yarn workspaces | npm / yarn | Workbench |
| uni-app | HBuilderX 项目 + CLI | npm | GEO（App + 小程序） |

**不引入** Turborepo / Nx 等统一调度工具，避免增加跨栈学习成本和工具链维护负担。

**Flutter 同源码双产物：**

```
apps/evie-mobile/       ← entry: lib/main_mobile.dart
apps/evie-desktop/      ← entry: lib/main_desktop.dart
        ↓
packages/evie-core/     ← 共享业务逻辑
```

两个 apps 共享 `packages/evie-core/` 的 Dart 代码，分别打包成移动端和桌面端产物。

**uni-app 同源码多产物：**

```
apps/geo-mobile/        ← manifest: app-plus + h5
apps/geo-mini/          ← manifest: mp-weixin + mp-toutiao + ...
        ↓
共享 src/pages + src/components（条件编译）
```

uni-app 通过 `manifest.json` 配置和条件编译（`#ifdef MP-WEIXIN` 等）区分平台。

---

## 四、与后端 API 的集成

### API 契约流程

```
backend-service/proto/                           ← 契约来源
        ↓ buf generate
backend-service/api/                             ← 生成的 Go 代码
        ↓ (跨仓库)
mobile-desktop-service/packages/api-client/      ← 生成的 Dart / TS 客户端
        ↓
mobile-desktop-service/apps/{product}-{platform}  ← 业务应用
```

### 客户端类型选择

| 后端暴露方式 | 推荐客户端 | 适用技术栈 |
|--------------|------------|------------|
| gRPC | grpc-dart | Flutter |
| gRPC-Web | grpc-web + TS | React Native（实验） |
| REST/HTTP | dio / axios | Flutter / React Native / uni-app |
| Connect | connectrpc | 未来支持 |

**契约优先原则：**

- 所有 API 调用必须基于 `backend-service/proto` 定义的契约
- 不允许在 mobile-desktop-service 内自定义"对后端的理解"
- proto → Dart 客户端生成配置：`tooling/codegen/buf-gen-dart.yaml`
- proto → TS 客户端生成配置：`tooling/codegen/buf-gen-ts.yaml`

### 认证流程

```
1. 客户端调用 uni.login / 原生 SDK 获取第三方 code
2. 调用 backend-service POST /platform/v1/auth/login-by-code
3. 后端验证 code，返回 JWT access_token + refresh_token
4. 客户端存储 token（Keychain / Keyring / uni.setStorageSync）
5. 后续请求通过 Authorization: Bearer {token} 头部携带
6. token 过期时调用 POST /platform/v1/auth/refresh 刷新
```

---

## 五、多租户与权限

- **租户隔离**：`tenant_id` 从 JWT claims 提取，不接受客户端传入
- **用户上下文**：`user_id` 从 JWT claims 提取
- **平台管理员**：通过 `is_platform=true` claim 标识，客户端 UI 可选择性展示平台功能入口
- **权限控制**：所有受控操作在后端做 Casbin 校验，客户端 UI 隐藏 ≠ 权限通过

---

## 六、测试策略

| 测试类型 | 工具 | 覆盖范围 |
|----------|------|----------|
| 单元测试 | Flutter: `flutter test` / RN: `jest` / uni-app: `@dcloudio/uni-automator` | 业务逻辑、工具函数 |
| Widget/组件测试 | Flutter: `flutter test` / RN: `@testing-library/react-native` / uni-app: Vue Test Utils | UI 组件 |
| 集成测试 | Flutter: `integration_test` / RN: `detox` / uni-app: 手动 + E2E | 跨模块流程 |
| 端到端测试 | 各平台模拟器/真机 | 关键路径 |

CI 必跑：

```bash
# Flutter
flutter analyze && flutter test

# React Native
tsc --noEmit && eslint . && jest

# uni-app
vue-tsc --noEmit && eslint . && jest
```

---

## 七、CI/CD 概览

子仓库根目录推荐配置 `.github/workflows/mobile-desktop-ci.yml`：

| Job | 触发条件 | 执行内容 |
|-----|----------|----------|
| `lint-flutter` | evie-* 变更 | `flutter analyze` |
| `lint-rn` | workbench-* 变更 | `tsc --noEmit` + `eslint` |
| `lint-uniapp` | geo-* 变更 | `vue-tsc --noEmit` + `eslint` |
| `test-flutter` | evie-* 变更 | `flutter test` |
| `test-rn` | workbench-* 变更 | `jest` |
| `test-uniapp` | geo-* 变更 | `jest` |
| `build-flutter-mobile` | 手动 / tag | `flutter build apk --release` |
| `build-flutter-desktop` | 手动 / tag | `flutter build macos/windows/linux` |
| `build-rn` | 手动 / tag | `gradle assembleRelease` + `xcodebuild` |
| `build-uniapp-mp` | 手动 / tag | `uni build -p mp-weixin` 等 |

---

## 八、发布流程

| 端 | 渠道 | 工具 |
|----|------|------|
| iOS App | App Store | Xcode + Transporter / Fastlane |
| Android App | Google Play / 国内市场 | Fastlane / 手传 |
| macOS App | App Store / dmg | Xcode |
| Windows | 官网 / Microsoft Store | MSIX / exe |
| 微信小程序 | 微信开放平台 | 微信开发者工具 |
| 抖音小程序 | 抖音开放平台 | 抖音开发者工具 |
| 支付宝小程序 | 支付宝开放平台 | 小程序开发者工具 |
| 百度小程序 | 百度开放平台 | 百度开发者工具 |

---

## 九、安全约束

| # | 规则 |
|:---:|------|
| 1 | token 存储使用平台安全机制（Keychain / Keyring / secure storage），**不存明文** |
| 2 | iOS/Android 必须做代码混淆 + 资源加密 |
| 3 | 小程序主包 ≤ 2MB，超出必须分包 |
| 4 | 客户端不存敏感配置（API key、secret），走 backend 代理 |
| 5 | 所有后端调用必须经过 HTTPS |
| 6 | 客户端不做最终权限校验，仅做 UI 隐藏 |

---

## 十、与 frontend-service 的边界

| 维度 | frontend-service | mobile-desktop-service |
|------|------------------|------------------------|
| 适用场景 | PC 浏览器 Web 后台 | 原生 App、桌面应用、跨端小程序 |
| 技术栈 | Vue 3 + Vben Admin（单一） | Flutter / RN / uni-app（多栈） |
| 菜单/路由 | Vue Router + 平台菜单系统 | 各端原生路由 |
| 状态管理 | Pinia | Riverpod / Zustand / Pinia |
| HTTP 客户端 | `@vben/request` | dio / axios / uni.request |
| 设计系统 | Vben Admin 默认 + Ant Design Vue | 各端独立设计系统（未来可收敛） |

**禁止边界：**

- ❌ Web 后台功能不进入 mobile-desktop-service（如管理后台 CRUD）
- ❌ 移动端功能不进入 frontend-service
- ⚠️ 跨两端共享的业务模型放 `packages/`，不放任一 apps/

---

## 十一、Roadmap

| 阶段 | 状态 | 内容 |
|------|:---:|------|
| 立项 | [x] | 命名、子仓库关系、技术栈矩阵、Monorepo 策略确定 |
| Skill 准备 | [~] | 编写 4 个 skill（avmc-mobile-desktop-monorepo + 3 个技术栈） |
| 子仓库初始化 | [ ] | GitHub 仓库创建 + 子仓库脚手架 + 首个应用（Evie Mobile）落地 |
| CI/CD | [ ] | 子仓库 GitHub Actions 配置 |
| 首批应用 | [ ] | Evie Mobile + Evie Desktop + GEO 小程序 |
| 设计系统 | [ ] | 跨端设计令牌（design tokens）落地 |

---

## 十二、相关文档

- 服务入口：`docs/services/mobile-desktop/README.md`
- 平台分层：`docs/architecture/0-1-架构总览-平台分层设计.md`
- 端应用 Skill：`avmc-flutter-app`、`avmc-react-native-app`、`avmc-uniapp-app`
- Monorepo Skill：`avmc-mobile-desktop-monorepo`
- API 契约流程：`docs/architecture/3-0-跨领域-API边界与通信契约.md`
