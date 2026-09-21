---
description: |
  为 Ark Tech Platform 跨端应用 monorepo 提供多技术栈协调规范。当需要在 mobile-desktop-service 子仓库内新增/协调跨端应用（Flutter + React Native + uni-app），管理共享代码、设计令牌、API 客户端生成和 CI/CD 时触发。

  触发场景：
  - "初始化 mobile-desktop-service 子仓库骨架" / "新建多端 monorepo"
  - "Flutter + RN + uni-app 三个项目如何协调" / "跨端共享 API 客户端怎么生成"
  - "proto 一次生成多端客户端（Dart + TS）"
  - "跨端设计令牌同步（design tokens）"
  - "跨端 CI/CD 编排" / "按文件变更触发对应端 CI"

  需要用户提供的输入：当前要承载的产品、目标端列表、各端技术栈选型。

name: avmc-mobile-desktop-monorepo
---

# Ark Tech Platform 多端 Monorepo 规范

为 `mobile-desktop-service` 子仓库提供多技术栈协调规范。**支持 Flutter / React Native / uni-app 三栈共存**，通过 proto + packages 实现跨端共享。

---

## 〇、基础原则（不可妥协）

### 多技术栈 monorepo 的工程原则

| 原则 | 含义 | 在 mobile-desktop-service 的落地 |
|------|------|--------------------------------|
| **各栈独立 monorepo 工具** | 不强求统一为 Turborepo/Nx；每个技术栈用自己最成熟的工具 | Flutter: Melos / very_good_cli；RN: pnpm workspaces；uni-app: HBuilderX + npm CLI |
| **共享通过 proto + packages** | 跨端共享的唯一方式是 `backend-service/proto` 生成的 API 客户端 | 不在多个 apps/ 间拷贝代码；Dart / TS 客户端从同一 proto 源生成 |
| **同源码多产物** | 同一产品在不同端的产物必须从同一源码生成 | Flutter 同源码打移动+桌面；uni-app 同源码打 App+小程序 |
| **依赖方向单向** | `apps/` 依赖 `packages/`，`packages/` 不依赖 `apps/` | packages/ 下的 ui-kit、core、api-client 是跨应用共享 |
| **CI 矩阵化** | 不同端有独立 CI job；按文件变更触发 | Flutter CI 只跑 `apps/evie-*/**` 变更 |
| **版本管理清晰** | 跨包依赖必须显式版本号；内部包用 workspace 协议 | `pubspec.yaml` / `package.json` 中 `evie_core: ^1.2.0` |
| **契约优先** | 任何跨端共享逻辑都必须有契约定义（proto / OpenAPI / token schema） | 不存在"端到端私下约定" |

### 与 frontend-service 的边界

| 维度 | frontend-service | mobile-desktop-service |
|------|------------------|------------------------|
| 端形态 | PC 浏览器 Web 应用 | 原生 App + 小程序 + 桌面应用 |
| 技术栈 | Vue 3 + Vben Admin（单一） | Flutter / RN / uni-app（多栈） |
| 构建工具 | Vite + pnpm workspace + Turbo | Melos / pnpm workspaces / HBuilderX（各自独立） |
| 共享策略 | packages/* 通过 workspace: protocol | apps/* 通过 workspace + proto 生成 |
| 入口 | `apps/web-antd-admin` | `apps/{product}-{platform}/` |

**禁止边界：**

- ❌ Web 后台功能不进 mobile-desktop-service（即使技术上能用 HBuilderX 打包 H5）
- ❌ 跨端共享逻辑不直接放在 apps/ 下某个项目里，必须抽到 packages/
- ❌ mobile-desktop-service 不实现任何业务逻辑（业务在 backend-service）

### 与 backend-service 的契约关系

```
backend-service/proto/                            ← 单一契约源（SSOT）
        ↓ buf generate
mobile-desktop-service/packages/api-client/        ← 跨端共享客户端
        ├── lib/  (Dart) → apps/evie-mobile/、apps/evie-desktop/
        └── src/  (TypeScript) → apps/workbench-mobile/、apps/geo-*/
