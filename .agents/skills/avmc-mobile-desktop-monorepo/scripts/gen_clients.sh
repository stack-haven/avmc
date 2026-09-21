#!/usr/bin/env bash
# gen_clients.sh
#
# 从 backend-service/proto 生成跨端 API 客户端。
# 输出到 packages/api-client/ 下的 Dart 和 TypeScript 目录。
#
# 用法：
#   ./tool/gen_clients.sh [--proto-dir <path>] [--scope dart|ts|all]
#
# 参数：
#   --proto-dir   proto 源目录（默认自动定位 monorepo 中的 backend-service/proto）
#   --scope       生成范围：dart（Dart 客户端）/ ts（TypeScript 客户端）/ all（两者）
#
# 前置条件：
#   1. 已安装 buf CLI（https://buf.build/docs/installation）
#   2. backend-service/proto 存在
#
# 退出码：
#   0 成功
#   1 参数错误
#   2 buf 未安装
#   3 proto 目录不存在
#   4 生成失败

set -euo pipefail

PROTO_DIR=""
SCOPE="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --proto-dir)
      PROTO_DIR=$2
      shift 2
      ;;
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
if [[ "$SCOPE" != "dart" && "$SCOPE" != "ts" && "$SCOPE" != "all" ]]; then
  echo "Error: --scope must be 'dart', 'ts', or 'all'" >&2
  exit 1
fi

# 校验 buf
if ! command -v buf &> /dev/null; then
  echo "Error: buf not installed" >&2
  echo "Install: https://buf.build/docs/installation" >&2
  exit 2
fi

# 自动定位 proto 目录
if [ -z "$PROTO_DIR" ]; then
  for candidate in \
    "../backend-service/proto" \
    "../../backend-service/proto" \
    "../../../backend-service/proto"; do
    if [ -d "$candidate" ]; then
      PROTO_DIR=$candidate
      break
    fi
  done
fi

if [ -z "$PROTO_DIR" ] || [ ! -d "$PROTO_DIR" ]; then
  echo "Error: proto directory not found" >&2
  echo "" >&2
  echo "Tried paths:" >&2
  echo "  - ../backend-service/proto" >&2
  echo "  - ../../backend-service/proto" >&2
  echo "  - ../../../backend-service/proto" >&2
  echo "" >&2
  echo "Set --proto-dir or PROTO_SRC env var" >&2
  exit 3
fi

# 校验输出目录存在
mkdir -p packages/api-client/lib packages/api-client/src/proto

# 选择配置文件
case "$SCOPE" in
  dart)
    CONFIG="tooling/codegen/buf-gen-dart.yaml"
    ;;
  ts)
    CONFIG="tooling/codegen/buf-gen-ts.yaml"
    ;;
  all)
    CONFIG="tooling/codegen/buf.gen.yaml"
    ;;
esac

if [ ! -f "$CONFIG" ]; then
  echo "Error: buf config '$CONFIG' not found" >&2
  echo "Run ./tool/init_monorepo.sh first" >&2
  exit 3
fi

echo "==> 生成跨端 API 客户端"
echo "    proto:    $PROTO_DIR"
echo "    config:   $CONFIG"
echo "    scope:    $SCOPE"

# 记录生成前后的文件数（用于 diff 摘要）
BEFORE_DART=$(find packages/api-client/lib -name "*.dart" 2>/dev/null | wc -l | tr -d ' ')
BEFORE_TS=$(find packages/api-client/src/proto -name "*.js" 2>/dev/null | wc -l | tr -d ' ')

# 跑 buf generate
cd "$PROTO_DIR"

# buf generate 需要 --template 和 --output
case "$SCOPE" in
  dart)
    buf generate --template "$(cd .. && pwd)/$CONFIG" \
      --output "$(cd .. && pwd)/packages/api-client/lib" 2>&1
    ;;
  ts)
    buf generate --template "$(cd .. && pwd)/$CONFIG" \
      --output "$(cd .. && pwd)/packages/api-client/src" 2>&1
    ;;
  all)
    # buf.gen.yaml 同时输出到多个目录（plugins 各自指定 out）
    buf generate --template "$(cd .. && pwd)/$CONFIG" 2>&1
    ;;
esac

cd - > /dev/null

# 计算 diff
AFTER_DART=$(find packages/api-client/lib -name "*.dart" 2>/dev/null | wc -l | tr -d ' ')
AFTER_TS=$(find packages/api-client/src/proto -name "*.js" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "==> 生成完成"
echo ""
echo "Diff summary:"
echo "  Dart:  $BEFORE_DART → $AFTER_DART files"
echo "  TS:    $BEFORE_TS → $AFTER_TS files"
echo ""
echo "新生成的文件（按类型）："
find packages/api-client/lib -name "*.pb.dart" -newer "$CONFIG" 2>/dev/null | head -10 | sed 's|^|  Dart: |'
find packages/api-client/lib -name "*.pbgrpc.dart" -newer "$CONFIG" 2>/dev/null | head -10 | sed 's|^|  Dart: |'
find packages/api-client/src/proto -name "*.js" -newer "$CONFIG" 2>/dev/null | head -10 | sed 's|^|  TS:   |'
find packages/api-client/src/proto -name "*.d.ts" -newer "$CONFIG" 2>/dev/null | head -10 | sed 's|^|  TS:   |'

echo ""
echo "下一步："
echo "  1. 检查生成的客户端（特别注意 breaking change）"
echo "  2. 各 apps/ 升级 api-client 版本（如有变化）："
echo "       ./tool/upgrade_dependencies.sh --scope api-client"
echo "  3. 跑回归测试："
echo "       ./tool/run_all_checks.sh"
echo "  4. 提交（记得把 packages/api-client/ 也 commit）"
