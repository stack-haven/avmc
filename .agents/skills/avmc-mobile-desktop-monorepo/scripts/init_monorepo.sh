#!/usr/bin/env bash
# init_monorepo.sh
#
# 初始化 mobile-desktop-service 子仓库骨架。
# 创建 apps/、packages/、tooling/ 顶层结构，注入配置文件和内置脚本。
#
# 用法：
#   ./tool/init_monorepo.sh [--monorepo-root <path>]
#
# 参数：
#   --monorepo-root   monorepo 根目录（默认当前目录）
#
# 前置条件：
#   1. 已在 GitHub 创建 stack-haven/avmc-mobile-desktop-service 仓库
#   2. 已 git clone 到本地
#   3. 当前目录是 monorepo 根
#
# 退出码：
#   0 成功
#   1 参数错误
#   2 目录已初始化（apps/ 已存在）
#   3 非空目录冲突

set -euo pipefail

MONOREPO_ROOT="."
while [ $# -gt 0 ]; do
  case "$1" in
    --monorepo-root)
      MONOREPO_ROOT=$2
      shift 2
      ;;
    *)
      echo "Error: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

cd "$MONOREPO_ROOT"

# 校验当前目录是空仓库（或只有 .git）
if [ -d "apps" ] || [ -d "packages" ] || [ -d "tooling" ]; then
  echo "Error: monorepo already initialized (apps/ or packages/ or tooling/ exists)" >&2
  exit 2
fi

# 校验是 git 仓库
if [ ! -d ".git" ]; then
  echo "Error: not a git repository. Run 'git init' first." >&2
  exit 3
fi

echo "==> 创建 monorepo 顶层结构"

# ===== apps/ =====
mkdir -p apps
cat > apps/.gitkeep << 'EOF'
EOF
cat > apps/README.md << 'EOF'
# Apps

可独立发布的端应用。每个子目录对应一个交付产物。

## 命名规范

```
<product>-<platform>/
```

| 端类型 | 后缀 | 示例 |
|--------|------|------|
| 移动 App | `-mobile` | `evie-mobile` |
| 桌面端 | `-desktop` | `evie-desktop` |
| 小程序 | `-mini` | `geo-mini` |
| 智能硬件 | `-device` | `watch-device` |

## 新增应用

参考 `avmc-mobile-desktop-monorepo` skill 指引。
EOF
echo "  ✓ apps/"

# ===== packages/api-client/ =====
mkdir -p packages/api-client/lib packages/api-client/src
cat > packages/api-client/lib/.gitkeep << 'EOF'
EOF
cat > packages/api-client/src/.gitkeep << 'EOF'
EOF

# Dart 包元数据
cat > packages/api-client/pubspec.yaml << 'EOF'
name: api_client
description: 跨端共享 API 客户端（与 backend-service proto 对接）。由 tooling/codegen/buf.gen.yaml 自动生成。
version: 0.1.0
publish_to: none

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  grpc: ^3.2.4
  protobuf: ^3.1.0

dev_dependencies:
  very_good_analysis: ^6.0.0
EOF

# TS 包元数据
cat > packages/api-client/package.json << 'EOF'
{
  "name": "@avmc/api-client",
  "version": "0.1.0",
  "private": true,
  "description": "跨端共享 API 客户端（与 backend-service proto 对接）。由 tooling/codegen/buf.gen.yaml 自动生成。",
  "main": "src/index.ts",
  "types": "src/index.d.ts",
  "scripts": {
    "build": "tsc",
    "lint": "eslint src --ext .ts"
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "eslint": "^8.57.0",
    "@typescript-eslint/eslint-plugin": "^7.0.0"
  }
}
EOF

cat > packages/api-client/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es2020",
    "module": "esnext",
    "lib": ["es2020", "dom"],
    "declaration": true,
    "strict": true,
    "esModuleInterop": true,
    "moduleResolution": "node",
    "skipLibCheck": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

cat > packages/api-client/README.md << 'EOF'
# @avmc/api-client

