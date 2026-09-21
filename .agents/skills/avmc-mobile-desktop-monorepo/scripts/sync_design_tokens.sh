#!/usr/bin/env bash
# sync_design_tokens.sh
#
# 把 packages/design-tokens/tokens.json 同步生成各端代码。
# - Dart:    packages/design-tokens/lib/theme.dart
# - TS:      packages/design-tokens/src/theme.ts
# - SCSS:    packages/design-tokens/src/theme.scss
#
# 用法：
#   ./tool/sync_design_tokens.sh [--check]
#
# 参数：
#   --check   只检查是否有变更，不实际生成（CI 用）
#
# 前置条件：
#   1. 已安装 Node.js（npm/npx）
#   2. style-dictionary 通过 npx 调用（自动下载）
#
# 退出码：
#   0 成功
#   1 参数错误
#   2 style-dictionary 配置缺失
#   3 tokens.json 缺失

set -euo pipefail

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=true
fi

# 校验依赖
if [ ! -f "packages/design-tokens/tokens.json" ]; then
  echo "Error: packages/design-tokens/tokens.json not found" >&2
  echo "Run ./tool/init_monorepo.sh first" >&2
  exit 3
fi

if [ ! -f "tooling/codegen/style-dictionary.config.json" ]; then
  echo "Error: tooling/codegen/style-dictionary.config.json not found" >&2
  exit 2
fi

# 校验 Node.js / npx
if ! command -v npx &> /dev/null; then
  echo "Error: npx not found. Install Node.js >= 16." >&2
  exit 1
fi

# 校验 JSON 格式
if ! python3 -c "import json; json.load(open('packages/design-tokens/tokens.json'))" 2>/dev/null; then
  echo "Error: packages/design-tokens/tokens.json is not valid JSON" >&2
  exit 1
fi

if [ "$CHECK_ONLY" = true ]; then
  echo "==> [CHECK MODE] 仅检查变更，不实际生成"
fi

echo "==> 同步设计令牌到各端"
echo "    source:   packages/design-tokens/tokens.json"
echo "    config:   tooling/codegen/style-dictionary.config.json"
echo ""

# 记录生成前的文件状态
declare -A BEFORE_HASH
for f in \
  "packages/design-tokens/lib/theme.dart" \
  "packages/design-tokens/src/theme.ts" \
  "packages/design-tokens/src/theme.scss"; do
  if [ -f "$f" ]; then
    BEFORE_HASH[$f]=$(md5 -q "$f" 2>/dev/null || shasum -a 256 "$f" | awk '{print $1}')
  else
    BEFORE_HASH[$f]="(not exist)"
  fi
done

# 跑 style-dictionary
if [ "$CHECK_ONLY" = true ]; then
  # --check 模式：先生成到临时目录，对比
  TEMP_DIR=$(mktemp -d)
  cp -r packages/design-tokens "$TEMP_DIR/"

  cd "$TEMP_DIR/design-tokens"
  npx --yes style-dictionary build \
    --config "$(cd ../../../ && pwd)/tooling/codegen/style-dictionary.config.json" \
    > /tmp/style-dictionary.log 2>&1 || {
      echo "Error: style-dictionary failed" >&2
      cat /tmp/style-dictionary.log >&2
      cd - > /dev/null
      rm -rf "$TEMP_DIR"
      exit 4
    }
  cd - > /dev/null

  # 对比
  CHANGED=0
  for f in lib/theme.dart src/theme.ts src/theme.scss; do
    SRC="$TEMP_DIR/design-tokens/$f"
    DST="packages/design-tokens/$f"
    if [ ! -f "$SRC" ]; then
      continue
    fi
    if [ ! -f "$DST" ]; then
      echo "  ❌ $f: 缺失（应自动生成）"
      CHANGED=$((CHANGED + 1))
    elif ! diff -q "$SRC" "$DST" > /dev/null 2>&1; then
      echo "  ❌ $f: 与 tokens.json 不一致"
      echo "     修复：跑 ./tool/sync_design_tokens.sh（不带 --check）"
      CHANGED=$((CHANGED + 1))
    fi
  done

  rm -rf "$TEMP_DIR"

  if [ $CHANGED -gt 0 ]; then
    echo ""
    echo "✗ $CHANGED file(s) out of sync"
    exit 1
  fi
  echo ""
  echo "✅ All design tokens are in sync"
  exit 0
fi

# 实际生成
npx --yes style-dictionary build \
  --config tooling/codegen/style-dictionary.config.json \
  > /tmp/style-dictionary.log 2>&1 || {
    echo "Error: style-dictionary failed" >&2
    cat /tmp/style-dictionary.log >&2
    exit 4
  }

# 输出 diff 摘要
echo ""
echo "==> Diff summary:"

CHANGED=0
for f in \
  "packages/design-tokens/lib/theme.dart" \
  "packages/design-tokens/src/theme.ts" \
  "packages/design-tokens/src/theme.scss"; do
  if [ ! -f "$f" ]; then
    echo "  (new)  $f"
    CHANGED=$((CHANGED + 1))
    continue
  fi
  AFTER=$(md5 -q "$f" 2>/dev/null || shasum -a 256 "$f" | awk '{print $1}')
  if [ "${BEFORE_HASH[$f]:-(not exist)}" != "$AFTER" ]; then
    echo "  (mod)  $f"
    CHANGED=$((CHANGED + 1))
  else
    echo "  (same) $f"
  fi
done

# 格式化生成的 Dart 文件
if [ -f "packages/design-tokens/lib/theme.dart" ] && command -v dart &> /dev/null; then
  dart format packages/design-tokens/lib/theme.dart > /dev/null 2>&1 || true
fi

# 格式化生成的 TS 文件
if [ -f "packages/design-tokens/src/theme.ts" ] && command -v npx &> /dev/null; then
  npx --yes prettier --write packages/design-tokens/src/theme.ts > /dev/null 2>&1 || true
fi

echo ""
if [ $CHANGED -gt 0 ]; then
  echo "✅ Design tokens 同步完成（$CHANGED 个文件变更）"
  echo ""
  echo "下一步："
  echo "  1. 检查变更：git diff packages/design-tokens/"
  echo "  2. 跑跨端检查：./tool/run_all_checks.sh"
  echo "  3. 提交："
  echo "       git add packages/design-tokens/"
  echo "       git commit -m 'style(tokens): 同步设计令牌'"
else
  echo "✅ Design tokens 已同步（无变更）"
fi
