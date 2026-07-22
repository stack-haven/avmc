# Update Operations

## Update Single Entity

```go
// Update one by ID
user, err := client.User.UpdateOneID(id).
    SetName("New Name").
    SetAge(31).
    Save(ctx)

// UpdateX (panic on error)
user := client.User.UpdateOneID(id).
    SetName("New Name").
    SaveX(ctx)
```

## Update with Get

```go
// Get and update
user, err := client.User.Get(ctx, id)
if err != nil {
    return err
}

updated, err := user.Update().
    SetName("New Name").
    Save(ctx)
```

## Batch Update

```go
// Update multiple records
n, err := client.User.Update().
    Where(user.AgeLT(18)).
    SetStatus("minor").
    Save(ctx)
```

## Update Operators

```go
// Set value
user.UpdateOneID(id).SetAge(30)

// Set nillable
user.UpdateOneID(id).SetNillableNickname(ptr("Nick"))

// Clear optional field
user.UpdateOneID(id).ClearNickname()

// Add to numeric field
user.UpdateOneID(id).AddAge(1)       // age = age + 1
user.UpdateOneID(id).AddCredits(100) // credits = credits + 100

// Append to JSON
user.UpdateOneID(id).AppendTags("new-tag")

// Remove from JSON
user.UpdateOneID(id).RemoveTags("old-tag")
```

## Update with Relationships

```go
// Add relationships
user, err := client.User.UpdateOneID(id).
    AddPetIDs(1, 2).
    Save(ctx)

// Remove relationships
user, err := client.User.UpdateOneID(id).
    RemovePetIDs(3, 4).
    Save(ctx)

// Clear all relationships
user, err := client.User.UpdateOneID(id).
    ClearPets().
    Save(ctx)

// Set relationship (replaces existing)
user, err := client.User.UpdateOneID(id).
    SetPets(pets...).
    Save(ctx)
```

## Upsert Pattern

```go
// Update or create
userID, err := client.User.Create().
    SetName("Alice").
    SetEmail("alice@example.com").
    OnConflictColumns(user.FieldEmail).
    Update(func(u *ent.UserUpsert) {
        u.SetName("Alice Updated")
        u.AddAge(1)
    }).
    ID(ctx)
```

## Conditional Update

```go
// Only update if conditions match
user, err := client.User.UpdateOneID(id).
    SetName("New Name").
    Where(
        user.Version(currentVersion),
    ).
    Save(ctx)
```

## Update Hooks

```go
// Update automatically triggers hooks
user, err := client.User.UpdateOneID(id).
    SetName("Alice").
    Save(ctx)
    // Triggers BeforeUpdate and AfterUpdate hooks
```

## Error Handling

```go
user, err := client.User.UpdateOneID(id).
    SetEmail("new@example.com").
    Save(ctx)

if err != nil {
    if ent.IsConstraintError(err) {
        // Handle unique constraint violation
        return fmt.Errorf("email already exists")
    }
    if ent.IsNotFound(err) {
        // Handle not found
        return fmt.Errorf("user not found")
    }
    return err
}
```

## Update Multiple Fields

```go
user, err := client.User.UpdateOneID(id).
    SetName("New Name").
    SetEmail("new@example.com").
    SetAge(30).
    SetActive(true).
    SetUpdatedAt(time.Now()).
    Save(ctx)
```