跨端共享 API 客户端。由 `backend-service/proto` 自动生成。

## 生成方式

```bash
./tool/gen_clients.sh
```

## 使用

### Flutter（Dart）

```dart
import 'package:api_client/evie/v1/dictionary.pbgrpc.dart';

final client = DictionaryServiceClient(channel);
final response = await client.listWords(...);
```

### React Native / uni-app（TypeScript）

```typescript
import { DictionaryServiceClient } from '@avmc/api-client/proto/evie/v1/dictionary_pb_service';
import { ListWordsRequest } from '@avmc/api-client/proto/evie/v1/dictionary_pb';

const client = new DictionaryServiceClient('https://api.avmc.example.com');
const response = await client.listWords(new ListWordsRequest());
```

## ⚠️ 不要手动修改

本目录由 `tool/gen_clients.sh` 自动生成。手动修改会在下次生成时被覆盖。
EOF
echo "  ✓ packages/api-client/"

# ===== packages/design-tokens/ =====
mkdir -p packages/design-tokens/lib packages/design-tokens/src

cat > packages/design-tokens/tokens.json << 'EOF'
{
  "$schema": "https://design-tokens.github.io/community-group/format/",
  "_comment": "⚠️ 这是跨端设计令牌的单一事实来源（SSOT）。修改后跑 ./tool/sync_design_tokens.sh 自动同步到各端代码。",
  "color": {
    "primary": { "value": "#1890ff", "type": "color" },
    "success": { "value": "#52c41a", "type": "color" },
    "warning": { "value": "#faad14", "type": "color" },
    "error": { "value": "#ff4d4f", "type": "color" },
    "text-primary": { "value": "rgba(0, 0, 0, 0.85)", "type": "color" },
    "text-secondary": { "value": "rgba(0, 0, 0, 0.65)", "type": "color" },
    "text-disabled": { "value": "rgba(0, 0, 0, 0.45)", "type": "color" },
    "background": { "value": "#ffffff", "type": "color" },
    "background-alt": { "value": "#fafafa", "type": "color" },
    "border": { "value": "#d9d9d9", "type": "color" }
  },
  "spacing": {
    "xs": { "value": "4px", "type": "dimension" },
    "sm": { "value": "8px", "type": "dimension" },
    "md": { "value": "16px", "type": "dimension" },
    "lg": { "value": "24px", "type": "dimension" },
    "xl": { "value": "32px", "type": "dimension" },
    "xxl": { "value": "48px", "type": "dimension" }
  },
  "typography": {
    "heading-1": { "value": { "fontSize": "24px", "fontWeight": 600, "lineHeight": "32px" }, "type": "typography" },
    "heading-2": { "value": { "fontSize": "20px", "fontWeight": 600, "lineHeight": "28px" }, "type": "typography" },
    "heading-3": { "value": { "fontSize": "16px", "fontWeight": 600, "lineHeight": "24px" }, "type": "typography" },
    "body": { "value": { "fontSize": "14px", "fontWeight": 400, "lineHeight": "22px" }, "type": "typography" },
    "caption": { "value": { "fontSize": "12px", "fontWeight": 400, "lineHeight": "20px" }, "type": "typography" }
  },
  "radius": {
    "none": { "value": "0px", "type": "dimension" },
    "sm": { "value": "4px", "type": "dimension" },
    "md": { "value": "8px", "type": "dimension" },
    "lg": { "value": "12px", "type": "dimension" },
    "full": { "value": "9999px", "type": "dimension" }
  },
  "elevation": {
    "none": { "value": "none", "type": "shadow" },
    "sm": { "value": "0 1px 2px rgba(0,0,0,0.08)", "type": "shadow" },
    "md": { "value": "0 2px 8px rgba(0,0,0,0.12)", "type": "shadow" },
    "lg": { "value": "0 4px 16px rgba(0,0,0,0.16)", "type": "shadow" }
  }
}
EOF

cat > packages/design-tokens/README.md << 'EOF'
# @avmc/design-tokens

