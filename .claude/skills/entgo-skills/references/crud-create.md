# Create Operations

## Basic Create

```go
user, err := client.User.Create().
    SetName("Alice").
    SetEmail("alice@example.com").
    SetAge(30).
    Save(ctx)
```

## Create with SaveX (Panic on Error)

```go
user := client.User.Create().
    SetName("Bob").
    SaveX(ctx)
```

## Create with Default Values

```go
// Fields with defaults don't need to be set
user, err := client.User.Create().
    SetName("Charlie").
    // active defaults to true
    // created_at defaults to time.Now()
    Save(ctx)
```

## Create with Optional Fields

```go
user, err := client.User.Create().
    SetName("David").
    SetNillableNickname(ptr("Dave")).  // Set or nil
    Save(ctx)

func ptr(s string) *string {
    return &s
}
```

## Create with Relationships

### Create with Existing Relation

```go
// Add existing pets
user, err := client.User.Create().
    SetName("Alice").
    AddPetIDs(1, 2, 3).
    Save(ctx)
```

### Create with New Relations

```go
// Create user and pets in one operation
user, err := client.User.Create().
    SetName("Alice").
    AddPets(
        client.Pet.Create().SetName("Fluffy"),
        client.Pet.Create().SetName("Buddy"),
    ).
    Save(ctx)
```

### Create with Inverse Relation

```go
// Create pet with owner
pet, err := client.Pet.Create().
    SetName("Fluffy").
    SetOwner(user).
    Save(ctx)
```

## Bulk Create

```go
users, err := client.User.CreateBulk(
    client.User.Create().SetName("User1").SetAge(20),
    client.User.Create().SetName("User2").SetAge(25),
    client.User.Create().SetName("User3").SetAge(30),
).Save(ctx)
```

## Batch Create

```go
func BulkCreateUsers(ctx context.Context, client *ent.Client, names []string) error {
    const batchSize = 100

    for i := 0; i < len(names); i += batchSize {
        end := i + batchSize
        if end > len(names) {
            end = len(names)
        }

        builders := make([]*ent.UserCreate, 0, batchSize)
        for _, name := range names[i:end] {
            builders = append(builders, client.User.Create().SetName(name))
        }

        _, err := client.User.CreateBulk(builders...).Save(ctx)
        if err != nil {
            return err
        }
    }
    return nil
}
```

## Upsert (Create or Update)

```go
// Insert or update on conflict
userID, err := client.User.Create().
    SetName("Alice").
    SetEmail("alice@example.com").
    OnConflictColumns(user.FieldEmail).
    Update(func(u *ent.UserUpsert) {
        u.SetName("Alice Updated")
    }).
    ID(ctx)

// Do nothing on conflict
userID, err := client.User.Create().
    SetName("Alice").
    SetEmail("alice@example.com").
    OnConflictColumns(user.FieldEmail).
    Ignore().
    ID(ctx)
```

## Create with Hooks

```go
// Hooks are automatically invoked during Save
user, err := client.User.Create().
    SetName("Alice").
    Save(ctx)
    // Triggers BeforeCreate and AfterCreate hooks
```

## Error Handling

```go
user, err := client.User.Create().
    SetName("Alice").
    SetEmail("alice@example.com").
    Save(ctx)

if err != nil {
    if ent.IsConstraintError(err) {
        // Handle duplicate email
        log.Println("Email already exists")
    } else if ent.IsValidationError(err) {
        // Handle validation error
        log.Println("Validation failed")
    } else {
        log.Fatalf("Create failed: %v", err)
    }
}
```
