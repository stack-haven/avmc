# Database Locking

## Pessimistic Locking (SELECT FOR UPDATE)

### Basic Usage

```go
import "entgo.io/ent/dialect/sql"

// Lock row for update
user, err := client.User.Query().
    Where(user.ID(id)).
    ForUpdate().
    Only(ctx)
```

### With Options

```go
// ForUpdate with NOWAIT
user, err := client.User.Query().
    Where(user.ID(id)).
    ForUpdate(
        sql.WithLockAction(sql.NoWait),
    ).
    Only(ctx)

// ForUpdate with SKIP LOCKED
user, err := client.User.Query().
    Where(user.ID(id)).
    ForUpdate(
        sql.WithLockAction(sql.SkipLocked),
    ).
    Only(ctx)

// ForShare (read lock)
user, err := client.User.Query().
    Where(user.ID(id)).
    ForShare().
    Only(ctx)
```

### In Transaction

```go
func TransferCredits(ctx context.Context, client *ent.Client, fromID, toID, amount int) error {
    return ent.WithTx(ctx, client, func(tx *ent.Tx) error {
        // Lock sender
        from, err := tx.User.Query().
            Where(user.ID(fromID)).
            ForUpdate().
            Only(ctx)
        if err != nil {
            return err
        }

        if from.Credits < amount {
            return errors.New("insufficient credits")
        }

        // Lock receiver
        to, err := tx.User.Query().
            Where(user.ID(toID)).
            ForUpdate().
            Only(ctx)
        if err != nil {
            return err
        }

        // Perform transfer
        _, err = tx.User.UpdateOne(from).
            AddCredits(-amount).
            Save(ctx)
        if err != nil {
            return err
        }

        _, err = tx.User.UpdateOne(to).
            AddCredits(amount).
            Save(ctx)
        return err
    })
}
```

## Optimistic Locking

### Schema Definition

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name"),
        field.Int64("version").
            DefaultFunc(func() int64 {
                return time.Now().UnixNano()
            }).
            Comment("Optimistic lock token"),
    }
}
```

### Update with Version Check

```go
func OptimisticUpdate(ctx context.Context, client *ent.Client, user *ent.User, newName string) error {
    nextVer := time.Now().UnixNano()

    n, err := client.User.Update().
        Where(
            user.ID(user.ID),
            user.Version(user.Version),
        ).
        SetName(newName).
        SetVersion(nextVer).
        Save(ctx)

    if err != nil {
        return err
    }

    if n != 1 {
        return fmt.Errorf("concurrent modification detected")
    }

    return nil
}
```

### Alternative: Using Version Field Directly

```go
updated, err := client.User.UpdateOneID(user.ID).
    SetName(newName).
    SetVersion(user.Version + 1).
    Where(user.Version(user.Version)).  // Only update if version matches
    Save(ctx)

if ent.IsNotFound(err) {
    // Version mismatch - record was modified by another process
    return errors.New("concurrent modification detected")
}
```

## Advisory Locks (PostgreSQL)

```go
// Acquire advisory lock
func WithAdvisoryLock(ctx context.Context, db *sql.DB, key int64, fn func() error) error {
    conn, err := db.Conn(ctx)
    if err != nil {
        return err
    }
    defer conn.Close()

    // Acquire lock
    _, err = conn.ExecContext(ctx, "SELECT pg_advisory_lock($1)", key)
    if err != nil {
        return err
    }

    // Ensure release
    defer conn.ExecContext(ctx, "SELECT pg_advisory_unlock($1)", key)

    return fn()
}

// Usage
err := WithAdvisoryLock(ctx, db, 12345, func() error {
    // Critical section
    return doWork(ctx)
})
```

## Lock Timeout

```go
import "database/sql"

func QueryWithTimeout(ctx context.Context, client *ent.Client) (*ent.User, error) {
    // Set statement timeout (PostgreSQL)
    ctx = sql.WithTimeout(ctx, 5*time.Second)

    return client.User.Query().
        Where(user.ID(1)).
        ForUpdate().
        Only(ctx)
}
```

## Best Practices

### 1. Keep Transactions Short

```go
// ✅ Good: Minimal work in transaction
err := WithTx(ctx, client, func(tx *ent.Tx) error {
    user, _ := tx.User.Get(ctx, id)
    return tx.User.UpdateOne(user).
        SetLastSeen(time.Now()).
        Exec(ctx)
})

// ❌ Bad: External calls in transaction
err := WithTx(ctx, client, func(tx *ent.Tx) error {
    user, _ := tx.User.Get(ctx, id)
    // Don't do this!
    resp, _ := http.Get("https://api.example.com/data")  // Holding lock!
    return tx.User.UpdateOne(user).
        SetData(resp.Body).
        Exec(ctx)
})
```

### 2. Lock Ordering

```go
// ✅ Always lock in consistent order to prevent deadlocks
func Transfer(tx *ent.Tx, fromID, toID int) error {
    // Sort IDs to ensure consistent locking order
    firstID, secondID := fromID, toID
    if fromID > toID {
        firstID, secondID = toID, fromID
    }

    // Lock in order
    tx.User.Query().Where(user.ID(firstID)).ForUpdate().Only(ctx)
    tx.User.Query().Where(user.ID(secondID)).ForUpdate().Only(ctx)

    // ... perform transfer
}
```
