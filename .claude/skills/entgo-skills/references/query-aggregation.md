# Aggregation Queries

## Count

```go
// Count all users
count, err := client.User.Query().Count(ctx)

// Count with filter
activeCount, err := client.User.Query().
    Where(user.Active(true)).
    Count(ctx)

// Count after traversal
count, err := user.QueryPets().Count(ctx)
```

## Group By

```go
// Group by single field
names, err := client.User.Query().
    GroupBy(user.FieldName).
    Strings(ctx)

// Group by with aggregation
var stats []struct {
    Age   int `json:"age"`
    Count int `json:"count"`
}
err := client.User.Query().
    GroupBy(user.FieldAge).
    Aggregate(ent.Count()).
    Scan(ctx, &stats)

// Group by multiple fields
var result []struct {
    Name  string `json:"name"`
    Age   int    `json:"age"`
    Count int    `json:"count"`
}
err := client.User.Query().
    GroupBy(user.FieldName, user.FieldAge).
    Aggregate(ent.Count()).
    Scan(ctx, &result)
```

## Sum

```go
// Sum all ages
totalAge, err := client.User.Query().
    Aggregate(ent.Sum(user.FieldAge)).
    Int(ctx)

// Sum after group by
var result []struct {
    Status string `json:"status"`
    SumAge int    `json:"sum_age"`
}
err := client.User.Query().
    GroupBy(user.FieldStatus).
    Aggregate(ent.Sum(user.FieldAge)).
    Scan(ctx, &result)
```

## Average

```go
// Average age
avgAge, err := client.User.Query().
    Aggregate(ent.Avg(user.FieldAge)).
    Float64(ctx)

// Average after group by
var result []struct {
    Status string  `json:"status"`
    AvgAge float64 `json:"avg_age"`
}
err := client.User.Query().
    GroupBy(user.FieldStatus).
    Aggregate(ent.Avg(user.FieldAge)).
    Scan(ctx, &result)
```

## Min/Max

```go
// Minimum age
minAge, err := client.User.Query().
    Aggregate(ent.Min(user.FieldAge)).
    Int(ctx)

// Maximum age
maxAge, err := client.User.Query().
    Aggregate(ent.Max(user.FieldAge)).
    Int(ctx)
```

## Multiple Aggregates

```go
var result []struct {
    Status string  `json:"status"`
    Count  int     `json:"count"`
    Min    int     `json:"min"`
    Max    int     `json:"max"`
    Sum    int     `json:"sum"`
    Avg    float64 `json:"avg"`
}
err := client.User.Query().
    GroupBy(user.FieldStatus).
    Aggregate(
        ent.Count(),
        ent.Min(user.FieldAge),
        ent.Max(user.FieldAge),
        ent.Sum(user.FieldAge),
        ent.Avg(user.FieldAge),
    ).
    Scan(ctx, &result)
```

## Custom Aggregations

```go
import "entgo.io/ent/dialect/sql"

// Custom aggregation with SQL
var users []struct {
    ID      int
    Name    string
    Average float64
}
err := client.User.Query().
    GroupBy(user.FieldID, user.FieldName).
    Aggregate(func(s *sql.Selector) string {
        t := sql.Table(pet.Table)
        s.Join(t).On(s.C(user.FieldID), t.C(pet.OwnerColumn))
        return sql.As(sql.Avg(t.C(pet.FieldAge)), "average")
    }).
    Scan(ctx, &users)

// Custom with window functions (PostgreSQL)
var result []struct {
    ID    int
    Name  string
    Rank  int
}
err := client.User.Query().
    Order(ent.Desc(user.FieldScore)).
    Aggregate(func(s *sql.Selector) string {
        return sql.As(sql.RowNumber(), "rank")
    }).
    Scan(ctx, &result)
```

## Aggregation with Edges

```go
// Group by edge
var result []struct {
    OwnerID int `json:"owner_id"`
    Count   int `json:"count"`
}
err := client.Pet.Query().
    GroupBy(pet.OwnerColumn).
    Aggregate(ent.Count()).
    Scan(ctx, &result)

// Complex: Group by related entity
var result []struct {
    Name  string `json:"name"`
    Count int    `json:"count"`
}
err := client.Pet.Query().
    GroupBy(pet.OwnerColumn).
    Aggregate(ent.Count()).
    Scan(ctx, &result)
```
