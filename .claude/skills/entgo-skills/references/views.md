# Views

## Defining a View

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/dialect/sql"
    "entgo.io/ent/schema"
    "entgo.io/ent/schema/field"
)

// UserStatistics is a read-only view
type UserStatistics struct {
    ent.View
}

func (UserStatistics) Annotations() []schema.Annotation {
    return []schema.Annotation{
        // Mark as view
        entsql.View(),
    }
}

func (UserStatistics) Fields() []ent.Field {
    return []ent.Field{
        field.Int("user_id"),
        field.String("user_name"),
        field.Int("pet_count"),
        field.Int("friend_count"),
    }
}

func (UserStatistics) Schema() string {
    return `
CREATE VIEW user_statistics AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    COUNT(DISTINCT p.id) AS pet_count,
    COUNT(DISTINCT f.id) AS friend_count
FROM users u
LEFT JOIN pets p ON p.user_id = u.id
LEFT JOIN user_friends f ON f.user_id = u.id
GROUP BY u.id, u.name
`
}
```

## Using Views

```go
// Query the view
stats, err := client.UserStatistics.Query().All(ctx)

// With filter
activeStats, err := client.UserStatistics.Query().
    Where(userstatistics.PetCountGT(0)).
    All(ctx)
```

## Materialized Views

```go
func (UserStatistics) Annotations() []schema.Annotation {
    return []schema.Annotation{
        // Mark as materialized view
        entsql.MaterializedView(),
    }
}

func (UserStatistics) Schema() string {
    return `
CREATE MATERIALIZED VIEW user_statistics AS
SELECT ...
`
}
```

### Refreshing Materialized Views

```go
// Refresh the view
func RefreshUserStatistics(ctx context.Context, client *ent.Client) error {
    _, err := client.ExecContext(ctx, "REFRESH MATERIALIZED VIEW user_statistics")
    return err
}

// Refresh concurrently (requires unique index)
func RefreshUserStatisticsConcurrently(ctx context.Context, client *ent.Client) error {
    _, err := client.ExecContext(ctx, "REFRESH MATERIALIZED VIEW CONCURRENTLY user_statistics")
    return err
}
```

## Migration with Views

```go
// ent/migrate/views.go
package migrate

import (
    "context"
    "entgo.io/ent/dialect"
)

func CreateViews(ctx context.Context, tx dialect.Tx) error {
    // Create view
    if err := tx.Exec(ctx, `
        CREATE OR REPLACE VIEW active_users AS
        SELECT * FROM users WHERE active = true
    `, nil, nil); err != nil {
        return err
    }
    return nil
}
```

## Querying Views

```go
// Views are read-only by default
activeUsers, err := client.ActiveUser.Query().All(ctx)

// Cannot create/update/delete
// client.ActiveUser.Create()... // Will error
```

## Views with Complex Queries

```go
func (UserDashboard) Schema() string {
    return `
CREATE VIEW user_dashboard AS
WITH user_stats AS (
    SELECT
        u.id,
        u.name,
        u.email,
        COUNT(DISTINCT p.id) as pet_count,
        COUNT(DISTINCT g.id) as group_count
    FROM users u
    LEFT JOIN pets p ON p.user_id = u.id AND p.deleted_at IS NULL
    LEFT JOIN group_users gu ON gu.user_id = u.id
    LEFT JOIN groups g ON g.id = gu.group_id AND g.active = true
    WHERE u.deleted_at IS NULL
    GROUP BY u.id, u.name, u.email
)
SELECT * FROM user_stats
`
}
```

## Best Practices

### 1. Use Views for Complex Joins

```go
// Instead of complex queries
users, err := client.User.Query().
    WithPets().
    WithGroups().
    Modify(func(s *sql.Selector) {
        // Complex aggregation
    }).
    All(ctx)

// Use a view
stats, err := client.UserStatistics.Query().All(ctx)
```

### 2. Index Materialized Views

```sql
CREATE UNIQUE INDEX ON user_statistics (user_id);
CREATE INDEX ON user_statistics (pet_count);
```

### 3. Schedule Refreshes

```go
// Refresh periodically
func ScheduleViewRefresh(client *ent.Client) {
    ticker := time.NewTicker(5 * time.Minute)
    go func() {
        for range ticker.C {
            ctx := context.Background()
            RefreshUserStatisticsConcurrently(ctx, client)
        }
    }()
}
```
