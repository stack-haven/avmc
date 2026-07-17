#!/usr/bin/env bash

set -euo pipefail

HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:8000/health/ready}"
MAX_EXCEEDED_RATE="${RESOURCE_QUOTA_MAX_EXCEEDED_RATE:-1}"
MAX_CONFLICT_RATE="${RESOURCE_QUOTA_MAX_CONFLICT_RATE:-0.05}"

response="${HEALTH_BODY:-}"
if [[ -z "${response}" ]]; then
  response="$(curl -fsS "${HEALTH_URL}")"
fi

HEALTH_BODY="${response}" \
MAX_EXCEEDED_RATE="${MAX_EXCEEDED_RATE}" \
MAX_CONFLICT_RATE="${MAX_CONFLICT_RATE}" \
node <<'NODE'
const body = JSON.parse(process.env.HEALTH_BODY || '{}');
const maxExceededRate = Number(process.env.MAX_EXCEEDED_RATE);
const maxConflictRate = Number(process.env.MAX_CONFLICT_RATE);

function fail(message) {
  console.error(message);
  process.exit(1);
}

function numeric(payload, key) {
  const value = Number(payload[key]);
  if (!Number.isFinite(value) || value < 0) {
    fail(`resource_quota.${key} must be a non-negative number: ${payload[key]}`);
  }
  return value;
}

function rateThreshold(name, value) {
  if (!Number.isFinite(value) || value < 0 || value > 1) {
    fail(`${name} must be a number between 0 and 1: ${value}`);
  }
}

if (body.status !== 'ok') {
  fail(`readiness status is ${JSON.stringify(body.status)}, want "ok"`);
}

const quota = body.details && body.details.resource_quota;
if (!quota || typeof quota !== 'object') {
  fail('readiness details.resource_quota is missing');
}

rateThreshold('RESOURCE_QUOTA_MAX_EXCEEDED_RATE', maxExceededRate);
rateThreshold('RESOURCE_QUOTA_MAX_CONFLICT_RATE', maxConflictRate);

const consumes = numeric(quota, 'consumes');
const releases = numeric(quota, 'releases');
const mutations = numeric(quota, 'mutations');
const quotaExceeded = numeric(quota, 'quota_exceeded');
const idempotencyConflicts = numeric(quota, 'idempotency_conflicts');
const exceededRate = numeric(quota, 'exceeded_rate');
const conflictRate = numeric(quota, 'conflict_rate');

if (mutations !== consumes + releases) {
  fail(`resource_quota.mutations ${mutations} does not equal consumes+releases ${consumes + releases}`);
}
if (quotaExceeded > consumes) {
  fail(`resource_quota.quota_exceeded ${quotaExceeded} exceeds consumes ${consumes}`);
}
if (idempotencyConflicts > mutations) {
  fail(`resource_quota.idempotency_conflicts ${idempotencyConflicts} exceeds mutations ${mutations}`);
}
if (exceededRate > maxExceededRate) {
  fail(`resource quota exceeded_rate ${exceededRate} exceeds max ${maxExceededRate}`);
}
if (conflictRate > maxConflictRate) {
  fail(`resource quota conflict_rate ${conflictRate} exceeds max ${maxConflictRate}`);
}

console.log(`resource quota health ok: exceeded_rate=${exceededRate} conflict_rate=${conflictRate}`);
NODE
