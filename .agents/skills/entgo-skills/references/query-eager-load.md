# Eager Loading

## Basic Eager Loading

```go
// Load users with their pets
users, err := client.User.Query().
    WithPets().
    All(ctx)

// Access loaded pets
for _, u := range users {
    for _, p := range u.Edges.Pets {
        fmt.Printf("%s has pet %s\n", u.Name, p.Name)
    }
}
```

## Multiple Eager Loads

```go
users, err := client.User.Query().
    WithPets().
    WithGroups().
    WithCard().
    All(ctx)
```

## Conditional Eager Loading

```go
// Load only active pets
users, err := client.User.Query().
    WithPets(func(q *ent.PetQuery) {
        q.Where(pet.Active(true))
    }).
    All(ctx)

// Load with ordering and limit
users, err := client.User.Query().
    WithPets(func(q *ent.PetQuery) {
        q.Where(pet.AgeGT(2))
        q.Order(ent.Desc(pet.FieldAge))
        q.Limit(5)
    }).
    All(ctx)
```

## Nested Eager Loading

```go
// Load users -> pets -> owner (back to user)
users, err := client.User.Query().
    WithPets(func(q *ent.PetQuery) {
        q.WithOwner()
    }).
    All(ctx)

// Load users -> groups -> users (in groups)
users, err := client.User.Query().
    WithGroups(func(q *ent.GroupQuery) {
        q.WithUsers()
        q.Limit(10)
    }).
    All(ctx)

// Deep nesting
admins, err := client.User.Query().
    Where(user.Admin(true)).
    WithPets().
    WithGroups(func(q *ent.GroupQuery) {
        q.Limit(5)
        q.WithUsers(func(uq *ent.UserQuery) {
            uq.WithPets()
        })
    }).
    All(ctx)
```

## N+1 Prevention

```go
// BAD: N+1 problem
users, _ := client.User.Query().All(ctx)
for _, u := range users {
    pets, _ := u.QueryPets().All(ctx)  // Query for each user!
    _ = pets
}

// GOOD: Eager loading
users, _ := client.User.Query().
    WithPets().  // Single query with JOIN
    All(ctx)
```

## Check if Loaded

```go
users, err := client.User.Query().All(ctx)

// Check if pets were eager loaded
for _, u := range users {
    if u.Edges.Pets != nil {
        // Pets were loaded
    } else {
        // Need to query
        pets, _ := u.QueryPets().All(ctx)
        _ = pets
    }
}
```

## Eager Loading with Pagination

```go
users, err := client.User.Query().
    WithPets(func(q *ent.PetQuery) {
        // Pagination within eager load
        q.Offset(0)
        q.Limit(10)
    }).
    Offset(20).  // User pagination
    Limit(10).
    All(ctx)
```
