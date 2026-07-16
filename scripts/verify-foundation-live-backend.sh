#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend-service"
ADMIN_DIR="${BACKEND_DIR}/app/platform/admin"
GOCACHE_DIR="${GOCACHE:-/private/tmp/avmc-go-cache}"
FIRST_MOCK_LOG="$(mktemp "${TMPDIR:-/tmp}/avmc-mock-first.XXXXXX")"
SECOND_MOCK_LOG="$(mktemp "${TMPDIR:-/tmp}/avmc-mock-second.XXXXXX")"
FIRST_COUNTS="$(mktemp "${TMPDIR:-/tmp}/avmc-mock-first-counts.XXXXXX")"
SECOND_COUNTS="$(mktemp "${TMPDIR:-/tmp}/avmc-mock-second-counts.XXXXXX")"

cleanup() {
  rm -f "${FIRST_MOCK_LOG}" "${SECOND_MOCK_LOG}" "${FIRST_COUNTS}" "${SECOND_COUNTS}"
}
trap cleanup EXIT

echo "[1/4] Run platform admin database migration"
(
  cd "${ADMIN_DIR}"
  GOCACHE="${GOCACHE_DIR}" go run ./cmd/migrate -conf ./configs
)

echo "[2/4] Seed and verify platform admin mock data"
(
  cd "${ADMIN_DIR}"
  GOCACHE="${GOCACHE_DIR}" go run ./cmd/mock -conf ./configs
) | tee "${FIRST_MOCK_LOG}"

echo "[3/4] Re-run mock seed and compare verification output"
(
  cd "${ADMIN_DIR}"
  GOCACHE="${GOCACHE_DIR}" go run ./cmd/mock -conf ./configs
) | tee "${SECOND_MOCK_LOG}"

grep '^verified ' "${FIRST_MOCK_LOG}" >"${FIRST_COUNTS}"
grep '^verified ' "${SECOND_MOCK_LOG}" >"${SECOND_COUNTS}"
if ! diff -u "${FIRST_COUNTS}" "${SECOND_COUNTS}"; then
  echo "mock verification output changed between consecutive runs" >&2
  exit 1
fi

echo "[4/4] Verify Redis-backed tenant authorization cache"
(
  cd "${BACKEND_DIR}"
  GOCACHE="${GOCACHE_DIR}" go test -tags=integration ./app/platform/admin/internal/data -run '^TestTenantAuthorizationCacheWithRedisVersions$'
)

echo "Foundation backend live verification passed."
