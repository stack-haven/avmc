# Hooks

## Schema-Level Hooks

```go
func (User) Hooks() []ent.Hook {
    return []ent.Hook{
        // Hook for create operations
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    // Validation
                    if age, ok := m.Age(); ok && age < 0 {
                        return nil, fmt.Errorf("age cannot be negative")
                    }

                    // Set default
                    if _, ok := m.Name(); !ok {
                        m.SetName("Anonymous")
                    }

                    return next.Mutate(ctx, m)
                })
            },
            ent.OpCreate,
        ),

        // Hook for update operations
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    // Auto-update timestamp
                    m.SetUpdatedAt(time.Now())
                    return next.Mutate(ctx, m)
                })
            },
            ent.OpUpdate|ent.OpUpdateOne,
        ),
    }
}
```

## Global Hooks

```go
func main() {
    client, err := ent.Open("sqlite3", "file:ent.db?_fk=1")
    if err != nil {
        log.Fatal(err)
    }

    // Add global audit hook
    client.Use(func(next ent.Mutator) ent.Mutator {
        return ent.MutateFunc(func(ctx context.Context, m ent.Mutation) (ent.Value, error) {
            start := time.Now()
            value, err := next.Mutate(ctx, m)

            // Audit log
            log.Printf("Operation: %s, Type: %T, Time: %v, Error: %v",
                m.Op(),
                m,
                time.Since(start),
                err,
            )

            return value, err
        })
    })
}
```

## Conditional Hooks

```go
func (Card) Hooks() []ent.Hook {
    return []ent.Hook{
        // Only on create
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.CardFunc(func(ctx context.Context, m *ent.CardMutation) (ent.Value, error) {
                    // Only for create
                    return next.Mutate(ctx, m)
                })
            },
            ent.OpCreate,
        ),

        // Only on delete
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.CardFunc(func(ctx context.Context, m *ent.CardMutation) (ent.Value, error) {
                    // Prevent deletion
                    return nil, fmt.Errorf("card deletion is not allowed")
                })
            },
            ent.OpDelete|ent.OpDeleteOne,
        ),

        // Skip if conditions not met
        hook.If(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    // Only for admin users
                    return next.Mutate(ctx, m)
                })
            },
            func(ctx context.Context, m ent.Mutation) bool {
                // Check if user is admin
                viewer := viewer.FromContext(ctx)
                return viewer != nil && viewer.IsAdmin()
            },
        ),
    }
}
```

## Hook Operations

```go
const (
    OpCreate    ent.Op = 1 << iota // Create operation
    OpUpdate                      // Update operation
    OpUpdateOne                   // UpdateOne operation
    OpDelete                      // Delete operation
    OpDeleteOne                   // DeleteOne operation
    OpAll         = OpCreate|OpUpdate|OpUpdateOne|OpDelete|OpDeleteOne
)
```

## Accessing Mutation Data

```go
func (User) Hooks() []ent.Hook {
    return []ent.Hook{
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    // Get operation type
                    op := m.Op()

                    // Get ID
                    id, ok := m.ID()

                    // Get old values
                    oldName, _ := m.OldName(ctx)

                    // Get new values
                    name, ok := m.Name()

                    // Check if field was changed
                    if m.Fields().Has(user.FieldName) {
                        // Name was modified
                    }

                    // Get all set fields
                    fields := m.Fields()

                    // Add additional changes
                    m.SetUpdatedAt(time.Now())

                    return next.Mutate(ctx, m)
                })
            },
            ent.OpUpdate|ent.OpUpdateOne,
        ),
    }
}
```

## Async Hooks (After Commit)

```go
func (User) Hooks() []ent.Hook {
    return []ent.Hook{
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    value, err := next.Mutate(ctx, m)
                    if err != nil {
                        return nil, err
                    }

                    // Fire and forget async operation
                    go func() {
                        // Send notification, update cache, etc.
                        // Note: This runs after transaction commit
                    }()

                    return value, nil
                })
            },
            ent.OpCreate,
        ),
    }
}
```

## Hook Best Practices

```go
// ✅ Validate before mutation
func (User) Hooks() []ent.Hook {
    return []ent.Hook{
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    // Validate before calling next
                    if email, ok := m.Email(); ok {
                        if !isValidEmail(email) {
                            return nil, fmt.Errorf("invalid email")
                        }
                    }
                    return next.Mutate(ctx, m)
                })
            },
            ent.OpCreate|ent.OpUpdate,
        ),
    }
}

// ✅ Always call next.Mutate
func (User) Hooks() []ent.Hook {
    return []ent.Hook{
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    // Do something before
                    m.SetUpdatedAt(time.Now())

                    // MUST call next.Mutate
                    value, err := next.Mutate(ctx, m)

                    // Do something after
                    if err == nil {
                        log.Println("User updated successfully")
                    }

                    return value, err
                })
            },
            ent.OpUpdate,
        ),
    }
}
```
