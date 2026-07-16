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
SERVER_LOG="$(mktemp "${TMPDIR:-/tmp}/avmc-platform-admin-server.XXXXXX")"
SERVER_PID=""

cleanup() {
  if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" >/dev/null 2>&1; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
  rm -f "${FIRST_MOCK_LOG}" "${SECOND_MOCK_LOG}" "${FIRST_COUNTS}" "${SECOND_COUNTS}" "${SERVER_LOG}"
}
trap cleanup EXIT

echo "[1/5] Run platform admin database migration"
(
  cd "${ADMIN_DIR}"
  GOCACHE="${GOCACHE_DIR}" go run ./cmd/migrate -conf ./configs
)

echo "[2/5] Seed and verify platform admin mock data"
(
  cd "${ADMIN_DIR}"
  GOCACHE="${GOCACHE_DIR}" go run ./cmd/mock -conf ./configs
) | tee "${FIRST_MOCK_LOG}"

echo "[3/5] Re-run mock seed and compare verification output"
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

echo "[4/5] Verify Redis-backed tenant authorization cache"
(
  cd "${BACKEND_DIR}"
  GOCACHE="${GOCACHE_DIR}" go test -tags=integration ./app/platform/admin/internal/data -run '^TestTenantAuthorizationCacheWithRedisVersions$'
)

echo "[5/5] Verify service readiness and authorization cache health"
(
  cd "${ADMIN_DIR}"
  GOCACHE="${GOCACHE_DIR}" go run ./cmd/server -conf ./configs
) >"${SERVER_LOG}" 2>&1 &
SERVER_PID=$!

readiness_output=""
ready=0
for _ in {1..30}; do
  if ! kill -0 "${SERVER_PID}" >/dev/null 2>&1; then
    cat "${SERVER_LOG}" >&2
    echo "platform admin server exited before readiness check passed" >&2
    exit 1
  fi
  if readiness_output="$(HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:8000/health/ready}" "${ROOT_DIR}/scripts/check-authorization-cache-health.sh" 2>&1)"; then
    echo "${readiness_output}"
    ready=1
    break
  fi
  sleep 1
done

if [[ "${ready}" != "1" ]]; then
  cat "${SERVER_LOG}" >&2
  if [[ -n "${readiness_output}" ]]; then
    echo "${readiness_output}" >&2
  fi
  echo "platform admin readiness check did not pass within 30 seconds" >&2
  exit 1
fi

echo "Foundation backend live verification passed."
