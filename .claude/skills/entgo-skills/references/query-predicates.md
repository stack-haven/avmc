# Query Predicates

## Comparison Operators

```go
// Equality
user.AgeEQ(30)       // age = 30
user.AgeNEQ(30)      // age != 30

// Numeric comparison
user.AgeGT(30)       // age > 30
user.AgeGTE(30)      // age >= 30
user.AgeLT(30)       // age < 30
user.AgeLTE(30)      // age <= 30

// Range
user.AgeIn(20, 30, 40)     // age IN (20, 30, 40)
user.AgeNotIn(50, 60)      // age NOT IN (50, 60)
```

## String Predicates

```go
// Case-sensitive
user.Name("Alice")              // name = 'Alice'
user.NameContains("ali")        // name LIKE '%ali%'
user.NameHasPrefix("Al")        // name LIKE 'Al%'
user.NameHasSuffix("ce")        // name LIKE '%ce'

// Case-insensitive
user.NameEqualFold("alice")     // LOWER(name) = LOWER('alice')
user.NameContainsFold("ALI")    // LOWER(name) LIKE LOWER('%ALI%')

// Regex (database-specific)
user.NameMatch("^A.*")          // name REGEXP '^A.*'
```

## Null Predicates

```go
user.DeletedAtIsNil()      // deleted_at IS NULL
user.DeletedAtNotNil()     // deleted_at IS NOT NULL

user.NicknameIsNil()       // nickname IS NULL
user.NicknameNotNil()      // nickname IS NOT NULL
```

## Boolean Predicates

```go
user.Active(true)          // active = true
user.Active(false)         // active = false
```

## Logical Operators

```go
// AND (implicit)
client.User.Query().
    Where(
        user.AgeGT(18),
        user.Active(true),
    )

// Explicit AND
client.User.Query().
    Where(
        user.And(
            user.AgeGT(18),
            user.Active(true),
        ),
    )

// OR
client.User.Query().
    Where(
        user.Or(
            user.AgeLT(18),
            user.AgeGT(65),
        ),
    )

// NOT
client.User.Query().
    Where(
        user.Not(user.Active(true)),
    )

// Complex
client.User.Query().
    Where(
        user.And(
            user.Active(true),
            user.Or(
                user.AgeLT(18),
                user.AgeGT(65),
            ),
        ),
    )
```

## Edge Predicates

```go
// Has edge
user.HasPets()                    // has pets
user.HasGroups()                  // has groups

// Has edge with conditions
user.HasPetsWith(pet.AgeGT(5))    // has pets with age > 5

// Has no edge
user.Not(user.HasPets())

// Edge count
user.PetsNotNil()                 // has at least one pet
```

## Time Predicates

```go
now := time.Now()

user.CreatedAtEQ(now)
user.CreatedAtGT(now)
user.CreatedAtLT(now)
user.CreatedAtGTE(now)
user.CreatedAtLTE(now)
user.CreatedAtIn(now.Add(-time.Hour), now)
```

## Custom SQL Predicates

```go
import "entgo.io/ent/dialect/sql"

// Custom predicate
users, err := client.User.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.Like(user.FieldName, "_B%"))
    }).
    All(ctx)

// Custom with EXISTS
users, err := client.User.Query().
    Where(func(s *sql.Selector) {
        t := sql.Table(pet.Table)
        p := sql.And(
            sql.EQ(t.C(pet.FieldAge), 5),
            sql.ColumnsEQ(s.C(user.FieldID), t.C(pet.OwnerColumn)),
        )
        s.Where(sql.Exists(sql.Select().From(t).Where(p)))
    }).
    All(ctx)

// Custom with IN
users, err := client.User.Query().
    Where(func(s *sql.Selector) {
        t := sql.Table(pet.Table)
        s.Where(
            sql.In(
                s.C(user.FieldID),
                sql.Select(t.C(pet.OwnerColumn)).From(t).Where(sql.EQ(t.C(pet.FieldName), "Fluffy")),
            ),
        )
    }).
    All(ctx)
```
