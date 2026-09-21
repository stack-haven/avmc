#!/usr/bin/env bash
# upgrade_dependencies.sh
#
# 跨端依赖升级器。
# 支持 Flutter / React Native / uni-app 三端的依赖检查和升级。
#
# 用法：
#   ./tool/upgrade_dependencies.sh [--scope flutter|react-native|uniapp|all] [--bump patch|minor|major]
#   ./tool/upgrade_dependencies.sh [--scope api-client] [--bump patch|minor|major]
#
# 参数：
#   --scope      升级范围：flutter、react-native、uniapp、api-client、design-tokens、all
#   --bump       版本号变更幅度：patch（默认）、minor、major
#   --check      只检查可升级版本，不实际执行（CI 用）
#
# 退出码：
#   0 成功
#   1 参数错误
#   2 工具链缺失
#   3 升级失败

set -euo pipefail

SCOPE="all"
BUMP="patch"
CHECK_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --scope)
      SCOPE=$2
      shift 2
      ;;
    --bump)
      BUMP=$2
      shift 2
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    *)
      echo "Error: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

# 校验 scope
case "$SCOPE" in
  flutter|react-native|uniapp|all|api-client|design-tokens) ;;
  *)
    echo "Error: --scope must be flutter, react-native, uniapp, all, api-client, design-tokens" >&2
    exit 1
    ;;
esac

# 校验 bump
case "$BUMP" in
  patch|minor|major) ;;
  *)
    echo "Error: --bump must be patch, minor, or major" >&2
    exit 1
    ;;
esac

# 校验在 monorepo 根目录
if [ ! -d "packages" ] || [ ! -d "apps" ]; then
  echo "Error: not in mobile-desktop-service monorepo root" >&2
  exit 1
fi

echo "==> 跨端依赖升级"
echo "    scope:  $SCOPE"
echo "    bump:   $BUMP"
echo "    mode:   $([ "$CHECK_ONLY" = true ] && echo 'check only' || echo 'apply')"
echo ""

run_flutter_upgrade() {
  if ! command -v flutter &> /dev/null; then
    echo "==> [flutter] flutter 未安装，跳过"
    return 0
  fi

  echo "==> [flutter] 检查可升级依赖"
  flutter pub outdated 2>&1 | tail -20 || true

  if [ "$CHECK_ONLY" = true ]; then
    echo "==> [flutter] (check only, skipping upgrade)"
    return 0
  fi

  echo ""
  echo "==> [flutter] 升级依赖（这是破坏性变更，确认前请 review）"
  read -p "确认升级 Flutter 依赖？[y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "==> [flutter] 跳过升级"
    return 0
  fi

  if command -v melos &> /dev/null && [ -f "melos.yaml" ]; then
    melos exec -c 1 -- "flutter pub upgrade --major-versions"
  else
    flutter pub upgrade --major-versions
  fi
}

run_react_native_upgrade() {
  if ! command -v pnpm &> /dev/null; then
    echo "==> [react-native] pnpm 未安装，跳过"
    return 0
  fi

  echo "==> [react-native] 检查可升级依赖"
  pnpm outdated -r 2>&1 | tail -20 || true

  if [ "$CHECK_ONLY" = true ]; then
    echo "==> [react-native] (check only, skipping upgrade)"
    return 0
  fi

  echo ""
  echo "==> [react-native] 升级依赖"
  read -p "确认升级 RN 依赖？[y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "==> [react-native] 跳过升级"
    return 0
  fi

  pnpm update -r --latest
}

run_uniapp_upgrade() {
  echo "==> [uniapp] 检查可升级依赖"
  for app in apps/geo-mobile apps/geo-mini; do
    if [ -d "$app" ] && [ -f "$app/package.json" ]; then
      echo "  → $app"
      cd "$app"
      npm outdated 2>&1 | tail -10 || true
      cd - > /dev/null
    fi
  done

  if [ "$CHECK_ONLY" = true ]; then
    echo "==> [uniapp] (check only, skipping upgrade)"
    return 0
  fi

  echo ""
  echo "==> [uniapp] 升级依赖"
  read -p "确认升级 uni-app 依赖？[y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "==> [uniapp] 跳过升级"
    return 0
  fi

  for app in apps/geo-mobile apps/geo-mini; do
    if [ -d "$app" ] && [ -f "$app/package.json" ]; then
      echo "  → $app"
      cd "$app"
      npm update --save 2>&1 | tail -5 || true
      cd - > /dev/null
    fi
  done
}

