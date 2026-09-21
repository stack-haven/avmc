#!/usr/bin/env bash
# gen_proto.sh
#
# 从 backend-service/proto 生成 Dart gRPC 客户端代码。
# 与 mobile-desktop-service/tooling/codegen/buf-gen-dart.yaml 配置配套使用。
#
# 用法：
#   ./tool/gen_proto.sh [output_dir] [proto_dir]
#
# 参数：
#   output_dir   生成代码输出目录（默认 lib/generated）
#   proto_dir    proto 文件源目录（默认 ../../../backend-service/proto）
#
# 环境变量：
#   PROTO_OUT    覆盖输出目录
#   PROTO_SRC    覆盖 proto 源目录
#
# 前置条件：
#   1. 已安装 buf CLI（https://buf.build/docs/installation）
#   2. backend-service/proto 与 mobile-desktop-service 在 monorepo 中
#
# 退出码：
#   0 成功
#   1 buf 未安装
#   2 proto 目录不存在
#   3 配置文件不存在

set -euo pipefail

OUTPUT_DIR=${PROTO_OUT:-${1:-lib/generated}}
PROTO_DIR=${PROTO_SRC:-${2:-../../../backend-service/proto}}

# 自动定位 monorepo 中的 proto 目录
if [ ! -d "$PROTO_DIR" ]; then
  # 尝试相对路径回退（mobile-desktop-service 子仓库结构）
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

# 校验 proto 目录
if [ ! -d "$PROTO_DIR" ]; then
  echo "Error: proto directory '$PROTO_DIR' not found" >&2
  echo "" >&2
  echo "Tried paths:" >&2
  echo "  - $PROTO_DIR" >&2
  echo "  - ../backend-service/proto" >&2
  echo "  - ../../backend-service/proto" >&2
  echo "  - ../../../backend-service/proto" >&2
  echo "" >&2
  echo "Set PROTO_SRC env var or pass proto_dir as 2nd arg" >&2
  exit 2
fi

# 校验 buf
if ! command -v buf &> /dev/null; then
  echo "Error: buf not installed" >&2
  echo "Install: https://buf.build/docs/installation" >&2
  exit 1
fi

# 校验 buf 配置
BUF_CONFIG="tooling/codegen/buf-gen-dart.yaml"
if [ ! -f "$BUF_CONFIG" ]; then
  echo "Error: buf config '$BUF_CONFIG' not found" >&2
  echo "" >&2
  echo "Expected location: <flutter_project>/tooling/codegen/buf-gen-dart.yaml" >&2
  echo "" >&2
  echo "buf-gen-dart.yaml template:" >&2
  cat << 'YAML' >&2
version: v1
plugins:
  - plugin: buf.build/protocolbuffers/dart
    out: lib/generated
  - plugin: buf.build/grpc/dart:v1
    out: lib/generated
YAML
  exit 3
fi

echo "==> Generating Dart proto code"
echo "    proto: $PROTO_DIR"
echo "    output: $OUTPUT_DIR"
echo "    config: $BUF_CONFIG"

mkdir -p "$OUTPUT_DIR"

cd "$PROTO_DIR"
buf generate --template "$(cd .. && pwd)/${BUF_CONFIG%/*}/buf-gen-dart.yaml" --output "$(cd .. && pwd)/$OUTPUT_DIR" || {
  # 回退：在 proto 目录直接生成
  buf generate --template "$BUF_CONFIG" --output "../$OUTPUT_DIR"
}
cd - > /dev/null

echo ""
echo "✓ Generated Dart proto code at $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "  1. 在 ${OUTPUT_DIR}/ 目录下查看生成的 .pb.dart 和 .pbgrpc.dart 文件"
echo "  2. 在 data/datasources/<feature>_remote_datasource.dart 中引用生成的 client"
echo "  3. 在 main.dart 中实例化 gRPC ClientChannel 并注入到 ProviderScope"
