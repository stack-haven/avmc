---
name: backend-service-build
description: How to build and run backend services in the Ark Tech Platform monorepo
metadata: 
  node_type: memory
  type: reference
  originSessionId: d9e279d5-1187-4e76-a0dc-8476b839c967
  modified: 2026-07-30T01:36:29.575Z
---

## Build System

Each service module under `backend-service/app/` (e.g., `platform/admin`, `ai/service`) has its own Makefile that includes `backend-service/app.mk`.

**Always run make commands from within the service directory**, e.g.:
```bash
cd backend-service/app/platform/service
make run      # api → go run ./cmd/server -conf ./configs
make build    # go build -o ./bin/ ./...
make check    # fmt + vet
make api      # buf generate from proto/
make ent      # go generate ./internal/data/ent
make wire     # wire ./cmd/server
make gen      # ent + wire + api + openapi
```

The `backend-service/Makefile` at the root is a DIFFERENT makefile with different targets (e.g., `make proto` which uses remote buf plugins). Do NOT use the root Makefile for service-level builds.

## Key findings from `app.mk`

- `run` depends on `api` target (proto regeneration before each run)
- `gen` = ent + wire + api + openapi
- `app` = api + wire + ent + build (full build pipeline)
- `wire` runs from `./cmd/server` within the service directory

See [[ent-case-insensitive-imports]] for issues with macOS case-insensitive filesystem and Ent gen packages.
