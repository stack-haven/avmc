# Pagination

## Offset-Based Pagination

```go
// Basic pagination
users, err := client.User.Query().
    Order(ent.Asc(user.FieldID)).
    Offset(0).   // Skip 0 rows
    Limit(20).   // Return 20 rows
    All(ctx)

// Page 2
users, err := client.User.Query().
    Order(ent.Asc(user.FieldID)).
    Offset(20).  // Skip 20 rows
    Limit(20).   // Return 20 rows
    All(ctx)

// With filter
users, err := client.User.Query().
    Where(user.Active(true)).
    Order(ent.Desc(user.FieldCreatedAt)).
    Offset(page * pageSize).
    Limit(pageSize).
    All(ctx)
```

## Cursor-Based Pagination

```go
// First page
users, err := client.User.Query().
    Order(ent.Asc(user.FieldID)).
    Limit(21).  // Request 1 extra to check for next page
    All(ctx)

// Check if there's a next page
hasNextPage := len(users) > 20
if hasNextPage {
    users = users[:20]  // Remove the extra item
}

// Next page using last ID as cursor
lastID := users[len(users)-1].ID
nextUsers, err := client.User.Query().
    Where(user.IDGT(lastID)).  // Get records after cursor
    Order(ent.Asc(user.FieldID)).
    Limit(21).
    All(ctx)
```

## Pagination Helper

```go
type Pagination struct {
    Limit  int
    Offset int
    Cursor int
}

type PaginatedResult[T any] struct {
    Data       []T
    Total      int
    HasNext    bool
    NextCursor int
}

func ListUsers(ctx context.Context, client *ent.Client, p Pagination) (*PaginatedResult[*ent.User], error) {
    query := client.User.Query()

    // Get total count
    total, err := query.Count(ctx)
    if err != nil {
        return nil, err
    }

    // Apply cursor if provided
    if p.Cursor > 0 {
        query = query.Where(user.IDGT(p.Cursor))
    }

    // Apply offset
    if p.Offset > 0 {
        query = query.Offset(p.Offset)
    }

    // Get data with limit+1 to check for next page
    limit := p.Limit
    if limit == 0 {
        limit = 20
    }

    users, err := query.
        Order(ent.Asc(user.FieldID)).
        Limit(limit + 1).
        All(ctx)
    if err != nil {
        return nil, err
    }

    // Check for next page
    hasNext := len(users) > limit
    if hasNext {
        users = users[:limit]
    }

    var nextCursor int
    if hasNext && len(users) > 0 {
        nextCursor = users[len(users)-1].ID
    }

    return &PaginatedResult[*ent.User]{
        Data:       users,
        Total:      total,
        HasNext:    hasNext,
        NextCursor: nextCursor,
    }, nil
}
```

## Relay-Style Pagination

```go
type PageInfo struct {
    HasNextPage     bool
    HasPreviousPage bool
    StartCursor     string
    EndCursor       string
}

type Connection[T any] struct {
    Edges      []Edge[T]
    Nodes      []T
    PageInfo   PageInfo
    TotalCount int
}

type Edge[T any] struct {
    Node   T
    Cursor string
}

func encodeCursor(id int) string {
    return base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("cursor:%d", id)))
}

func decodeCursor(cursor string) (int, error) {
    b, err := base64.StdEncoding.DecodeString(cursor)
    if err != nil {
        return 0, err
    }
    var id int
    _, err = fmt.Sscanf(string(b), "cursor:%d", &id)
    return id, err
}
```

## Pagination with Eager Loading

```go
users, err := client.User.Query().
    WithPets(func(q *ent.PetQuery) {
        q.Order(ent.Desc(pet.FieldAge))
        q.Limit(5)  // Limit pets per user
    }).
    Order(ent.Asc(user.FieldName)).
    Offset(0).
    Limit(20).
    All(ctx)
```