跨端设计令牌。`tokens.json` 是单一事实来源（SSOT），由 `./tool/sync_design_tokens.sh` 自动生成各端代码。

## 目录结构

```
design-tokens/
├── tokens.json                # ⚠️ SSOT（手动编辑此文件）
├── lib/theme.dart             # Flutter 使用（自动生成）
├── src/theme.ts               # React Native 使用（自动生成）
├── src/theme.scss             # uni-app 使用（自动生成）
└── README.md
```

## 修改令牌

1. 编辑 `tokens.json`
2. 跑 `./tool/sync_design_tokens.sh`
3. 各端 apps 自动看到变更（通过 workspace: protocol）
4. CI 验证生成代码无 lint 错误
EOF
echo "  ✓ packages/design-tokens/"

cat > packages/README.md << 'EOF'
# Packages

跨应用共享代码。每个子目录是一个 workspace 包。

## 当前包

| 包名 | 类型 | 说明 |
|------|------|------|
| `api-client` | API 客户端 | 跨端共享，由 proto 自动生成 |
| `design-tokens` | 设计令牌 | 跨端设计令牌 SSOT + 各端代码生成 |

## 命名规范

- 单技术栈包：`<name>-flutter` / `<name>-react` / `<name>-uniapp`
- 跨技术栈包：直接 `<name>`（如 `api-client`）
- 业务核心：`<product>-core`（如 `evie-core`、`geo-core`）

## 新增包

