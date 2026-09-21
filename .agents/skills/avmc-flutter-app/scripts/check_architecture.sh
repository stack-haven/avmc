#!/usr/bin/env bash
# check_architecture.sh
#
# 检查 Flutter 项目 feature-first + 三层架构的合规性。
# 校验每个 feature 是否有完整 data / domain / application / presentation 层，
# 检查是否有跨层非法依赖。
#
# 用法：
#   ./tool/check_architecture.sh [features_dir]
#
# 参数：
#   features_dir   features 目录路径（默认 lib/features）
#
# 退出码：
#   0 所有 feature 架构合规
#   1 缺层 / 跨层非法依赖
#   2 features 目录不存在

set -euo pipefail

FEATURES_DIR=${1:-lib/features}

# 校验 features 目录存在
if [ ! -d "$FEATURES_DIR" ]; then
  echo "Error: features directory '$FEATURES_DIR' does not exist" >&2
  exit 2
fi

echo "==> Check 1: 每个 feature 必须有完整的四层目录结构"

REQUIRED_LAYERS=(
  "data/datasources"
  "data/models"
  "data/repositories"
  "domain/entities"
  "domain/repositories"
  "domain/usecases"
  "application/providers"
  "application/states"
  "presentation/pages"
  "presentation/widgets"
)

MISSING=0
for feature_dir in "$FEATURES_DIR"/*/; do
  [ -d "$feature_dir" ] || continue
  feature=$(basename "$feature_dir")

  for layer in "${REQUIRED_LAYERS[@]}"; do
    if [ ! -d "$feature_dir$layer" ]; then
      echo "  ❌ $feature: 缺少 $layer/"
      MISSING=$((MISSING + 1))
    fi
  done

  # 每个 feature 必须有 barrel file
  if [ ! -f "$feature_dir$feature.dart" ]; then
    echo "  ❌ $feature: 缺少 barrel file ${feature}.dart"
    MISSING=$((MISSING + 1))
  fi

  # domain 层不能 import data 层或 application 层
  if [ -d "$feature_dir/domain" ]; then
    if grep -rn "import.*data/" "$feature_dir/domain/" 2>/dev/null | grep -v "// ignore" > /dev/null; then
      echo "  ❌ $feature/domain: 不允许 import data/ 层"
      MISSING=$((MISSING + 1))
    fi
    if grep -rn "import.*application/" "$feature_dir/domain/" 2>/dev/null | grep -v "// ignore" > /dev/null; then
      echo "  ❌ $feature/domain: 不允许 import application/ 层"
      MISSING=$((MISSING + 1))
    fi
  fi

  # data 层不允许 import application 层或 presentation 层
  if [ -d "$feature_dir/data" ]; then
    if grep -rn "import.*application/" "$feature_dir/data/" 2>/dev/null | grep -v "// ignore" > /dev/null; then
      echo "  ❌ $feature/data: 不允许 import application/ 层"
      MISSING=$((MISSING + 1))
    fi
    if grep -rn "import.*presentation/" "$feature_dir/data/" 2>/dev/null | grep -v "// ignore" > /dev/null; then
      echo "  ❌ $feature/data: 不允许 import presentation/ 层"
      MISSING=$((MISSING + 1))
    fi
  fi

  # application 层不允许 import presentation 层
  if [ -d "$feature_dir/application" ]; then
    if grep -rn "import.*presentation/" "$feature_dir/application/" 2>/dev/null | grep -v "// ignore" > /dev/null; then
      echo "  ❌ $feature/application: 不允许 import presentation/ 层"
      MISSING=$((MISSING + 1))
    fi
  fi
done

if [ $MISSING -gt 0 ]; then
  echo ""
  echo "✗ Architecture check failed: $MISSING issue(s) found"
  exit 1
fi
echo "  ✓ 所有 feature 架构合规"

echo ""
echo "==> Check 2: 每个 feature 必须有对应的 test/features/<name>/ 目录"

MISSING_TESTS=0
for feature_dir in "$FEATURES_DIR"/*/; do
  [ -d "$feature_dir" ] || continue
  feature=$(basename "$feature_dir")
  test_dir="test/features/$feature"
  if [ ! -d "$test_dir" ]; then
    echo "  ❌ $feature: 缺少 test/features/$feature/"
    MISSING_TESTS=$((MISSING_TESTS + 1))
  fi
done

if [ $MISSING_TESTS -gt 0 ]; then
  echo ""
  echo "✗ Test directory check failed: $MISSING_TESTS feature(s) missing tests"
  exit 1
fi
echo "  ✓ 所有 feature 都有 test 目录"

echo ""
echo "==> Check 3: very_good_analysis 必须启用"

if [ -f "analysis_options.yaml" ]; then
  if grep -q "very_good_analysis" "analysis_options.yaml"; then
    echo "  ✓ analysis_options.yaml 已包含 very_good_analysis"
  else
    echo "  ❌ analysis_options.yaml 未引用 very_good_analysis"
    echo "     修复：在 include 列表加入 package:very_good_analysis/analysis_options.yaml"
    exit 1
  fi
else
  echo "  ❌ analysis_options.yaml 不存在"
  exit 1
fi

echo ""
echo "✅ Flutter architecture check passed"
