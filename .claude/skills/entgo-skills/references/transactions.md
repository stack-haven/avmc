# Transactions

## Basic Transaction

```go
func TransferCredits(ctx context.Context, client *ent.Client, fromID, toID, amount int) error {
    tx, err := client.Tx(ctx)
    if err != nil {
        return err
    }

    // Deduct from sender
    from, err := tx.User.Get(ctx, fromID)
    if err != nil {
        tx.Rollback()
        return err
    }
    if from.Credits < amount {
        tx.Rollback()
        return errors.New("insufficient credits")
    }
    _, err = tx.User.UpdateOne(from).
        AddCredits(-amount).
        Save(ctx)
    if err != nil {
        tx.Rollback()
        return err
    }

    // Add to receiver
    _, err = tx.User.UpdateOneID(toID).
        AddCredits(amount).
        Save(ctx)
    if err != nil {
        tx.Rollback()
        return err
    }

    return tx.Commit()
}
```

## Transaction Helper

```go
func WithTx(ctx context.Context, client *ent.Client, fn func(tx *ent.Tx) error) error {
    tx, err := client.Tx(ctx)
    if err != nil {
        return err
    }
    defer func() {
        if v := recover(); v != nil {
            tx.Rollback()
            panic(v)
        }
    }()
    if err := fn(tx); err != nil {
        if rerr := tx.Rollback(); rerr != nil {
            err = fmt.Errorf("%w: rolling back transaction: %v", err, rerr)
        }
        return err
    }
    if err := tx.Commit(); err != nil {
        return fmt.Errorf("committing transaction: %w", err)
    }
    return nil
}

// Usage
err := WithTx(ctx, client, func(tx *ent.Tx) error {
    u, err := tx.User.Create().SetName("Alice").Save(ctx)
    if err != nil {
        return err
    }
    _, err = tx.Pet.Create().SetName("Fluffy").SetOwner(u).Save(ctx)
    return err
})
```

## Context Propagation

```go
// In middleware/resolver
func TransactionMiddleware(client *ent.Client) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            tx, err := client.Tx(r.Context())
            if err != nil {
                http.Error(w, err.Error(), http.StatusInternalServerError)
                return
            }
            defer tx.Rollback()

            // Inject transaction client into context
            ctx := ent.NewContext(r.Context(), tx.Client())

            // Call next handler
            next.ServeHTTP(w, r.WithContext(ctx))

            // Commit if no error (you'd typically check for response status)
            tx.Commit()
        })
    }
}

// In resolver
func (r *mutationResolver) CreateUser(ctx context.Context, input ent.CreateUserInput) (*ent.User, error) {
    client := ent.FromContext(ctx)  // Get transaction client
    return client.User.Create().SetInput(input).Save(ctx)
}
```

## Nested Transactions (Savepoints)

```go
// Ent supports savepoints for nested transactions
func NestedTransaction(ctx context.Context, tx *ent.Tx) error {
    // Start savepoint
    nestedTx, err := tx.BeginTx(ctx, nil)
    if err != nil {
        return err
    }

    _, err = nestedTx.User.Create().SetName("Test").Save(ctx)
    if err != nil {
        nestedTx.Rollback()  // Rollback to savepoint
        return err
    }

    return nestedTx.Commit()  // Release savepoint
}
```

## Transaction Isolation

```go
import "database/sql"

func WithIsolation(ctx context.Context, client *ent.Client, level sql.IsolationLevel) (*ent.Tx, error) {
    opts := &sql.TxOptions{
        Isolation: level,
        ReadOnly:  false,
    }
    return client.BeginTx(ctx, opts)
}

// Usage
tx, err := WithIsolation(ctx, client, sql.LevelSerializable)
// or
tx, err := WithIsolation(ctx, client, sql.LevelReadCommitted)
```

## Best Practices

```go
// ✅ Keep transactions short
func GoodExample(ctx context.Context, client *ent.Client) error {
    return WithTx(ctx, client, func(tx *ent.Tx) error {
        // Do minimal work here
        _, err := tx.User.Create().SetName("Alice").Save(ctx)
        return err
    })
}

// ❌ Don't do long operations in transactions
func BadExample(ctx context.Context, client *ent.Client) error {
    tx, _ := client.Tx(ctx)
    defer tx.Rollback()

    // Don't do this!
    time.Sleep(10 * time.Second)  // Holding transaction open

    tx.User.Create().SetName("Alice").Save(ctx)
    return tx.Commit()
}

// ✅ Handle panics
func SafeTransaction(ctx context.Context, client *ent.Client) (err error) {
    tx, err := client.Tx(ctx)
    if err != nil {
        return err
    }
    defer func() {
        if v := recover(); v != nil {
            tx.Rollback()
            err = fmt.Errorf("panic: %v", v)
        } else if err != nil {
            tx.Rollback()
        } else {
            err = tx.Commit()
        }
    }()

    // Transaction operations...
    _, err = tx.User.Create().SetName("Alice").Save(ctx)
    return err
}
```
