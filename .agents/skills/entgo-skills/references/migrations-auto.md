# Auto Migrations

## Basic Auto Migration

```go
import "context"

func main() {
    client, err := ent.Open("mysql", dsn)
    if err != nil {
        log.Fatal(err)
    }
    defer client.Close()

    ctx := context.Background()

    // Run auto migration
    if err := client.Schema.Create(ctx); err != nil {
        log.Fatalf("failed creating schema: %v", err)
    }
}
```

## Migration Options

```go
import "entgo.io/ent/dialect/sql/schema"

func migrate(ctx context.Context, client *ent.Client) error {
    return client.Schema.Create(
        ctx,
        // Drop indexes that no longer exist in schema
        schema.WithDropIndex(true),

        // Drop columns that no longer exist in schema
        schema.WithDropColumn(true),

        // Create foreign keys
        schema.WithForeignKeys(true),

        // Use Atlas for migrations (recommended)
        schema.WithAtlas(true),
    )
}
```

## Conditional Migration

```go
func migrateWithMode(ctx context.Context, client *ent.Client, devMode bool) error {
    if devMode {
        // In dev: drop columns and indexes
        return client.Schema.Create(
            ctx,
            schema.WithDropIndex(true),
            schema.WithDropColumn(true),
        )
    }

    // In prod: safer migration
    return client.Schema.Create(ctx)
}
```

## Migration Hooks

```go
func migrateWithHooks(ctx context.Context, client *ent.Client) error {
    return client.Schema.Create(
        ctx,
        schema.WithApplyHook(func(next schema.Applier) schema.Applier {
            return schema.ApplyFunc(func(ctx context.Context, conn dialect.ExecQuerier, plan *migrate.Plan) error {
                // Log migration
                log.Printf("Applying migration with %d changes", len(plan.Changes))

                // Apply migration
                return next.Apply(ctx, conn, plan)
            })
        }),
    )
}
```

## Data Migration Hook

```go
func FillNullValues(dialect string) schema.ApplyHook {
    return func(next schema.Applier) schema.Applier {
        return schema.ApplyFunc(func(ctx context.Context, conn dialect.ExecQuerier, plan *migrate.Plan) error {
            // Check if we need data migration
            hasChange := func() bool {
                for _, c := range plan.Changes {
                    m, ok := c.Source.(*schema.ModifyTable)
                    if ok && m.T.Name == user.Table {
                        for _, change := range m.Changes {
                            if _, ok := change.(*schema.AddColumn); ok {
                                return true
                            }
                        }
                    }
                }
                return false
            }()

            if hasChange {
                // Create temp client from connection
                client := ent.NewClient(
                    ent.Driver(sql.NewDriver(dialect, sql.Conn{ExecQuerier: conn.(*sql.Tx)})))

                // Fill default values
                if err := client.User.
                    Update().
                    SetStatus("active").
                    Where(user.StatusIsNil()).
                    Exec(ctx); err != nil {
                    return err
                }
            }

            return next.Apply(ctx, conn, plan)
        })
    }
}

// Usage
client.Schema.Create(ctx, schema.WithApplyHook(FillNullValues("mysql")))
```

## Dry Run Migration

```go
func dryRun(ctx context.Context, client *ent.Client) error {
    // Use memory database for dry run
    memClient, err := ent.Open("sqlite3", "file:test?mode=memory&_fk=1")
    if err != nil {
        return err
    }
    defer memClient.Close()

    // This will print the SQL without affecting production
    return memClient.Schema.WriteTo(ctx, os.Stdout)
}
```

## Migration with Multiple Databases

```go
func migrateDatabases(ctx context.Context) error {
    dbs := []struct {
        name   string
        dialect string
        dsn    string
    }{
        {"primary", "mysql", primaryDSN},
        {"analytics", "postgres", analyticsDSN},
    }

    for _, db := range dbs {
        client, err := ent.Open(db.dialect, db.dsn)
        if err != nil {
            return fmt.Errorf("opening %s: %w", db.name, err)
        }

        if err := client.Schema.Create(ctx); err != nil {
            client.Close()
            return fmt.Errorf("migrating %s: %w", db.name, err)
        }

        client.Close()
        log.Printf("Migrated %s database", db.name)
    }

    return nil
}
```

## Caution: Auto Migration in Production

```go
// ⚠️ Auto migration with drop options is dangerous in production!

// ❌ Don't do this in production
if err := client.Schema.Create(
    ctx,
    schema.WithDropIndex(true),   // Dangerous!
    schema.WithDropColumn(true),  // Dangerous!
); err != nil {
    log.Fatal(err)
}

// ✅ Safer approach for production
if err := client.Schema.Create(ctx); err != nil {
    log.Fatal(err)
}

// ✅ Use versioned migrations instead (see migrations-versioned.md)
```
