# Common Errors

## Not Found

```
ent: user not found
```

**Causes:**
- Entity doesn't exist
- Entity was soft deleted
- Wrong ID provided

**Solutions:**
```go
user, err := client.User.Get(ctx, id)
if err != nil {
    if ent.IsNotFound(err) {
        // Handle not found gracefully
        return nil, ErrUserNotFound
    }
    return nil, err
}

// Or use Only() and check
user, err := client.User.Query().
    Where(user.ID(id)).
    Only(ctx)
if ent.IsNotFound(err) {
    // Not found
}
```

## Constraint Error

```
ent: constraint failed: UNIQUE constraint failed: users.email
```

**Causes:**
- Duplicate unique field
- Violating foreign key constraint

**Solutions:**
```go
user, err := client.User.Create().
    SetEmail(email).
    Save(ctx)
if err != nil {
    if ent.IsConstraintError(err) {
        // Check specific constraint
        if strings.Contains(err.Error(), "email") {
            return nil, ErrDuplicateEmail
        }
    }
    return nil, err
}

// Or use upsert
client.User.Create().
    SetEmail(email).
    OnConflictColumns(user.FieldEmail).
    Update(func(u *ent.UserUpsert) {
        u.SetName(name)
    }).
    Exec(ctx)
```

## Validation Error

```
ent: validator failed for field User.age: invalid value
```

**Causes:**
- Field validation failed
- Required field missing
- Regex pattern not matched

**Solutions:**
```go
// Check validation
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.Int("age").
            Positive().
            Validate(func(i int) error {
                if i > 150 {
                    return fmt.Errorf("age too high")
                }
                return nil
            }),
    }
}

// Handle in code
user, err := client.User.Create().SetAge(-1).Save(ctx)
if ent.IsValidationError(err) {
    // Handle validation error
}
```

## N+1 Query

**Symptom:** Slow queries, many database calls

**Solution:**
```go
// ❌ Bad - N+1
users, _ := client.User.Query().All(ctx)
for _, u := range users {
    pets, _ := u.QueryPets().All(ctx)  // Query per user!
}

// ✅ Good - Eager loading
users, _ := client.User.Query().
    WithPets().  // Single query
    All(ctx)
```

## Migration Errors

```
ent: migrate: sql/schema: creating table: table users already exists
```

**Solutions:**
```bash
# Reset database (dev only)
dropdb mydb && createdb mydb

# Or use versioned migrations
atlas migrate apply --dir "file://migrations" --url "postgres://..."
```

## Connection Errors

```
dial tcp: connect: connection refused
```

**Causes:**
- Database not running
- Wrong connection string
- Network issues

**Solutions:**
```go
// Check connection string
dsn := "user:pass@tcp(localhost:3306)/dbname?parseTime=True"

// Add retry logic
for i := 0; i < 5; i++ {
    client, err := ent.Open("mysql", dsn)
    if err == nil {
        return client, nil
    }
    time.Sleep(time.Second * time.Duration(i+1))
}
```

## Generated Code Issues

```
undefined: ent.User
```

**Solutions:**
```bash
# Regenerate code
go generate ./ent

# Or
go run -mod=mod entgo.io/ent/cmd/ent generate ./schema

# Clear cache if needed
go clean -cache
go generate ./ent
```
