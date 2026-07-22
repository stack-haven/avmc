# Error Handling

## Ent Error Types

```go
import "entgo.io/ent"

// Check error types
if ent.IsNotFound(err) {
    // Handle not found
}

if ent.IsConstraintError(err) {
    // Handle unique constraint violation
}

if ent.IsValidationError(err) {
    // Handle validation error
}
```

## Common Error Patterns

### Not Found

```go
user, err := client.User.Get(ctx, id)
if err != nil {
    if ent.IsNotFound(err) {
        return nil, fmt.Errorf("user %d not found", id)
    }
    return nil, fmt.Errorf("getting user: %w", err)
}
```

### Constraint Error

```go
user, err := client.User.Create().
    SetEmail(email).
    Save(ctx)
if err != nil {
    if ent.IsConstraintError(err) {
        return nil, fmt.Errorf("email already exists: %s", email)
    }
    return nil, err
}
```

### Validation Error

```go
user, err := client.User.Create().
    SetAge(-1).
    Save(ctx)
if err != nil {
    if ent.IsValidationError(err) {
        return nil, fmt.Errorf("invalid data: %w", err)
    }
    return nil, err
}
```

## Custom Error Types

```go
package errors

import (
    "errors"
    "entgo.io/ent"
)

var (
    ErrNotFound       = errors.New("not found")
    ErrDuplicate      = errors.New("duplicate entry")
    ErrValidation     = errors.New("validation failed")
    ErrUnauthorized   = errors.New("unauthorized")
)

func Wrap(err error, operation string) error {
    if err == nil {
        return nil
    }

    switch {
    case ent.IsNotFound(err):
        return fmt.Errorf("%s: %w", operation, ErrNotFound)
    case ent.IsConstraintError(err):
        return fmt.Errorf("%s: %w", operation, ErrDuplicate)
    case ent.IsValidationError(err):
        return fmt.Errorf("%s: %w", operation, ErrValidation)
    default:
        return fmt.Errorf("%s: %w", operation, err)
    }
}
```

## Error Handling in Service Layer

```go
func (s *UserService) GetByID(ctx context.Context, id int) (*ent.User, error) {
    user, err := s.client.User.Get(ctx, id)
    if err != nil {
        if ent.IsNotFound(err) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("getting user %d: %w", id, err)
    }
    return user, nil
}

func (s *UserService) Create(ctx context.Context, input CreateUserInput) (*ent.User, error) {
    user, err := s.client.User.Create().
        SetName(input.Name).
        SetEmail(input.Email).
        Save(ctx)
    if err != nil {
        if ent.IsConstraintError(err) {
            return nil, ErrEmailExists
        }
        return nil, fmt.Errorf("creating user: %w", err)
    }
    return user, nil
}
```

## Panic Recovery

```go
func WithRecovery(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                log.Printf("panic: %v\n%s", err, debug.Stack())
                http.Error(w, "Internal Server Error", http.StatusInternalServerError)
            }
        }()
        next.ServeHTTP(w, r)
    })
}
```

## Error in Transactions

```go
func Transfer(ctx context.Context, client *ent.Client, from, to, amount int) error {
    tx, err := client.Tx(ctx)
    if err != nil {
        return fmt.Errorf("starting transaction: %w", err)
    }

    defer func() {
        if v := recover(); v != nil {
            tx.Rollback()
            panic(v)
        }
    }()

    // ... operations ...

    if err := tx.Commit(); err != nil {
        return fmt.Errorf("committing transaction: %w", err)
    }
    return nil
}
```
