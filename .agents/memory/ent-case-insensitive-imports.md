---
name: ent-case-insensitive-imports
description: macOS case-insensitive filesystem causes Ent gen package import collisions
metadata: 
  node_type: memory
  type: reference
  originSessionId: d9e279d5-1187-4e76-a0dc-8476b839c967
  modified: 2026-07-30T01:36:47.061Z
---

## Problem

When renaming an Ent schema (e.g., `MenuPermissionGroup` → `TenantMenuPermissionGroup`), the Ent code generator creates new gen packages. On macOS (case-insensitive filesystem), the old and new package directories resolve to the same path, causing Go import collisions like:

```
case-insensitive import collision: "gen/TenantMenuPermissionGroup" and "gen/tenantmenupermissiongroup"
```

This happens because the old directory `gen/menupermissiongroup` and the new `gen/TenantMenuPermissionGroup` are treated as identical by the filesystem.

## Fix

After schema rename and `make ent` regeneration:

1. **Delete old generated API proto files** (`api/core/service/v1/menu_permission_group*.pb.go`, `api/platform/admin/v1/i_menu_permission_group*.pb.go` — 注：迁移后旧路径已统一为 `api/platform/service/v1/`；此处为迁移前历史路径) — they coexist with new `tenant_menu_permission_group*.pb.go` files and cause duplicate declarations.

2. **Fix import paths**: Source code imports must use the lowercase package paths that Ent generates (e.g., `gen/tenantmenupermissiongroup`, not `gen/TenantMenuPermissionGroup`). On macOS, Go sees them as the same but the compiler flags the mismatch.

3. **Fix package-level function references**: Ent generates sub-packages with lowercase names. Code like `TenantMenuPermissionGroup.IDEQ(id)` must use the lowercase package name: `tenantmenupermissiongroup.IDEQ(id)`. But method calls on `gen.Client` like `r.Data.DB(ctx).TenantMenuPermissionGroup` use the capitalized type name and must NOT be changed.

4. **Fix double-prefix errors**: Bulk renames can create `TenantTenantMenuPermissionGroup` — collapse back to single `Tenant` prefix.

5. **Regenerate proto** after renaming proto files: `cd proto && buf generate --template buf.gen.local.yaml` (use local plugins if BSR remote is unavailable).

## Related

[[backend-service-build]] for correct build commands.