1. 创建目录：`mkdir -p packages/<name>`
2. 添加元数据：`pubspec.yaml`（Dart）或 `package.json`（TS）
3. 跑 `./tool/run_all_checks.sh` 验证
4. 在 apps/* 中通过 `path:` 或 `workspace:*` 引用
EOF

# ===== tooling/ =====
mkdir -p tooling/codegen tooling/ci tooling/scripts

cat > tooling/codegen/buf.gen.yaml << 'EOF'
# buf.gen.yaml
#
# 跨端 proto 客户端生成配置。
# 输出到 packages/api-client/ 下的 Dart 和 TypeScript 目录。
#
# 使用方法：
#   ./tool/gen_clients.sh
#
# ⚠️ 不要手动运行 buf generate；统一通过脚本调用，确保路径解析一致。

version: v1
plugins:
  # === Dart（Flutter 应用）===
  - plugin: buf.build/protocolbuffers/dart
    out: ../../packages/api-client/lib
    opt: file_extension=pb.dart
  - plugin: buf.build/grpc/dart:v1
    out: ../../packages/api-client/lib

  # === TypeScript（React Native / uni-app）===
  - plugin: buf.build/protocolbuffers/js
    out: ../../packages/api-client/src/proto
    opt: import_suffix=pb.js
  - plugin: buf.build/grpc/web
    out: ../../packages/api-client/src/proto
    opt: mode=grpcweb
EOF

cat > tooling/codegen/buf-gen-dart.yaml << 'EOF'
# buf-gen-dart.yaml
#
# 仅生成 Dart 客户端（用于 apps/evie-mobile、apps/evie-desktop）。
# 与 buf.gen.yaml 的区别：buf.gen.yaml 同时生成 Dart + TS。
#
# 使用方法：
#   buf generate --template tooling/codegen/buf-gen-dart.yaml \
#     --output packages/api-client/lib

version: v1
plugins:
  - plugin: buf.build/protocolbuffers/dart
    out: ../../packages/api-client/lib
    opt: file_extension=pb.dart
  - plugin: buf.build/grpc/dart:v1
    out: ../../packages/api-client/lib
EOF

cat > tooling/codegen/buf-gen-ts.yaml << 'EOF'
# buf-gen-ts.yaml
#
# 仅生成 TypeScript 客户端（用于 apps/workbench-mobile、apps/geo-*）。
#
# 使用方法：
#   buf generate --template tooling/codegen/buf-gen-ts.yaml \
#     --output packages/api-client/src

version: v1
plugins:
  - plugin: buf.build/protocolbuffers/js
    out: ../../packages/api-client/src/proto
    opt: import_suffix=pb.js
  - plugin: buf.build/grpc/web
    out: ../../packages/api-client/src/proto
    opt: mode=grpcweb
EOF

cat > tooling/codegen/style-dictionary.config.json << 'EOF'
{
  "source": ["packages/design-tokens/tokens.json"],
  "platforms": {
    "dart": {
      "transformGroup": "dart",
      "buildPath": "packages/design-tokens/lib/",
      "files": [
        {
          "destination": "theme.dart",
          "format": "dart/flutter/class.dart"
        }
      ]
    },
    "ts": {
      "transformGroup": "js",
      "buildPath": "packages/design-tokens/src/",
      "files": [
        {
          "destination": "theme.ts",
          "format": "typescript/object"
        }
      ]
    },
    "scss": {
      "transformGroup": "scss",
      "buildPath": "packages/design-tokens/src/",
      "files": [
        {
          "destination": "theme.scss",
          "format": "scss/variables"
        }
      ]
    }
  }
}
EOF

cat > tooling/codegen/README.md << 'EOF'
# Codegen

跨端代码生成器配置。

## 文件

| 文件 | 用途 |
|------|------|
| `buf.gen.yaml` | proto → Dart + TS（同时生成） |
| `buf-gen-dart.yaml` | proto → Dart（仅） |
| `buf-gen-ts.yaml` | proto → TS（仅） |
| `style-dictionary.config.json` | design tokens → 各端代码 |

## 调用方式

通过根目录脚本：

```bash
./tool/gen_clients.sh          # 跨端客户端生成
./tool/sync_design_tokens.sh   # 设计令牌同步
```

## ⚠️ 不要手动运行 buf generate

直接调用 `buf generate` 可能因为路径问题生成到错误位置。
统一通过脚本调用。
EOF
echo "  ✓ tooling/codegen/"

cat > tooling/ci/README.md << 'EOF'
# CI 配置

GitHub Actions 模板。被 `.github/workflows/mobile-desktop-ci.yml` 引用。

## 模板文件

| 文件 | 用途 |
|------|------|
| `flutter-ci.yml` | Flutter 应用 CI（lint + test + build） |
| `react-native-ci.yml` | React Native CI |
| `uniapp-ci.yml` | uni-app CI |

## 复用工作流

主工作流 `mobile-desktop-ci.yml` 用 `jobs.<name>.uses:` 引用这些模板：

```yaml
flutter-ci:
  uses: ./.github/workflows/_flutter-ci.yml
```

模板化避免主工作流文件臃肿。
EOF

cat > tooling/scripts/README.md << 'EOF'
# 内部工具脚本

跨 monorepo 使用的工具脚本。

## 文件

- `version_bump.sh` — 批量更新 packages/ 下所有包的版本号
- `changelog.sh` — 从 git log 生成 CHANGELOG.md

调用方式：

```bash
./tooling/scripts/version_bump.sh --bump minor
./tooling/scripts/changelog.sh --since v1.0.0
```
EOF
echo "  ✓ tooling/"

# ===== tool/ =====
mkdir -p tool
cat > tool/README.md << 'EOF'
# Monorepo 级脚本

由 `avmc-mobile-desktop-monorepo` skill 维护。复制到 `mobile-desktop-service/tool/` 目录使用。

## 脚本列表

| 脚本 | 用途 |
|------|------|
| `init_monorepo.sh` | 初始化 monorepo 骨架 |
| `gen_clients.sh` | proto → 多端客户端生成 |
| `sync_design_tokens.sh` | design tokens → 各端代码 |
| `run_all_checks.sh` | 跨端 lint/test 调度 |
| `upgrade_dependencies.sh` | 跨端依赖升级 |

## 调用顺序

```bash
# 首次创建仓库后
./tool/init_monorepo.sh

# backend-service proto 变更后
./tool/gen_clients.sh

# 设计令牌变更后
./tool/sync_design_tokens.sh

# pre-commit / CI
./tool/run_all_checks.sh

# 季度依赖维护
./tool/upgrade_dependencies.sh
```
EOF
echo "  ✓ tool/"

# ===== .github/workflows/ =====
mkdir -p .github/workflows

cat > .github/workflows/mobile-desktop-ci.yml << 'EOF'
# GitHub Actions CI for mobile-desktop-service
# 详细配置参考 tooling/ci/README.md

name: mobile-desktop-service CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
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
EOF
echo "  ✓ .github/workflows/mobile-desktop-ci.yml"

# ===== 仓库根配置 =====
cat > .gitignore << 'EOF'
# Flutter / Dart
**/.dart_tool/
**/.flutter-plugins
**/.flutter-plugins-dependencies
**/.packages
**/.pub-cache/
**/.pub/
**/build/
**/.idea/
**/*.iml

# Node.js
**/node_modules/
**/yarn-error.log
**/npm-debug.log
**/.pnpm-store/