run_api_client_bump() {
  if [ ! -f "packages/api-client/pubspec.yaml" ]; then
    echo "==> [api-client] pubspec.yaml 不存在，跳过"
    return 0
  fi

  echo "==> [api-client] 当前版本"
  grep "^version:" packages/api-client/pubspec.yaml
  grep '"version"' packages/api-client/package.json

  if [ "$CHECK_ONLY" = true ]; then
    echo "==> [api-client] (check only, skipping bump)"
    return 0
  fi

  # 提取当前版本
  CURRENT_DART=$(grep "^version:" packages/api-client/pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
  CURRENT_TS=$(grep '"version"' packages/api-client/package.json | sed -E 's/.*"version": *"([^"]+)".*/\1/')

  # 计算新版本
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_DART"
  case "$BUMP" in
    major)
      NEW_DART="$((MAJOR + 1)).0.0"
      ;;
    minor)
      NEW_DART="$MAJOR.$((MINOR + 1)).0"
      ;;
    patch)
      NEW_DART="$MAJOR.$MINOR.$((PATCH + 1))"
      ;;
  esac

  echo "==> [api-client] 新版本: $CURRENT_DART → $NEW_DART"

  # 更新 Dart 版本
  sed -i.bak "s/^version: $CURRENT_DART/version: $NEW_DART/" packages/api-client/pubspec.yaml
  rm -f packages/api-client/pubspec.yaml.bak

  # 更新 TS 版本
  sed -i.bak "s/\"version\": \"$CURRENT_TS\"/\"version\": \"$NEW_DART\"/" packages/api-client/package.json
  rm -f packages/api-client/package.json.bak

  echo "  ✓ pubspec.yaml: $CURRENT_DART → $NEW_DART"
  echo "  ✓ package.json: $CURRENT_TS → $NEW_DART"
}

run_design_tokens_bump() {
  if [ ! -f "packages/design-tokens/package.json" ]; then
    return 0
  fi

  CURRENT=$(grep '"version"' packages/design-tokens/package.json | sed -E 's/.*"version": *"([^"]+)".*/\1/')
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
  case "$BUMP" in
    major) NEW="$((MAJOR + 1)).0.0" ;;
    minor) NEW="$MAJOR.$((MINOR + 1)).0" ;;
    patch) NEW="$MAJOR.$MINOR.$((PATCH + 1))" ;;
  esac

  if [ "$CHECK_ONLY" = true ]; then
    echo "==> [design-tokens] current: $CURRENT (would bump to $NEW)"
    return 0
  fi

  sed -i.bak "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" packages/design-tokens/package.json
  rm -f packages/design-tokens/package.json.bak

  echo "==> [design-tokens] $CURRENT → $NEW"
}

# 跑各 scope
case "$SCOPE" in
  flutter) run_flutter_upgrade ;;
  react-native) run_react_native_upgrade ;;
  uniapp) run_uniapp_upgrade ;;
  api-client) run_api_client_bump ;;
  design-tokens) run_design_tokens_bump ;;
  all)
    run_flutter_upgrade
    run_react_native_upgrade
    run_uniapp_upgrade
    run_api_client_bump
    run_design_tokens_bump
    ;;
esac

echo ""
echo "==> 升级完成"
echo ""
echo "下一步："
echo "  1. 检查变更：git diff packages/ apps/"
echo "  2. 跑跨端检查：./tool/run_all_checks.sh"
echo "  3. 更新 CHANGELOG.md"
echo "  4. 提交："
echo "       git add -A"
echo "       git commit -m 'chore(deps): 升级 \$SCOPE 依赖'"