```

**契约变更触发链路：**

1. 修改 `backend-service/proto/{product}/{service}/v1/*.proto`
2. CI 自动跑 `buf lint` + `buf breaking`
3. 通过后，mobile-desktop-service CI 自动跑 `./tool/gen_clients.sh`
4. 生成 Dart / TS 客户端到 `packages/api-client/`
5. 跨端 apps/ 升级 api-client 版本号
6. 触发各端 CI 回归

---

## 一、子仓库初始化

### 1.1 首次创建（GitHub 仓库已存在时）

```bash
# 1. 克隆子仓库
git clone git@github.com:stack-haven/avmc-mobile-desktop-service.git
cd avmc-mobile-desktop-service

# 2. 跑初始化脚本（生成 apps/、packages/、tooling/ 骨架）
bash tool/init_monorepo.sh

# 3. 创建首个 Flutter 应用
cd apps
very_good create flutter_app evie_mobile \
  --description "Evie Mobile - Ark Tech Platform" \
  --org com.stackhaven.avmc

# 4. 创建首个 React Native 应用（用 pnpm workspace 模式）
mkdir -p workbench-mobile
cd workbench-mobile
pnpm init
# 按 avmc-react-native-app skill 指引完善

# 5. 创建首个 uni-app 应用
mkdir -p geo-mobile
# 用 HBuilderX 导入空项目
```

### 1.2 init_monorepo.sh 行为（[内置脚本]）

```bash
./tool/init_monorepo.sh
```

**脚本自动生成：**

```
mobile-desktop-service/
├── apps/                              # ✅ 已创建（空）
│   ├── .gitkeep
│   └── README.md                       # apps/ 子目录说明
├── packages/                          # ✅ 已创建（空）
│   ├── api-client/                    # ✅ API 客户端占位
│   │   ├── lib/
│   │   │   └── .gitkeep
│   │   ├── src/
│   │   │   └── .gitkeep
│   │   ├── pubspec.yaml                # ✅ Dart 包元数据
│   │   ├── package.json                # ✅ TS 包元数据
│   │   └── README.md
│   ├── design-tokens/                  # ✅ 跨端设计令牌
│   │   ├── tokens.json                 # 令牌源（SSOT）
│   │   ├── lib/theme.dart              # 生成的 Dart 代码
│   │   ├── src/theme.ts                # 生成的 TS 代码
│   │   ├── src/theme.scss              # 生成的 SCSS 变量
│   │   └── README.md
│   └── README.md
├── tooling/                           # ✅ 已创建
│   ├── codegen/
│   │   ├── buf.gen.yaml                # 跨端客户端生成配置
│   │   └── README.md
│   ├── ci/
│   │   └── README.md
│   └── scripts/
├── tool/                              # ✅ 已创建（monorepo 级脚本）
│   ├── init_monorepo.sh                # [本 skill 内置] 初始化
│   ├── gen_clients.sh                  # [本 skill 内置] 跨端生成
│   ├── sync_design_tokens.sh           # [本 skill 内置] 令牌同步
│   ├── run_all_checks.sh               # [本 skill 内置] 跨端检查
│   └── upgrade_dependencies.sh         # [本 skill 内置] 依赖升级
├── .github/
│   └── workflows/
│       └── mobile-desktop-ci.yml       # ✅ CI 配置
├── .gitignore
├── README.md
├── CONTRIBUTING.md
├── LICENSE
└── docs/
    └── ARCHITECTURE.md
```

### 1.3 GitHub 仓库首次创建（用户需手动）

```bash
# 1. 在 GitHub 创建仓库 stack-haven/avmc-mobile-desktop-service（私有）

# 2. 在根仓库添加 .gitmodules（不是子仓库内的 .gitmodules）
#    .gitmodules 在 avmc 根仓库中
cat >> ../avmc/.gitmodules << EOF

[submodule "mobile-desktop-service"]
	path = mobile-desktop-service
	url = git@github.com:stack-haven/avmc-mobile-desktop-service.git
EOF

# 3. 在根仓库 commit 并 push
cd ../avmc
git add .gitmodules
git commit -m "chore: 注册 mobile-desktop-service 子仓库"
git push

# 4. 子仓库初始化
cd mobile-desktop-service
git init
git remote add origin git@github.com:stack-haven/avmc-mobile-desktop-service.git
bash tool/init_monorepo.sh
git add -A
git commit -m "chore: 初始化 mobile-desktop-service monorepo 骨架"
git push -u origin main
```

---

## 二、目录结构（apps / packages / tooling）

### 2.1 顶层三分

```
mobile-desktop-service/
├── apps/        # 可独立发布的端应用（产物 = 安装包 / 小程序）
├── packages/    # 跨应用共享代码（库形式，由 apps/ 依赖）
└── tooling/     # 工具脚本、CI/CD 配置、代码生成
```

**绝对禁止：**

- ❌ 在 apps/ 下直接放共享代码（应抽到 packages/）
- ❌ packages/ 依赖 apps/（会形成循环）
- ❌ tooling/ 引用 apps/ 或 packages/ 内部代码（只能通过配置文件）

### 2.2 apps/ 命名规范

```
apps/
├── evie-mobile/           # Flutter，iOS/Android
├── evie-desktop/          # Flutter，macOS/Windows/Linux
├── geo-mobile/            # uni-app，iOS/Android
├── geo-mini/              # uni-app，微信/支付宝/抖音小程序
├── workbench-mobile/      # React Native，iOS/Android
└── workbench-desktop/     # Tauri（不在 mobile-desktop-service 内，归 Tauri 子仓）
```

| 端类型 | 后缀 | 示例 |
|--------|------|------|
| 移动 App | `-mobile` | `evie-mobile` |
| 桌面端 | `-desktop` | `evie-desktop` |
| 小程序 | `-mini` | `geo-mini` |
| 智能硬件 | `-device` | `watch-device` |

### 2.3 packages/ 组织原则

| 类型 | 命名规范 | 跨端共享策略 |
|------|---------|------------|
| API 客户端 | `api-client` | 同时提供 Dart 和 TS；Dart 暴露给 Flutter，TS 暴露给 RN/uni-app |
| 设计令牌 | `design-tokens` | `tokens.json` SSOT；各端 codegen 转换为运行时代码 |
| UI 组件库 | `ui-kit-flutter` / `ui-kit-react` / `ui-kit-uniapp` | 按技术栈分；不跨技术栈共享 UI |
| 业务核心 | `<product>-core` | Evie core 用 Dart（Flutter）；Geo core 用 TS（uni-app）；不强行跨栈共享业务逻辑 |

**反例（不允许）：**

- ❌ `packages/shared-business-logic/` 同时包含 Dart 和 TS 的同名类（不是真共享）
- ❌ `packages/all-in-one/` 把 UI + 业务 + API 全混在一起

### 2.4 tooling/ 组织

```
tooling/
├── codegen/                # 代码生成器配置
│   ├── buf.gen.yaml        # proto → 多端客户端
│   ├── design-tokens.config.json
│   └── README.md
├── ci/                     # CI 模板（被 .github/workflows 引用）
│   ├── flutter-ci.yml
│   ├── react-native-ci.yml
│   └── uniapp-ci.yml
└── scripts/                # 内部工具脚本
    ├── version_bump.sh
    └── changelog.sh
```

---

## 三、各端 Monorepo 工具配置

### 3.1 Flutter（apps/evie-mobile、apps/evie-desktop）

```yaml
# melos.yaml（子仓库根）
name: avmc_mobile_desktop

packages:
  - apps/**
  - packages/*

command:
  bootstrap:
    runPubGetInParallel: true

scripts:
  analyze:
    description: Run flutter analyze in all apps.
    run: melos exec -c 1 -- "flutter analyze"
  
  test:
    description: Run flutter test in all apps.
    run: melos exec -c 1 -- "flutter test"

  build:mobile:
    description: Build mobile artifacts.
    run: melos exec -c 1 --scope="*-mobile" -- "flutter build apk --release"

  format:
    description: Run dart format.
    run: melos exec -c 1 -- "dart format ."
```

**关键决策：**

- ✅ Flutter 多包用 **Melos**（dart pub global activate melos）
- ✅ 单个 app 用 **very_good_cli** 生成（约定优于配置）
- ❌ 不引入 Turborepo（Flutter 项目用 Melos 才是社区主流）

### 3.2 React Native（apps/workbench-mobile）

```json
// mobile-desktop-service/package.json（根）
{
  "name": "avmc-mobile-desktop-service",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "lint": "pnpm -r --parallel run lint",
    "test": "pnpm -r --parallel run test",
    "typecheck": "pnpm -r --parallel run typecheck"
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "eslint": "^8.57.0",
    "prettier": "^3.2.0"
  },
  "packageManager": "pnpm@8.15.0",
  "engines": {
    "node": ">=18"
  }
}
```

**关键决策：**

- ✅ 用 **pnpm workspaces**（节省磁盘、严格依赖）
- ✅ TypeScript 严格模式（与 backend-service 对齐）
- ❌ 不混用 yarn workspaces（团队统一 pnpm）

### 3.3 uni-app（apps/geo-mobile、apps/geo-mini）

uni-app 与 monorepo 工具的兼容性差，因为：
- HBuilderX 是 uni-app 的官方 IDE
- 标准 npm 工作流在 uni-app 上有诸多限制（条件编译、manifest.json）

**推荐策略：**

```json
// apps/geo-mobile/package.json（独立 monorepo，**不**用 workspaces）
{
  "name": "geo-mobile",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@dcloudio/uni-app": "3.0.0-4000020241225001",
    "vue": "^3.4.0"
  }
}
```

```json
// apps/geo-mini/package.json（与 geo-mobile 共享源码）
{
  "name": "geo-mini",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@dcloudio/uni-app": "3.0.0-4000020241225001",
    "vue": "^3.4.0"
  }
}
```

**关键决策：**

- ✅ geo-mobile 和 geo-mini **共享同一份 `src/` 源码**（同源码多产物）
- ✅ `manifest.json` 和 `pages.json` 在两个项目分别维护（平台配置差异）
- ❌ **不强行用 workspaces**（uni-app 编译器绑定 HBuilderX）

### 3.4 三栈工具选型总结

| 技术栈 | Monorepo 工具 | 包管理器 | 备注 |
|--------|--------------|---------|------|
| Flutter | Melos + very_good_cli | pub | 多包 + 项目约定 |
| React Native | pnpm workspaces | pnpm | 标准 Node.js monorepo |
| uni-app | 各自独立（无 workspaces） | npm + HBuilderX | 编译器绑定 |

---

## 四、跨端共享：API 客户端生成

### 4.1 buf.gen.yaml 配置（[内置脚本]）

```yaml
# tooling/codegen/buf.gen.yaml
version: v1
plugins:
  # === Dart（Flutter 应用）===
  - plugin: buf.build/protocolbuffers/dart
    out: ../../packages/api-client/lib
    opt: file_extension=pb.dart
  - plugin: buf.build/grpc/dart:v1
    out: ../../packages/api-client/lib

  # === TypeScript（RN / uni-app）===
  - plugin: buf.build/protocolbuffers/js
    out: ../../packages/api-client/src/proto
    opt: import_suffix=pb.js
  - plugin: buf.build/grpc/web
    out: ../../packages/api-client/src/proto
    opt: mode=grpcweb
```

### 4.2 gen_clients.sh 行为（[内置脚本]）

```bash
./tool/gen_clients.sh
```

**脚本执行：**

1. 校验 buf CLI 已安装
2. 定位 `backend-service/proto/` 源
3. 跑 `buf generate` 按 `tooling/codegen/buf.gen.yaml` 生成
4. 校验生成结果（Dart 客户端在 `packages/api-client/lib/`；TS 客户端在 `packages/api-client/src/proto/`）
5. 输出 changelog 提示

**典型输出：**

```
==> 生成 Dart 客户端（apps/evie-mobile 使用）
✓ packages/api-client/lib/evie/v1/dictionary.pb.dart
✓ packages/api-client/lib/evie/v1/dictionary.pbgrpc.dart

==> 生成 TypeScript 客户端（apps/workbench-mobile、apps/geo-mobile 使用）
✓ packages/api-client/src/proto/evie/v1/dictionary_pb.js
✓ packages/api-client/src/proto/evie/v1/dictionary_pb.d.ts
✓ packages/api-client/src/proto/evie/v1/dictionary_pb_service.js
```

### 4.3 客户端使用示例

**Flutter（Dart）：**

```yaml
# apps/evie-mobile/pubspec.yaml
dependencies:
  api_client:
    path: ../../../packages/api-client
```

```dart
import 'package:api_client/evie/v1/dictionary.pbgrpc.dart';

final client = DictionaryServiceClient(channel);
final response = await client.listWords(...);
```

**React Native（TypeScript）：**

```json
// apps/workbench-mobile/package.json
{
  "dependencies": {
    "api-client": "workspace:*"
  }
}
```

```typescript
import { DictionaryServiceClient } from 'api-client/proto/evie/v1/dictionary_pb_service';
import { ListWordsRequest } from 'api-client/proto/evie/v1/dictionary_pb';

const client = new DictionaryServiceClient('https://api.avmc.example.com');
const response = await client.listWords(new ListWordsRequest());
```

**uni-app（TypeScript）：**

uni-app 用 grpc-web 兼容性差，**实际推荐走 REST 封装层**：

```typescript
// packages/api-client/src/rest/evie.ts
// 由 buf.build/connectrpc/es 生成 REST 类型
// uni-app 调 REST 而非 gRPC
```

### 4.4 版本管理

API 客户端作为 monorepo workspace 内的本地包，使用 `workspace:*` 或 `path:` 协议引用：

- Flutter：`path: ../../../packages/api-client`
- pnpm：`"api-client": "workspace:*"`

**版本号统一策略：**

- mobile-desktop-service 子仓库整体使用 git tag（`v1.2.0`）
- packages/api-client 的版本号由脚本自动同步（`./tool/upgrade_dependencies.sh`）

---

## 五、跨端共享：设计令牌（Design Tokens）

### 5.1 tokens.json 源（SSOT）

```json
// packages/design-tokens/tokens.json
{
  "$schema": "https://design-tokens.github.io/community-group/format/",
  "color": {
    "primary": { "value": "#1890ff", "type": "color" },
    "success": { "value": "#52c41a", "type": "color" },
    "warning": { "value": "#faad14", "type": "color" },
    "error": { "value": "#ff4d4f", "type": "color" }
  },
  "spacing": {
    "xs": { "value": "4px", "type": "dimension" },
    "sm": { "value": "8px", "type": "dimension" },
    "md": { "value": "16px", "type": "dimension" },
    "lg": { "value": "24px", "type": "dimension" },
    "xl": { "value": "32px", "type": "dimension" }
  },
  "typography": {
    "heading-1": { "value": { "fontSize": "24px", "fontWeight": 600 }, "type": "typography" },
    "body": { "value": { "fontSize": "14px", "fontWeight": 400 }, "type": "typography" }
  },
  "radius": {
    "sm": { "value": "4px", "type": "dimension" },
    "md": { "value": "8px", "type": "dimension" },
    "lg": { "value": "12px", "type": "dimension" }
  }
}
```

### 5.2 sync_design_tokens.sh 行为（[内置脚本]）

```bash
./tool/sync_design_tokens.sh
```

**脚本执行：**

1. 用 `style-dictionary` 把 `tokens.json` 转为各端代码：
   - `packages/design-tokens/lib/theme.dart`（Flutter 用）
   - `packages/design-tokens/src/theme.ts`（RN 用）
   - `packages/design-tokens/src/theme.scss`（uni-app 用）
2. 跑 `dart format` / `prettier` 格式化生成代码
3. 输出 diff 摘要

**典型输出：**

```
==> 同步设计令牌到各端
✓ Dart:    packages/design-tokens/lib/theme.dart
✓ TS:      packages/design-tokens/src/theme.ts
✓ SCSS:    packages/design-tokens/src/theme.scss

Diff summary:
  color.primary: #1890ff (no change)
  spacing.md:    16px → 20px
  radius.lg:     (new)
```

### 5.3 各端使用示例

**Flutter：**

```dart
import 'package:design_tokens/theme.dart';

Container(
  padding: EdgeInsets.all(Spacing.md),
  decoration: BoxDecoration(
    color: ColorTokens.primary,
    borderRadius: BorderRadius.circular(RadiusTokens.md),
  ),
  child: Text(
    'Hello',
    style: TextStyle(
      fontSize: TypographyTokens.heading1.fontSize,
      fontWeight: TypographyTokens.heading1.fontWeight,
    ),
  ),
)
```

**React Native：**

```typescript
import { colors, spacing, typography } from 'design-tokens';

<View style={{
  padding: spacing.md,
  backgroundColor: colors.primary,
  borderRadius: 8,
}}>
  <Text style={typography.heading1}>Hello</Text>
</View>
```

**uni-app：**

```vue
<template>
  <view class="container">
    <text class="heading">Hello</text>
  </view>
</template>

<style lang="scss" scoped>
@import 'design-tokens/theme.scss';

.container {
  padding: $spacing-md;
  background-color: $color-primary;
  border-radius: $radius-md;
}

.heading {
  font-size: $typography-heading-1-font-size;
  font-weight: $typography-heading-1-font-weight;
}
</style>
```

---

## 六、跨端 CI/CD 协调

### 6.1 CI 架构：变更驱动

```yaml
# .github/workflows/mobile-desktop-ci.yml
name: mobile-desktop-service CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  # Step 1: 检测哪些端有变更
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      flutter: ${{ steps.filter.outputs.flutter }}
      react_native: ${{ steps.filter.outputs.react_native }}
      uniapp: ${{ steps.filter.outputs.uniapp }}
      tokens: ${{ steps.filter.outputs.tokens }}
      proto: ${{ steps.filter.outputs.proto }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: filter
        with:
          filters: |
            flutter:
              - 'apps/evie-*/**'
              - 'packages/*-flutter/**'
              - 'melos.yaml'
            react_native:
              - 'apps/workbench-*/**'
              - 'packages/*-react/**'
              - 'package.json'
            uniapp:
              - 'apps/geo-*/**'
            tokens:
              - 'packages/design-tokens/tokens.json'
            proto:
              - 'packages/api-client/**'
              - 'tooling/codegen/**'

  # Step 2: 各端独立 CI job（按变更触发）
  flutter-ci:
    needs: detect-changes
    if: needs.detect-changes.outputs.flutter == 'true'
    uses: ./.github/workflows/_flutter-ci.yml

  react-native-ci:
    needs: detect-changes
    if: needs.detect-changes.outputs.react_native == 'true'
    uses: ./.github/workflows/_react-native-ci.yml

  uniapp-ci:
    needs: detect-changes
    if: needs.detect-changes.outputs.uniapp == 'true'
    uses: ./.github/workflows/_uniapp-ci.yml

  # Step 3: 设计令牌同步（影响所有端）
  design-tokens-sync:
    needs: detect-changes
    if: needs.detect-changes.outputs.tokens == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./tool/sync_design_tokens.sh
      - uses: pnpm/action-setup@v2
      - run: pnpm install --frozen-lockfile
      - run: ./tool/run_all_checks.sh --scope design-tokens

  # Step 4: proto 契约验证（破坏性变更阻断）
  proto-breaking:
    needs: detect-changes
    if: needs.detect-changes.outputs.proto == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      - uses: bufbuild/buf-action@v1
      - run: buf breaking --against '.git#branch=main'
