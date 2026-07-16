# PostgreSQL Specific Features

## Native Enum Type

### Define Enum in SQL

```sql
-- Create custom enum type
CREATE TYPE status AS ENUM ('active', 'inactive', 'pending');
```

### Use in Ent Schema

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/dialect"
    "entgo.io/ent/schema/field"
)

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.Enum("status").
            Values("active", "inactive", "pending").
            SchemaType(map[string]string{
                dialect.Postgres: "status",
            }),
    }
}
```

## Array Types

```go
import "github.com/lib/pq"

func (User) Fields() []ent.Field {
    return []ent.Field{
        // String array
        field.Other("tags", &pq.StringArray{}).
            SchemaType(map[string]string{
                dialect.Postgres: "text[]",
            }),

        // Integer array
        field.Other("scores", &pq.Int32Array{}).
            SchemaType(map[string]string{
                dialect.Postgres: "integer[]",
            }),

        // JSONB array
        field.Other("metadata", &pq.GenericArray{}).
            SchemaType(map[string]string{
                dialect.Postgres: "jsonb[]",
            }),
    }
}
```

### Array Operations

```go
// Contains
client.User.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.P("tags @> ?::text[]", pq.Array([]string{"admin"})))
    }).
    All(ctx)

// Overlap
client.User.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.P("tags && ?::text[]", pq.Array([]string{"premium", "vip"})))
    }).
    All(ctx)
```

## Range Types

```go
import "github.com/jackc/pgtype"

func (Reservation) Fields() []ent.Field {
    return []ent.Field{
        field.Other("duration", &pgtype.Tstzrange{}).
            SchemaType(map[string]string{
                dialect.Postgres: "tstzrange",
            }),
    }
}
```

## JSONB Specific

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.JSON("data", map[string]interface{}{}).
            SchemaType(map[string]string{
                dialect.Postgres: "jsonb",
            }),
    }
}
```

### JSONB Queries

```go
// Contains
client.User.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.P("data @> ?::jsonb", `{"role": "admin"}`))
    }).
    All(ctx)

// Path exists
client.User.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.P("data ? 'email'"))
    }).
    All(ctx)

// Array element exists
client.User.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.P("data->'tags' ? 'vip'"))
    }).
    All(ctx)
```

### GIN Index for JSONB

```go
import "entgo.io/ent/dialect/entsql"

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

## Full Text Search

```go
func (Article) Fields() []ent.Field {
    return []ent.Field{
        field.String("title"),
        field.Text("content"),
        field.String("search_vector").
            SchemaType(map[string]string{
                dialect.Postgres: "tsvector",
            }).
            Optional(),
    }
}
```

### Full Text Search Queries

```go
// Search
client.Article.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.P("search_vector @@ plainto_tsquery('english', ?)", "search term"))
    }).
    All(ctx)

// With ranking
var results []struct {
    ID      int
    Title   string
    Content string
    Rank    float64
}

client.Article.Query().
    Where(func(s *sql.Selector) {
        s.Where(sql.P("search_vector @@ plainto_tsquery('english', ?)", "search term"))
    }).
    Modify(func(s *sql.Selector) {
        rank := sql.P("ts_rank(search_vector, plainto_tsquery('english', ?))", "search term")
        s.Select("*", sql.As(rank, "rank"))
        s.OrderBy(sql.Desc("rank"))
    }).
    Scan(ctx, &results)
```

## UUID

```go
import "github.com/google/uuid"

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.UUID("id", uuid.UUID{}).
            Default(uuid.New).
            Immutable(),

        field.UUID("external_id", uuid.UUID{}).
            Default(uuid.New),
    }
}
```

## CITEXT (Case-Insensitive Text)

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS citext;
```

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("email").
            SchemaType(map[string]string{
                dialect.Postgres: "citext",
            }).
            Unique(),
    }
}
```

## HStore

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS hstore;
```

```go
import "github.com/lib/pq"

func (Product) Fields() []ent.Field {
    return []ent.Field{
        field.Other("attributes", &pq.Hstore{}).
            SchemaType(map[string]string{
                dialect.Postgres: "hstore",
            }),
    }
}
```

## Partitioning

```go
func (Event) Annotations() []schema.Annotation {
    return []schema.Annotation{
        entsql.Annotation{
            Table: "events",
        },
    }
}
```

```sql
-- Create partitioned table manually
CREATE TABLE events (
    id bigint,
    created_at timestamptz,
    data jsonb
) PARTITION BY RANGE (created_at);

CREATE TABLE events_y2024m01 PARTITION OF events
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

## Ltree (Hierarchical Data)

```sql
CREATE EXTENSION IF NOT EXISTS ltree;
```

```go
import "github.com/jackc/pgtype"

func (Category) Fields() []ent.Field {
    return []ent.Field{
        field.Other("path", &pgtype.Ltree{}).
            SchemaType(map[string]string{
                dialect.Postgres: "ltree",
            }),
    }
}
```
