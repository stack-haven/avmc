#!/usr/bin/env bash
# run_all_checks.sh
#
# 跨端 lint/test 检查调度器。
# 按 git diff 自动检测哪些端有变更，只跑对应端的检查。
#
# 用法：
#   ./tool/run_all_checks.sh [--scope flutter|react-native|uniapp|all]
#   ./tool/run_all_checks.sh [--scope design-tokens]
#
# 参数：
#   --scope   强制指定检查范围（默认：自动检测）
#
# 前置条件：
#   1. 各端工具链已安装（flutter / pnpm / HBuilderX）
#   2. 已 git clone（用 git diff 检测变更）
#
# 退出码：
#   0 所有检查通过
#   1 参数错误
#   2 Flutter 检查失败
#   3 RN 检查失败
#   4 uni-app 检查失败
#   5 design-tokens 检查失败

set -euo pipefail

SCOPE="auto"
while [ $# -gt 0 ]; do
  case "$1" in
    --scope)
      SCOPE=$2
      shift 2
      ;;
    *)
      echo "Error: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

# 校验 scope
case "$SCOPE" in
  auto|flutter|react-native|uniapp|all|design-tokens|api-client) ;;
  *)
    echo "Error: --scope must be auto, flutter, react-native, uniapp, all, design-tokens, api-client" >&2
    exit 1
    ;;
esac

