#!/usr/bin/env bash

set -euo pipefail

HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:8000/health/ready}"
MAX_BYPASS_RATE="${AUTHZ_CACHE_MAX_BYPASS_RATE:-0.05}"
MIN_HIT_RATE="${AUTHZ_CACHE_MIN_HIT_RATE:-0}"

response="$(curl -fsS "${HEALTH_URL}")"

HEALTH_BODY="${response}" \
MAX_BYPASS_RATE="${MAX_BYPASS_RATE}" \
MIN_HIT_RATE="${MIN_HIT_RATE}" \
node <<'NODE'
const body = JSON.parse(process.env.HEALTH_BODY || '{}');
const maxBypassRate = Number(process.env.MAX_BYPASS_RATE);
const minHitRate = Number(process.env.MIN_HIT_RATE);

function fail(message) {
  console.error(message);
  process.exit(1);
}

if (body.status !== 'ok') {
  fail(`readiness status is ${JSON.stringify(body.status)}, want "ok"`);
}

const cache = body.details && body.details.authorization_cache;
if (!cache || typeof cache !== 'object') {
  fail('readiness details.authorization_cache is missing');
}

const hitRate = Number(cache.hit_rate);
const bypassRate = Number(cache.bypass_rate);
if (!Number.isFinite(hitRate)) {
  fail(`authorization_cache.hit_rate is not numeric: ${cache.hit_rate}`);
}
if (!Number.isFinite(bypassRate)) {
  fail(`authorization_cache.bypass_rate is not numeric: ${cache.bypass_rate}`);
}
if (!Number.isFinite(maxBypassRate) || maxBypassRate < 0 || maxBypassRate > 1) {
  fail(`AUTHZ_CACHE_MAX_BYPASS_RATE must be a number between 0 and 1: ${process.env.MAX_BYPASS_RATE}`);
}
if (!Number.isFinite(minHitRate) || minHitRate < 0 || minHitRate > 1) {
  fail(`AUTHZ_CACHE_MIN_HIT_RATE must be a number between 0 and 1: ${process.env.MIN_HIT_RATE}`);
}
if (bypassRate > maxBypassRate) {
  fail(`authorization cache bypass_rate ${bypassRate} exceeds max ${maxBypassRate}`);
}
if (hitRate < minHitRate) {
  fail(`authorization cache hit_rate ${hitRate} below min ${minHitRate}`);
}

console.log(`authorization cache health ok: hit_rate=${hitRate} bypass_rate=${bypassRate}`);
NODE
