# Query Operations

## Basic Query

```go
// Get all
users, err := client.User.Query().All(ctx)

// Get first
user, err := client.User.Query().First(ctx)

// Get single (error if 0 or >1)
user, err := client.User.Query().Only(ctx)

// Get by ID
user, err := client.User.Get(ctx, id)

// Get by ID (panic if not found)
user := client.User.GetX(ctx, id)
```

## Query with Predicates

```go
// Simple where
users, err := client.User.Query().
    Where(user.Name("Alice")).
    All(ctx)

// Multiple conditions (AND)
users, err := client.User.Query().
    Where(
        user.AgeGT(18),
        user.Active(true),
    ).
    All(ctx)

// OR condition
users, err := client.User.Query().
    Where(
        user.Or(
            user.AgeLT(18),
            user.AgeGT(65),
        ),
    ).
    All(ctx)

// Complex conditions
users, err := client.User.Query().
    Where(
        user.And(
            user.NameContains("ali"),
            user.Or(
                user.AgeGTE(18),
                user.HasParent(),
            ),
        ),
    ).
    All(ctx)
```

## Common Predicates

```go
// Equality
user.AgeEQ(30)           // =
user.AgeNEQ(30)          // !=

// Comparison
user.AgeGT(30)           // >
user.AgeGTE(30)          // >=
user.AgeLT(30)           // <
user.AgeLTE(30)          // <=

// Range
user.AgeIn(20, 30, 40)   // IN (20, 30, 40)
user.AgeNotIn(50, 60)    // NOT IN

// String matching
user.NameContains("ali")    // LIKE '%ali%'
user.NameHasPrefix("Al")    // LIKE 'Al%'
user.NameHasSuffix("ce")    // LIKE '%ce'
user.NameEqualFold("ALICE") // case-insensitive

// Null checks
user.DeletedAtIsNil()       // IS NULL
user.DeletedAtNotNil()      // IS NOT NULL

// Edge predicates
user.HasPets()              // has pets
user.HasPetsWith(pet.AgeGT(5))  // has pets with age > 5
```

## Sorting

```go
// Ascending
users, err := client.User.Query().
    Order(ent.Asc(user.FieldName)).
    All(ctx)

// Descending
users, err := client.User.Query().
    Order(ent.Desc(user.FieldAge)).
    All(ctx)

// Multiple sorts
users, err := client.User.Query().
    Order(ent.Desc(user.FieldStatus)).
    Order(ent.Asc(user.FieldName)).
    All(ctx)
```

## Pagination

```go
// Offset and limit
users, err := client.User.Query().
    Offset(20).
    Limit(10).
    All(ctx)
```

## Selecting Fields

```go
// Select specific fields
names, err := client.User.Query().
    Select(user.FieldName).
    Strings(ctx)

// Scan into struct
var results []struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}
err := client.User.Query().
    Select(user.FieldID, user.FieldName).
    Scan(ctx, &results)
```

## Aggregation

```go
// Count
count, err := client.User.Query().Count(ctx)
count, err := client.User.Query().
    Where(user.Active(true)).
    Count(ctx)

// Group by
var stats []struct {
    Age   int `json:"age"`
    Count int `json:"count"`
}
err := client.User.Query().
    GroupBy(user.FieldAge).
    Aggregate(ent.Count()).
    Scan(ctx, &stats)
```

## Existence Check

```go
exists, err := client.User.Query().
    Where(user.Email("alice@example.com")).
    Exist(ctx)
```

## Query Modifiers

```go
// Distinct
users, err := client.User.Query().Unique(false).All(ctx)

// Lock for update (MySQL/PostgreSQL)
user, err := client.User.Query().
    Where(user.ID(id)).
    ForUpdate().
    Only(ctx)
```