```

### 6.2 run_all_checks.sh 行为（[内置脚本]）

```bash
./tool/run_all_checks.sh                   # 跑全部变更端的检查
./tool/run_all_checks.sh --scope flutter   # 只跑 Flutter
./tool/run_all_checks.sh --scope design-tokens
```

**脚本执行：**

1. 检测当前 git diff 涉及的端
2. 按端类型调度对应的 lint + test + build 命令
3. 输出汇总结果

### 6.3 升级依赖

```bash
./tool/upgrade_dependencies.sh                    # 升级所有端
./tool/upgrade_dependencies.sh --scope flutter    # 只升 Flutter
./tool/upgrade_dependencies.sh --scope react-native
./tool/upgrade_dependencies.sh --scope uniapp
```

**脚本执行：**

1. 跑 `flutter pub upgrade` / `pnpm outdated && pnpm update` / `npm outdated`
2. 输出 changelog 摘要
3. 可选自动创建 PR

---

## 七、版本管理

### 7.1 整体版本号

mobile-desktop-service 整体使用 git tag：

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

### 7.2 内部包版本

packages/api-client、packages/design-tokens 等的版本号由 monorepo 根版本派生：

- v1.2.0 → api-client@1.2.0、design-tokens@1.2.0
- 通过 `./tool/upgrade_dependencies.sh --bump-version` 自动更新

### 7.3 变更日志

`CHANGELOG.md` 由 conventional commits 自动生成：

```bash
./tool/scripts/changelog.sh  # 读最近 100 个 commit，按类型分组
```

---

## 八、安全与合规

### 8.1 敏感配置

- ❌ **不存** API key、secret、token 在代码中
- ✅ 通过 `backend-service` 代理敏感操作（如支付、推送）
- ✅ 本地 token 存平台安全机制（Keychain / Keyring）

### 8.2 代码混淆

| 端 | 工具 | 配置位置 |
|----|------|---------|
| Flutter（移动） | `--obfuscate --split-debug-info` | CI build 命令 |
| Flutter（桌面） | N/A（dart obfuscate 可选） | — |
| React Native | ProGuard（Android）+ Hermes | `android/app/proguard-rules.pro` |
| uni-app | 启用 `enableMiniAppCodeCache` + 加密 | `manifest.json` |

### 8.3 隐私合规

- iOS：Info.plist 必须有 `NSPhotoLibraryUsageDescription` 等
- Android：AndroidManifest 权限最小化
- macOS：`entitlements` 文件最小化
- 小程序：用户隐私协议 + 数据收集声明

---

## 九、待完善的子 skill ⚠️

下列 skill 当前为基础版（占位 + 脚手架建议），**未经过实战验证**：

### 9.1 `avmc-react-native-app`

**当前状态：** 提供基础项目结构 + pubspec/package.json 模板 + 状态管理建议（Zustand）。

**待实战补充：**

- 实际痛点（Hermes 配置、Metro 缓存、原生模块链接）
- 平台特定 hack（iOS Pods、Android Gradle）
- 团队组件库选型（react-native-paper / NativeBase / Tamagui）
- 离线优先策略（WatermelonDB / SQLite）
- 推送通知集成（FCM / APNs）
- 性能优化（FlashList / 渲染优化）

**触发提醒规则**（Agent 必读）：

> ⚠️ **当用户提出"用 React Native 在 mobile-desktop-service 开发 XX"任务时**：
> 1. **必须**先告知用户：skill 当前为基础版，未实战验证
> 2. **询问**：是否暂停任务先花 1-2 小时补充 skill（基于真实项目经验），或按当前 skill 推进
> 3. **记录**：在 `docs/architecture/4-6-治理-开发功能清单.md` 4.3 章节下追加一行 `[ ] P? RN skill 待实战补充`
> 4. **不允许**长期绕过：超过 2 周仍未实战补充时，再次提醒

### 9.2 `avmc-uniapp-app`

**当前状态：** 提供基础项目结构 + manifest.json 模板 + 条件编译示例。

**待实战补充：**

- 实际痛点（HBuilderX 与 CLI 工作流冲突、App 端打包体积优化）
- 各小程序平台差异（微信、抖音、支付宝、百度）
- 原生插件开发（uni-app 原生 SDK 集成）
- 跨端 UI 库选型（uv-ui vs uView 2.0 vs uni-ui）
- 性能监控与上报（uni.stat / 自研）
- 小程序分包加载策略
- App 上架审核踩坑

**触发提醒规则**（Agent 必读）：

> ⚠️ **当用户提出"用 uni-app 在 mobile-desktop-service 开发 XX"任务时**：
> 1. **必须**先告知用户：skill 当前为基础版，未实战验证
> 2. **询问**：是否暂停任务先花 1-2 小时补充 skill（基于真实项目经验），或按当前 skill 推进
> 3. **记录**：在 `docs/architecture/4-6-治理-开发功能清单.md` 4.3 章节下追加一行 `[ ] P? uni-app skill 待实战补充`
> 4. **不允许**长期绕过：超过 2 周仍未实战补充时，再次提醒

### 9.3 提醒的执行方式

实现路径：

1. **文档层**：本 SKILL.md 第九章 + `avmc-react-native-app/SKILL.md` / `avmc-uniapp-app/SKILL.md` 顶部加 "TODO: 待实战验证" 标记
2. **清单层**：在 `4-6-治理-开发功能清单.md` 4.3 章节预留 `[ ] P? RN/uniapp skill 待实战补充` 行
3. **流程层**：Agent 接到 RN/uni-app 任务时**必须**先读对应 skill，若发现"待实战验证"标记，**主动询问用户**

---

## 十、内置脚本速查

| 脚本 | 用途 | 调用时机 |
|------|------|----------|
| `tool/init_monorepo.sh` | 初始化 mobile-desktop-service 子仓库骨架 | 首次创建仓库后 |
| `tool/gen_clients.sh` | proto → 多端客户端生成（Dart + TS） | backend-service proto 变更后 |
| `tool/sync_design_tokens.sh` | tokens.json → 各端代码生成 | 设计令牌变更后 |
| `tool/run_all_checks.sh` | 跨端 lint/test 调度（按文件变更触发） | pre-commit / CI |
| `tool/upgrade_dependencies.sh` | 跨端依赖升级 | 季度依赖维护 |

详细用法见各脚本头部注释。

---

## 十一、与其他端 skill 的关系

| skill | 状态 | 何时使用 |
|-------|------|---------|
| `avmc-flutter-app` | ✅ 已深度实战基础（very_good_cli + Flutter 官方架构） | Flutter 项目脚手架 + 新增 feature |
| `avmc-react-native-app` | ⚠️ 基础版（待实战验证） | RN 项目脚手架；首次实战前必读第九章提醒 |
| `avmc-uniapp-app` | ⚠️ 基础版（待实战验证） | uni-app 项目脚手架；首次实战前必读第九章提醒 |

**使用顺序：**

1. 先读本 skill（avmc-mobile-desktop-monorepo）理解 monorepo 整体
2. 再读对应端 skill 启动具体应用
3. 应用内新增 feature 时，按对应端 skill 指引

---

## 十二、相关文档

- 子仓库服务资料：`docs/services/mobile-desktop/README.md`
- 子仓库技术规范：`docs/services/mobile-desktop/SERVICE.md`
- 平台分层：`docs/architecture/0-1-架构总览-平台分层设计.md`
- 端应用 skill：`avmc-flutter-app`、`avmc-react-native-app`、`avmc-uniapp-app`
- API 契约：`docs/architecture/3-0-跨领域-API边界与通信契约.md`
