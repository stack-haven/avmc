# Migration Issues

## Schema Drift

**Symptom:** Database schema doesn't match ent schema

**Diagnosis:**
```bash
# Check current schema
atlas schema inspect --url "mysql://user:pass@localhost/dbname"

# Compare with ent schema
atlas schema diff \
  --from "mysql://user:pass@localhost/dbname" \
  --to "ent://ent/schema"
```

**Solution:**
```bash
# Generate migration for drift
atlas migrate diff fix_schema_drift \
  --dir "file://ent/migrate/migrations" \
  --to "ent://ent/schema" \
  --dev-url "docker://mysql/8/ent"

# Apply fix
atlas migrate apply \
  --dir "file://ent/migrate/migrations" \
  --url "mysql://user:pass@localhost/dbname"
```

## Migration Conflicts

**Symptom:** `atlas.sum` file conflicts

**Solution:**
```bash
# Recompute hash
atlas migrate hash \
  --dir "file://ent/migrate/migrations"

# Verify integrity
atlas migrate validate \
  --dir "file://ent/migrate/migrations"
```

## Failed Migration

**Symptom:** Migration partially applied, now failing

**Solution:**
```bash
# Check status
atlas migrate status \
  --dir "file://ent/migrate/migrations" \
  --url "mysql://user:pass@localhost/dbname"

# If stuck, manually fix and mark as applied
atlas migrate set 20240101120000 \
  --dir "file://ent/migrate/migrations" \
  --url "mysql://user:pass@localhost/dbname"
```

## Auto Migration in Production

**Issue:** Auto migration with drop options is dangerous

**Solution:**
```go
// ❌ Don't do this
client.Schema.Create(ctx,
    schema.WithDropIndex(true),
    schema.WithDropColumn(true),
)

// ✅ Safe for production
client.Schema.Create(ctx)

// ✅ Use versioned migrations
// See migrations-versioned.md
```

## Data Migration Failures

**Issue:** Schema migration passes but data migration fails

**Solution:**
```go
func migrateWithDataFix(ctx context.Context, client *ent.Client) error {
    // 1. Apply schema migration
    if err := client.Schema.Create(ctx); err != nil {
        return err
    }

    // 2. Apply data fixes
    if err := fixData(ctx, client); err != nil {
        return fmt.Errorf("data fix failed: %w", err)
    }

    return nil
}

func fixData(ctx context.Context, client *ent.Client) error {
    // Fix null values
    _, err := client.User.Update().
        SetStatus("active").
        Where(user.StatusIsNil()).
        Exec(ctx)
    return err
}
```

## Rollback Needed

**Issue:** Need to rollback a migration

**Solution:**
```bash
# Atlas doesn't support automatic rollback
# You need to create a new migration

# Create rollback migration manually:
cat > ent/migrate/migrations/20240102_rollback_change.sql << 'EOF'
-- Reverse the changes
ALTER TABLE users DROP COLUMN new_field;
EOF

# Update hash
atlas migrate hash --dir "file://ent/migrate/migrations"
```
