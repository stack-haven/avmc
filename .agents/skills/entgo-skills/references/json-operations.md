# JSON Operations

## JSON Field Definition

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
)

type Tag struct {
    Name    string    `json:"name"`
    Created time.Time `json:"created"`
}

func (User) Fields() []ent.Field {
    return []ent.Field{
        // JSON with map
        field.JSON("metadata", map[string]interface{}{}),

        // JSON with slice
        field.JSON("tags", []string{}),

        // JSON with struct
        field.JSON("profile", Profile{}),

        // JSON with struct slice
        field.JSON("history", []HistoryEntry{}),
    }
}
```

## JSON Predicates

```go
import "entgo.io/ent/dialect/sql/sqljson"

// Equals
client.User.Query().
    Where(sqljson.ValueEQ(user.FieldData, value)).
    All(ctx)

// Not equals
client.User.Query().
    Where(sqljson.ValueNEQ(user.FieldData, value)).
    All(ctx)

// Contains (for arrays)
client.User.Query().
    Where(sqljson.ValueContains(user.FieldTags, "admin")).
    All(ctx)

// Path-based queries
client.User.Query().
    Where(sqljson.ValueEQ(
        user.FieldData,
        "value",
        sqljson.Path("nested", "key"),
    )).
    All(ctx)

// Dot path notation
client.User.Query().
    Where(sqljson.ValueEQ(
        user.FieldData,
        "value",
        sqljson.DotPath("nested.key"),
    )).
    All(ctx)

// Comparison operators
client.User.Query().
    Where(sqljson.ValueGT(user.FieldData, 100, sqljson.Path("count"))).
    All(ctx)

client.User.Query().
    Where(sqljson.ValueGTE(user.FieldData, 18, sqljson.Path("age"))).
    All(ctx)
```

## JSON Array Operations

```go
// Check if array contains value
client.User.Query().
    Where(sqljson.ValueContains(user.FieldTags, "premium")).
    All(ctx)

// Check if array contains any of the values
client.User.Query().
    Where(sqljson.ValueContains(user.FieldTags, []string{"admin", "moderator"})).
    All(ctx)

// Array length (PostgreSQL)
client.User.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.GT(
            sqljson.Length(user.FieldTags),
            0,
        ))
    }).
    All(ctx)
```

## JSON Update Operations

```go
// Append to JSON array
client.User.Update().
    Where(user.ID(id)).
    Modify(func(u *sql.UpdateBuilder) {
        sqljson.Append(u, user.FieldTags, "new-tag")
    }).
    Exec(ctx)

// Append with path
client.User.Update().
    Where(user.ID(id)).
    Modify(func(u *sql.UpdateBuilder) {
        sqljson.Append(u, user.FieldData, "value", sqljson.Path("array"))
    }).
    Exec(ctx)

// Set JSON value
client.User.UpdateOneID(id).
    SetMetadata(map[string]interface{}{
        "key": "value",
        "nested": map[string]interface{}{
            "inner": "data",
        },
    }).
    Save(ctx)
```

## PostgreSQL JSONB

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.JSON("data", map[string]interface{}{}).
            SchemaType(map[string]string{
                dialect.MySQL:    "json",
                dialect.Postgres: "jsonb",
            }),
    }
}

// JSONB-specific queries (PostgreSQL)
client.User.Query().
    Where(func(s *sql.Selector) {
        // @> operator (contains)
        s.Where(sql.P("data @> ?::jsonb", `{"status": "active"}`))
    }).
    All(ctx)

// GIN index for JSONB
func (User) Indexes() []ent.Index {
    return []ent.Index{
        index.Fields("data").
            Annotations(
                entsql.IndexTypes(map[string]string{
                    dialect.Postgres: "GIN",
                }),
            ),
    }
}
```

## JSON Aggregation (PostgreSQL)

```go
// Aggregate JSON array
var results []struct {
    ID   int
    Data json.RawMessage
}

client.User.Query().
    GroupBy(user.FieldID).
    Aggregate(func(s *sql.Selector) string {
        return sql.As(
            sqljson.Agg(user.FieldData),
            "data",
        )
    }).
    Scan(ctx, &results)
```
