#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend-service"
FRONTEND_DIR="${ROOT_DIR}/frontend-service"

echo "[1/7] Build protobuf contracts"
(
  cd "${BACKEND_DIR}/proto"
  buf build
)

echo "[2/7] Check protobuf lint baseline"
"${BACKEND_DIR}/scripts/check-buf-lint-baseline.sh"

echo "[3/7] Test platform backend"
(
  cd "${BACKEND_DIR}"
  GOCACHE="${GOCACHE:-/private/tmp/avmc-go-cache}" \
    go test ./pkg/auth ./app/platform/admin/...
)

echo "[4/7] Check backend diff formatting"
git -C "${BACKEND_DIR}" diff --check

echo "[5/7] Check Sass compiler selection"
if (
  cd "${FRONTEND_DIR}"
  node -e "require.resolve('sass-embedded', { paths: ['internal/vite-config'] })"
) >/dev/null 2>&1; then
  echo "sass-embedded must not be resolvable from @vben/vite-config" >&2
  exit 1
fi
(
  cd "${FRONTEND_DIR}"
  node -e "require.resolve('sass', { paths: ['internal/vite-config'] })"
)

echo "[6/7] Type-check admin frontend"
(
  cd "${FRONTEND_DIR}"
  pnpm --filter @vben/web-antd-admin typecheck
)

echo "[7/7] Build admin frontend"
(
  cd "${FRONTEND_DIR}"
  pnpm --filter @vben/web-antd-admin build
)

echo "Foundation static verification passed."
