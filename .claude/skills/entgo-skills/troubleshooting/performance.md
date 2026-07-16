# Performance Issues

## N+1 Query Problem

**Symptom:** Many small queries instead of one

**Before:**
```go
// ❌ N+1: 1 + N queries
users, _ := client.User.Query().All(ctx)  // 1 query
for _, u := range users {
    pets, _ := u.QueryPets().All(ctx)      // N queries
    _ = pets
}
```

**After:**
```go
// ✅ Eager loading: 1 query with JOIN
users, _ := client.User.Query().
    WithPets().
    All(ctx)

for _, u := range users {
    pets := u.Edges.Pets  // Already loaded
    _ = pets
}
```

## Large Result Sets

**Symptom:** Memory issues with large queries

**Solution:**
```go
// Use pagination
func ProcessAllUsers(ctx context.Context, client *ent.Client) error {
    const batchSize = 1000
    cursor := 0

    for {
        users, err := client.User.Query().
            Where(user.IDGT(cursor)).
            Order(ent.Asc(user.FieldID)).
            Limit(batchSize).
            All(ctx)
        if err != nil {
            return err
        }

        if len(users) == 0 {
            break
        }

        // Process batch
        for _, u := range users {
            // Process user
        }

        cursor = users[len(users)-1].ID
    }
    return nil
}
```

## Slow Queries

**Symptom:** Query taking too long

**Solutions:**
```go
// Add indexes
func (User) Indexes() []ent.Index {
    return []ent.Index{
        index.Fields("status", "created_at"),
        index.Fields("email").Unique(),
    }
}

// Use Select for specific fields
names, err := client.User.Query().
    Select(user.FieldName).
    Strings(ctx)

// Add limit
users, err := client.User.Query().
    Where(user.Status("active")).
    Order(ent.Desc(user.FieldCreatedAt)).
    Limit(100).
    All(ctx)
```

## Connection Pool Exhaustion

**Symptom:** "too many connections" errors

**Solution:**
```go
drv, err := sql.Open("mysql", dsn)
db := drv.DB()

// Tune pool settings
db.SetMaxOpenConns(25)        // Adjust based on DB capacity
db.SetMaxIdleConns(25)
db.SetConnMaxLifetime(5 * time.Minute)
db.SetConnMaxIdleTime(1 * time.Minute)
```

## Lock Contention

**Symptom:** Deadlocks or timeouts

**Solutions:**
```go
// Use FOR UPDATE for locking
user, err := client.User.Query().
    Where(user.ID(id)).
    ForUpdate().
    Only(ctx)

// Keep transactions short
err := WithTx(ctx, client, func(tx *ent.Tx) error {
    // Do minimal work here
    // Don't call external services
    return nil
})

// Use optimistic locking with version field
field.Int("version").Default(0)

user.Update().
    SetName("new").
    SetVersion(user.Version + 1).
    Where(user.Version(user.Version)).
    Save(ctx)
```

## Memory Leaks

**Symptom:** Growing memory usage

**Solutions:**
```go
// Close client on shutdown
client, err := ent.Open("mysql", dsn)
if err != nil {
    log.Fatal(err)
}
defer client.Close()

// Don't cache large result sets
// Process and release

// Use streaming for very large datasets
```

## Profiling

```go
import _ "net/http/pprof"

func init() {
    go func() {
        log.Println(http.ListenAndServe("localhost:6060", nil))
    }()
}

// View profile:
// go tool pprof http://localhost:6060/debug/pprof/heap
```
