# Delete Operations

## Delete Single Entity

```go
// Delete by ID
err := client.User.DeleteOneID(id).Exec(ctx)

// Check if deleted
n, err := client.User.DeleteOneID(id).Exec(ctx)
// n = 0 if not found, 1 if deleted

// DeleteX (panic on error)
client.User.DeleteOneID(id).ExecX(ctx)
```

## Delete with Get

```go
// Get and delete
user, err := client.User.Get(ctx, id)
if err != nil {
    return err
}
err := client.User.DeleteOne(user).Exec(ctx)
```

## Batch Delete

```go
// Delete multiple records
n, err := client.User.Delete().
    Where(user.AgeLT(18)).
    Exec(ctx)

// Delete all (be careful!)
n, err := client.User.Delete().
    Where(user.IDGT(0)).
    Exec(ctx)
```

## Soft Delete Pattern

```go
// Instead of deleting, set deleted_at
func SoftDeleteUser(ctx context.Context, client *ent.Client, id int) error {
    _, err := client.User.UpdateOneID(id).
        SetDeletedAt(time.Now()).
        Save(ctx)
    return err
}

// Query only non-deleted
users, err := client.User.Query().
    Where(user.DeletedAtIsNil()).
    All(ctx)
```

## Delete with Hooks

```go
// Delete triggers hooks
err := client.User.DeleteOneID(id).Exec(ctx)
// Triggers BeforeDelete and AfterDelete hooks
```

## Cascade Delete

```go
// Using edge annotation
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("pets", Pet.Type).
            Annotations(
                annotation.OnDelete(annotation.Cascade),
            ),
    }
}

// Manual cascade
deleteUserAndPets := func(ctx context.Context, client *ent.Client, userID int) error {
    return ent.WithTx(ctx, client, func(tx *ent.Tx) error {
        // Delete pets first
        _, err := tx.Pet.Delete().
            Where(pet.HasOwnerWith(user.ID(userID))).
            Exec(ctx)
        if err != nil {
            return err
        }

        // Delete user
        return tx.User.DeleteOneID(userID).Exec(ctx)
    })
}
```

## Delete with Constraints

```go
// Handle constraint errors
err := client.User.DeleteOneID(id).Exec(ctx)
if err != nil {
    if ent.IsConstraintError(err) {
        // User is referenced by other entities
        return fmt.Errorf("cannot delete: user has related records")
    }
    return err
}
```

## Delete and Return

```go
// Ent doesn't support RETURNING directly
// You need to query first, then delete
user, err := client.User.Get(ctx, id)
if err != nil {
    return nil, err
}

err = client.User.DeleteOne(user).Exec(ctx)
if err != nil {
    return nil, err
}

return user, nil  // Return the deleted user
```
