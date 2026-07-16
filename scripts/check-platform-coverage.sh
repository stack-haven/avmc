#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend-service"
GOCACHE_DIR="${GOCACHE:-/private/tmp/avmc-go-cache}"
MIN_COVERAGE="${PLATFORM_ADMIN_COVERAGE_MIN:-45.0}"
COVER_PROFILE="$(mktemp "${TMPDIR:-/tmp}/avmc-platform-cover.XXXXXX")"

cleanup() {
  rm -f "${COVER_PROFILE}"
}
trap cleanup EXIT

PACKAGES=(
  ./app/platform/admin/internal/authzpolicy
  ./app/platform/admin/internal/biz
  ./app/platform/admin/internal/data
  ./app/platform/admin/internal/runtimeconfig
  ./app/platform/admin/internal/server
  ./app/platform/admin/internal/service
)

echo "Run platform admin coverage gate"
(
  cd "${BACKEND_DIR}"
  GOCACHE="${GOCACHE_DIR}" go test "${PACKAGES[@]}" -covermode=atomic -coverprofile="${COVER_PROFILE}"
)

TOTAL_COVERAGE="$(
  cd "${BACKEND_DIR}"
  GOCACHE="${GOCACHE_DIR}" go tool cover -func="${COVER_PROFILE}" |
    awk '/^total:/ { gsub("%", "", $3); print $3 }'
)"

awk -v got="${TOTAL_COVERAGE}" -v min="${MIN_COVERAGE}" 'BEGIN {
  if (got + 0 < min + 0) {
    printf("platform admin coverage %.1f%% is below required %.1f%%\n", got, min) > "/dev/stderr";
    exit 1;
  }
  printf("platform admin coverage %.1f%% >= %.1f%%\n", got, min);
}'
