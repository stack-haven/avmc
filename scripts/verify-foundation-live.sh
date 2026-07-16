#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="${ROOT_DIR}/frontend-service"

echo "[1/2] Run backend live verification"
"${ROOT_DIR}/scripts/verify-foundation-live-backend.sh"

echo "[2/2] Run admin frontend E2E against real backend"
(
  cd "${FRONTEND_DIR}"
  pnpm --filter @vben/web-antd-admin test:e2e
)

echo "Foundation live verification passed."
