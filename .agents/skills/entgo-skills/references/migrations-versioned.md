# Versioned Migrations

## Atlas Installation

```bash
# macOS
curl -sSf https://atlasgo.sh | sh

# Docker
docker pull arigaio/atlas

# Go
go install ariga.io/atlas/cmd/atlas@latest
```

## Initialize Migrations

```bash
# Create migrations directory
mkdir -p ent/migrate/migrations

# Create initial migration
atlas migrate diff initial \
  --dir "file://ent/migrate/migrations" \
  --to "ent://ent/schema" \
  --dev-url "docker://mysql/8/ent"
```

## Generate Migrations

```bash
# MySQL
atlas migrate diff add_user_table \
  --dir "file://ent/migrate/migrations" \
  --to "ent://ent/schema" \
  --dev-url "docker://mysql/8/ent"

# PostgreSQL
atlas migrate diff add_user_table \
  --dir "file://ent/migrate/migrations" \
  --to "ent://ent/schema" \
  --dev-url "docker://postgres/15/test?search_path=public"

# SQLite
atlas migrate diff add_user_table \
  --dir "file://ent/migrate/migrations" \
  --to "ent://ent/schema" \
  --dev-url "sqlite://file?mode=memory&_fk=1"
```

## Migration Directory Structure

```
ent/migrate/migrations/
├── 20240101000001_initial.sql
├── 20240102000002_add_user_table.sql
├── 20240103000003_add_indexes.sql
└── atlas.sum          # Integrity check
```

## Apply Migrations

```bash
# Apply all pending migrations
atlas migrate apply \
  --dir "file://ent/migrate/migrations" \
  --url "mysql://user:pass@localhost:3306/dbname"

# Apply specific number of migrations
atlas migrate apply 1 \
  --dir "file://ent/migrate/migrations" \
  --url "mysql://user:pass@localhost:3306/dbname"
```

## Status Check

```bash
# Check migration status
atlas migrate status \
  --dir "file://ent/migrate/migrations" \
  --url "mysql://user:pass@localhost:3306/dbname"
```

## Programmatic Migration

```go
import (
    "ariga.io/atlas/sql/migrate"
    "entgo.io/ent/dialect/sql"
    "entgo.io/ent/dialect/sql/schema"
)

func runMigrations(ctx context.Context, db *sql.DB) error {
    // Create local migration directory
    dir, err := migrate.NewLocalDir("ent/migrate/migrations")
    if err != nil {
        return err
    }

    // Create migrator
    m, err := schema.NewMigrate(
        sql.OpenDB("mysql", db),
        schema.WithDir(dir),
    )
    if err != nil {
        return err
    }

    // Apply migrations
    return m.NamedDiff(ctx, "migration_name", nil)
}
```

## Rollback Migrations

```bash
# Atlas doesn't support automatic rollback
# You need to create a new migration that reverses changes

# Example: To rollback 'add_column', create:
atlas migrate diff rollback_add_column \
  --dir "file://ent/migrate/migrations" \
  --to "ent://ent/schema@previous_version" \
  --dev-url "docker://mysql/8/ent"
```

## Best Practices

```go
// 1. Always review generated migrations before applying
// 2. Test migrations on a copy of production data
// 3. Make migrations backward compatible when possible
// 4. Use transactions in migrations

// Example of backward-compatible migration:
// 1. Add new column (nullable)
// 2. Deploy code that writes to both columns
// 3. Backfill data
// 4. Make column non-nullable
// 5. Deploy code that only uses new column
// 6. Drop old column
```

## CI/CD Integration

```yaml
# .github/workflows/migrate.yml
name: Database Migration
on:
  push:
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Atlas
        uses: ariga/setup-atlas@v0

      - name: Apply Migrations
        run: |
          atlas migrate apply \
            --dir "file://ent/migrate/migrations" \
            --url "${{ secrets.DATABASE_URL }}"
```