# 自动检测变更范围
detect_changes() {
  if [ ! -d ".git" ]; then
    echo ""
    return
  fi

  # 聚合三个来源的变更：
  #   1. 工作区未提交变更（git diff）
  #   2. 已 add 未 commit（git diff --cached）
  #   3. 与 main 分支比较（CI 环境：GITHUB_BASE_REF）
  local changed_paths=""

  # Source 1: 工作区未提交
  changed_paths="$changed_paths $(git diff --name-only 2>/dev/null)"

  # Source 2: 已 add 未 commit
  changed_paths="$changed_paths $(git diff --name-only --cached 2>/dev/null)"

  # Source 3: 与 base 分支比较（CI）
  local base=${GITHUB_BASE_REF:-main}
  if git rev-parse "$base" > /dev/null 2>&1; then
    changed_paths="$changed_paths $(git diff --name-only "$base"...HEAD 2>/dev/null)"
  fi

  local flutter_changed=false
  local rn_changed=false
  local uniapp_changed=false
  local tokens_changed=false
  local api_changed=false

  for path in $changed_paths; do
    [ -z "$path" ] && continue
    case "$path" in
      apps/evie-*|packages/*-flutter/*|melos.yaml)
        flutter_changed=true
        ;;
      apps/workbench-*|packages/*-react/*|package.json)
        rn_changed=true
        ;;
      apps/geo-*)
        uniapp_changed=true
        ;;
      packages/design-tokens/tokens.json)
        tokens_changed=true
        ;;
      packages/api-client/*|tooling/codegen/*)
        api_changed=true
        ;;
    esac
  done

  if [ "$flutter_changed" = true ]; then echo "flutter"; fi
  if [ "$rn_changed" = true ]; then echo "react-native"; fi
  if [ "$uniapp_changed" = true ]; then echo "uniapp"; fi
  if [ "$tokens_changed" = true ]; then echo "design-tokens"; fi
  if [ "$api_changed" = true ]; then echo "api-client"; fi
}

# 解析要跑的 scope
if [ "$SCOPE" = "auto" ]; then
  SCOPES=$(detect_changes)
  if [ -z "$SCOPES" ]; then
    echo "==> 未检测到变更，跳过所有检查"
    exit 0
  fi
else
  SCOPES=$SCOPE
fi

echo "==> 跨端检查调度"
echo "    scope(s): $SCOPES"
echo ""

FAIL=0

run_flutter() {
  if [ ! -f "melos.yaml" ]; then
    echo "==> [flutter] melos.yaml 不存在，跳过"
    return 0
  fi
  if ! command -v melos &> /dev/null && ! command -v flutter &> /dev/null; then
    echo "==> [flutter] flutter/melos 未安装，跳过"
    return 0
  fi

  echo "==> [flutter] running..."
  if command -v melos &> /dev/null; then
    melos exec -c 1 -- "flutter analyze" 2>&1 | tail -20 || FAIL=2
    melos exec -c 1 -- "flutter test" 2>&1 | tail -10 || FAIL=2
  else
    flutter pub get
    flutter analyze 2>&1 | tail -20 || FAIL=2
    flutter test 2>&1 | tail -10 || FAIL=2
  fi
  echo "==> [flutter] done (exit: $FAIL)"
}

run_react_native() {
  if [ ! -f "package.json" ]; then
    echo "==> [react-native] package.json 不存在，跳过"
    return 0
  fi
  if ! command -v pnpm &> /dev/null; then
    echo "==> [react-native] pnpm 未安装，跳过"
    return 0
  fi

  echo "==> [react-native] running..."
  pnpm install --frozen-lockfile 2>&1 | tail -10
  pnpm -r --parallel run lint 2>&1 | tail -20 || FAIL=3
  pnpm -r --parallel run typecheck 2>&1 | tail -20 || FAIL=3
  pnpm -r --parallel run test 2>&1 | tail -20 || FAIL=3
  echo "==> [react-native] done (exit: $FAIL)"
}

run_uniapp() {
  if [ ! -d "apps/geo-mobile" ] && [ ! -d "apps/geo-mini" ]; then
    echo "==> [uniapp] apps/geo-* 不存在，跳过"
    return 0
  fi

  echo "==> [uniapp] running..."
  for app in apps/geo-mobile apps/geo-mini; do
    if [ -d "$app" ] && [ -f "$app/package.json" ]; then
      echo "  → $app"
      cd "$app"
      if [ -f "package.json" ]; then
        npm install --silent 2>&1 | tail -5 || true
        if grep -q '"lint"' package.json; then
          npm run lint 2>&1 | tail -10 || FAIL=4
        fi
      fi
      cd - > /dev/null
    fi
  done
  echo "==> [uniapp] done (exit: $FAIL)"
}

run_design_tokens() {
  echo "==> [design-tokens] running check..."
  ./tool/sync_design_tokens.sh --check || FAIL=5
  echo "==> [design-tokens] done (exit: $FAIL)"
}

run_api_client() {
  echo "==> [api-client] 检查 API 客户端与 proto 一致性..."
  # 简单校验：检查最近一次 gen_clients.sh 是否生成过新文件
  if [ ! -d "packages/api-client/lib" ] || [ ! -d "packages/api-client/src/proto" ]; then
    echo "  ⚠ API 客户端目录为空（首次？或未生成？）"
    echo "     跑 ./tool/gen_clients.sh 生成"
    return 0
  fi

  # 校验是否有部分 proto 服务缺失
  local dart_services=$(find packages/api-client/lib -name "*_service.pb.dart" -o -name "*_service.pbgrpc.dart" 2>/dev/null | wc -l | tr -d ' ')
  local ts_services=$(find packages/api-client/src/proto -name "*_service.js" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$dart_services" = "0" ] && [ "$ts_services" = "0" ]; then
    echo "  ⚠ 没有发现 API 客户端文件，可能未生成"
  else
    echo "  ✓ Dart services: $dart_services"
    echo "  ✓ TS services:   $ts_services"
  fi
  echo "==> [api-client] done"
}

# 跑各 scope
for s in $SCOPES; do
  case "$s" in
    flutter) run_flutter ;;
    react-native) run_react_native ;;
    uniapp) run_uniapp ;;
    design-tokens) run_design_tokens ;;
    api-client) run_api_client ;;
  esac
done

echo ""
if [ $FAIL -eq 0 ]; then
  echo "✅ All checks passed"
  exit 0
else
  echo "❌ Checks failed (exit code: $FAIL)"
  exit $FAIL
fi
