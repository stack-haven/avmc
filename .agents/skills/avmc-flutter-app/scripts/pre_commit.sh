#!/usr/bin/env bash
# pre_commit.sh
#
# Flutter 项目提交前检查（基于 very_good_cli 哲学：约定优于配置）。
# 必跑：format check + analyze + test coverage。
#
# 用法：
#   ./tool/pre_commit.sh [--fix]
#
# 参数：
#   --fix   自动修复格式问题（dart format .）和代码生成（build_runner build）
#
# 退出码：
#   0 全部通过
#   1 format 不通过
#   2 analyze 不通过
#   3 test 不通过
#   4 coverage 低于门禁

set -euo pipefail

FIX=false
if [ "${1:-}" = "--fix" ]; then
  FIX=true
fi

# 校验在 Flutter 项目根目录
if [ ! -f "pubspec.yaml" ]; then
  echo "Error: pubspec.yaml not found. Run from Flutter project root." >&2
  exit 1
fi

if [ ! -f "analysis_options.yaml" ]; then
  echo "Error: analysis_options.yaml not found." >&2
  exit 1
fi

# 校验依赖已安装
if [ ! -d ".dart_tool" ]; then
  echo "==> Installing dependencies..."
  flutter pub get
fi

FAIL=0

# 1. 格式检查
echo "==> [1/4] Format check..."
if ! dart format --output=none --set-exit-if-changed . 2>&1; then
  echo "  ❌ Format check failed" >&2
  if [ "$FIX" = true ]; then
    echo "  → 自动修复：dart format ."
    dart format .
  else
    echo "  → 运行 ./tool/pre_commit.sh --fix 自动修复" >&2
    FAIL=1
  fi
else
  echo "  ✓ Format OK"
fi

# 2. 静态分析
echo ""
echo "==> [2/4] Static analysis (very_good_analysis)..."
if ! flutter analyze 2>&1; then
  echo "  ❌ Analyze failed" >&2
  FAIL=2
else
  echo "  ✓ Analyze OK"
fi

# 3. 测试
echo ""
echo "==> [3/4] Tests..."
if ! flutter test --reporter expanded 2>&1; then
  echo "  ❌ Tests failed" >&2
  FAIL=3
else
  echo "  ✓ Tests OK"
fi

# 4. 覆盖率门禁（默认 45%，与 backend-service 对齐）
echo ""
echo "==> [4/4] Coverage check (threshold: 45%)..."
COVERAGE_FILE="coverage/lcov.info"
if flutter test --coverage 2>&1; then
  if [ -f "$COVERAGE_FILE" ]; then
    # 用 lcov 统计行覆盖率
    LINES_FOUND=$(grep -c "^DA:" "$COVERAGE_FILE" 2>/dev/null || echo 0)
    LINES_HIT=$(grep "^DA:" "$COVERAGE_FILE" 2>/dev/null | awk -F, '{ if ($2 > 0) print }' | wc -l | tr -d ' ' || echo 0)
    if [ "$LINES_FOUND" -gt 0 ]; then
      COVERAGE=$(awk -v hit="$LINES_HIT" -v total="$LINES_FOUND" 'BEGIN { printf "%.1f", (hit/total)*100 }')
      echo "  Coverage: ${COVERAGE}%"
      IS_BELOW=$(awk -v c="$COVERAGE" 'BEGIN { print (c < 45) ? 1 : 0 }')
      if [ "$IS_BELOW" = "1" ]; then
        echo "  ❌ Coverage ${COVERAGE}% < 45%" >&2
        FAIL=4
      else
        echo "  ✓ Coverage OK"
      fi
    else
      echo "  ⚠ No coverage data found"
    fi
  else
    echo "  ⚠ Coverage file not generated"
  fi
else
  echo "  ❌ Tests with coverage failed" >&2
  FAIL=3
fi

# 5. 架构合规检查
echo ""
echo "==> [5/5] Architecture check (optional, requires ./tool/check_architecture.sh)..."
if [ -x "./tool/check_architecture.sh" ]; then
  if ./tool/check_architecture.sh 2>&1; then
    echo "  ✓ Architecture OK"
  else
    echo "  ❌ Architecture check failed" >&2
    FAIL=1
  fi
else
  echo "  ⚠ check_architecture.sh not found, skipping"
fi

echo ""
if [ $FAIL -eq 0 ]; then
  echo "✅ All pre-commit checks passed"
  exit 0
else
  echo "❌ Pre-commit checks failed (exit code: $FAIL)"
  exit $FAIL
fi