# uni-app
**/unpackage/
**/HBuilderX/

# 生成代码
packages/api-client/lib/**/*.pb.dart
packages/api-client/lib/**/*.pbgrpc.dart
packages/api-client/src/proto/
packages/design-tokens/lib/theme.dart
packages/design-tokens/src/theme.ts
packages/design-tokens/src/theme.scss

# 密钥
**/*.env
**/*.key
**/*.pem

# IDE
**/.vscode/
**/.idea/
**/*.swp

# 操作系统
.DS_Store
Thumbs.db
EOF

cat > README.md << 'EOF'
# Mobile Desktop Service

Ark Tech Platform 多端应用承载层（桌面端 + 移动端 + 小程序端）。

**不实现业务逻辑**，只承载各 Ark Product Service（Evie / GEO / Workbench）的端产物。

## 架构

```
backend-service/proto/    → 契约源
        ↓ buf generate
packages/api-client/      → Dart + TS 客户端
        ↓ workspace 引用
apps/{product}-{platform}/  → 端应用
```

详细规范见 `docs/services/mobile-desktop/SERVICE.md`。

## 当前应用

| 产品 | 端 | 路径 | 技术栈 |
|------|----|-----|--------|
| — | — | — | — |

（待 init_monorepo.sh 完成后填充）

## 开发

```bash
# 初始化（首次）
./tool/init_monorepo.sh

# proto 变更后生成客户端
./tool/gen_clients.sh

# 设计令牌变更后同步
./tool/sync_design_tokens.sh

# pre-commit
./tool/run_all_checks.sh

# 升级依赖
./tool/upgrade_dependencies.sh
```

## 相关文档

- 服务资料：`docs/services/mobile-desktop/README.md`（在根仓库）
- 技术规范：`docs/services/mobile-desktop/SERVICE.md`（在根仓库）
- Skill：`avmc-mobile-desktop-monorepo`（根仓库 `.agents/skills/`）
EOF

cat > CONTRIBUTING.md << 'EOF'
# Contributing to Mobile Desktop Service

## 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
feat(apps/evie-mobile): 新增词库中心移动端
fix(apps/evie-desktop): 修复 macOS 启动崩溃
chore(monorepo): 升级 melos 到 6.0.0
docs(skill): 补充 RN 实战经验到 skill
```

## 分支策略

- `main` — 受保护，仅通过 PR 合并
- `feat/<feature>` — 功能开发
- `fix/<bug>` — 缺陷修复
- `release/<version>` — 发布准备

## PR 检查清单

- [ ] `./tool/run_all_checks.sh` 全绿
- [ ] 涉及 proto 变更时 `./tool/gen_clients.sh` 已重新生成客户端
- [ ] 涉及设计令牌变更时 `./tool/sync_design_tokens.sh` 已同步
- [ ] CHANGELOG.md 已更新（重大变更）
- [ ] 至少一个 reviewer 通过
EOF

cat > LICENSE << 'EOF'
Copyright (c) 2026 stack-haven

保留所有权利。
EOF

# ===== docs/ =====
mkdir -p docs
cat > docs/ARCHITECTURE.md << 'EOF'
# Mobile Desktop Service 架构

## 顶层结构

```
mobile-desktop-service/
├── apps/         # 可独立发布的端应用
├── packages/     # 跨应用共享代码
├── tooling/      # 工具脚本和配置
└── tool/         # monorepo 级脚本
```

## 数据流

```
backend-service/proto (SSOT)
    ↓ buf generate
packages/api-client/  (Dart + TS)
    ↓ workspace 引用
apps/{product}-{platform}/
```

## 依赖方向

- `apps/*` → `packages/*`
- `apps/*` → `apps/*` ❌（禁止）
- `packages/*` → `packages/*` ⚠️（谨慎使用，避免循环）

## CI 协调

变更驱动：
- Flutter 变更 → Flutter CI
- RN 变更 → RN CI
- uni-app 变更 → uni-app CI
- proto 变更 → buf breaking check
- tokens 变更 → design-tokens 同步
EOF
echo "  ✓ docs/"

# ===== melos.yaml（Flutter 端 monorepo）=====
cat > melos.yaml << 'EOF'
name: avmc_mobile_desktop

packages:
  - apps/**
  - packages/*

command:
  bootstrap:
    runPubGetInParallel: true
    usePubspecOverrides: true

scripts:
  analyze:
    description: Run flutter analyze in all packages.
    run: melos exec -c 1 -- "flutter analyze"

  test:
    description: Run flutter test in all packages.
    run: melos exec -c 1 -- "flutter test"

  format:
    description: Run dart format in all packages.
    run: melos exec -c 1 -- "dart format ."

  build:mobile:
    description: Build mobile artifacts (APK / IPA).
    run: melos exec -c 1 --scope="*-mobile" -- "flutter build apk --release"

  build:desktop:
    description: Build desktop artifacts.
    run: melos exec -c 1 --scope="*-desktop" -- "flutter build macos --release"
EOF

# ===== 顶层 package.json（pnpm workspace）=====
cat > package.json << 'EOF'
{
  "name": "avmc-mobile-desktop-service",
  "version": "0.1.0",
  "private": true,
  "description": "Ark Tech Platform 多端应用承载层 monorepo。",
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "lint": "pnpm -r --parallel run lint",
    "test": "pnpm -r --parallel run test",
    "typecheck": "pnpm -r --parallel run typecheck",
    "format": "pnpm -r --parallel run format"
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
EOF

echo ""
echo "✅ Monorepo 骨架初始化完成"
echo ""
echo "目录结构："
echo "  mobile-desktop-service/"
echo "  ├── apps/              (空，待新增应用)"
echo "  ├── packages/"
echo "  │   ├── api-client/    (proto 客户端占位)"
echo "  │   └── design-tokens/ (tokens.json SSOT)"
echo "  ├── tooling/"
echo "  │   ├── codegen/       (buf.gen.yaml + style-dictionary.config.json)"
echo "  │   ├── ci/            (CI 模板)"
echo "  │   └── scripts/       (内部工具脚本)"
echo "  ├── tool/              (monorepo 级脚本占位)"
echo "  ├── .github/workflows/ (mobile-desktop-ci.yml)"
echo "  ├── melos.yaml         (Flutter monorepo)"
echo "  └── package.json       (pnpm workspaces)"
echo ""
echo "下一步："
echo "  1. 复制本 skill 的 scripts/ 到 tool/ 目录："
echo "       cp -r <skill_dir>/scripts/* tool/"
echo "       chmod +x tool/*.sh"
echo "  2. 创建首个应用："
echo "       cd apps && very_good create flutter_app evie_mobile \\"
echo "         --description 'Evie Mobile' --org com.stackhaven.avmc"
echo "  3. 提交："
echo "       git add -A && git commit -m 'chore(monorepo): 初始化多端 monorepo 骨架'"
