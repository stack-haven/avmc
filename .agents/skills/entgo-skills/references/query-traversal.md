# Graph Traversal Queries

## Basic Edge Traversal

```go
// From user to pets (O2M)
pets, err := user.QueryPets().All(ctx)

// From pet to owner (M2O)
owner, err := pet.QueryOwner().Only(ctx)

// From user to groups (M2M)
groups, err := user.QueryGroups().All(ctx)

// From group to users (M2M)
users, err := group.QueryUsers().All(ctx)

// From user to card (O2O)
card, err := user.QueryCard().Only(ctx)
```

## Chained Traversal

```go
// User -> Pets -> Owner (back to another user)
otherOwners, err := user.QueryPets().
    QueryOwner().
    All(ctx)

// User -> Groups -> Users (friends in same groups)
friends, err := user.QueryGroups().
    QueryUsers().
    Where(user.IDNEQ(user.ID)).  // Exclude self
    All(ctx)

// Deep traversal: User -> Friends -> Pets -> Owner
owners, err := user.QueryFriends().
    QueryPets().
    QueryOwner().
    All(ctx)
```

## Traversal with Conditions

```go
// User's pets that are older than 5
oldPets, err := user.QueryPets().
    Where(pet.AgeGT(5)).
    All(ctx)

// User's active groups
activeGroups, err := user.QueryGroups().
    Where(group.Active(true)).
    All(ctx)

// User's friends who have dogs
dogOwners, err := user.QueryFriends().
    Where(
        user.HasPetsWith(
            pet.Species("dog"),
        ),
    ).
    All(ctx)
```

## Reverse Traversal

```go
// Find pets owned by users in a specific group
pets, err := client.Group.Query().
    Where(group.ID(groupID)).
    QueryUsers().
    QueryPets().
    All(ctx)

// Find all groups containing a specific pet's owner
groups, err := client.Pet.Query().
    Where(pet.ID(petID)).
    QueryOwner().
    QueryGroups().
    All(ctx)

// Find users who own pets named "Fluffy"
owners, err := client.Pet.Query().
    Where(pet.Name("Fluffy")).
    QueryOwner().
    All(ctx)
```

## Self-Referencing Traversal

```go
// User's friends
friends, err := user.QueryFriends().All(ctx)

// User's friends' friends
friendsOfFriends, err := user.QueryFriends().
    QueryFriends().
    All(ctx)

// Exclude self from friends of friends
fof, err := user.QueryFriends().
    QueryFriends().
    Where(user.IDNEQ(user.ID)).
    All(ctx)

// Common friends between two users
commonFriends, err := user1.QueryFriends().
    Where(
        user.IDIn(
            client.User.Query().
                Where(user.ID(user2.ID)).
                QueryFriends().
                QueryIDs(ctx)...,
        ),
    ).
    All(ctx)
```

## Traversal Aggregation

```go
// Count user's pets
petCount, err := user.QueryPets().Count(ctx)

// Get average age of user's pets
var result struct {
    Average float64
}
err := user.QueryPets().
    Aggregate(func(s *sql.Selector) string {
        return sql.As(sql.Avg(s.C(pet.FieldAge)), "average")
    }).
    Scan(ctx, &result)

// Check if user has any pets
hasPets, err := user.QueryPets().Exist(ctx)
```

## Complex Traversal Example

```go
// Find all pets of friends in the same groups as a user
func GetFriendsPets(ctx context.Context, user *ent.User) ([]*ent.Pet, error) {
    return user.QueryGroups().  // Get user's groups
        QueryUsers().           // Get users in those groups
        Where(
            user.IDNEQ(user.ID), // Exclude self
            user.HasFriendsWith(user.ID(user.ID)), // Who are friends with user
        ).
        QueryPets().            // Get their pets
        Where(pet.Active(true)). // Only active pets
        All(ctx)
}
```

## Traversal with Pagination

```go
// Paginated friends
friends, err := user.QueryFriends().
    Order(ent.Asc(user.FieldName)).
    Offset(20).
    Limit(10).
    All(ctx)

// Paginated pets with ordering
pets, err := user.QueryPets().
    Order(ent.Desc(pet.FieldAge)).
    Limit(5).
    All(ctx)
```
