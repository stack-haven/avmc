# Schema Indexes

## Single Field Index

```go
import (
    "entgo.io/ent/schema/index"
)

func (User) Indexes() []ent.Index {
    return []ent.Index{
        // Non-unique index
        index.Fields("age"),

        // Unique index
        index.Fields("email").Unique(),
    }
}
```

## Composite Index

```go
func (User) Indexes() []ent.Index {
    return []ent.Index{
        // Composite unique index
        index.Fields("first_name", "last_name").Unique(),

        // Composite non-unique index
        index.Fields("status", "created_at"),
    }
}
```

## Edge Index

```go
func (Pet) Indexes() []ent.Index {
    return []ent.Index{
        // Index on edge (foreign key)
        index.Edges("owner"),

        // Composite index with edge
        index.Fields("name").
            Edges("owner").
            Unique(),
    }
}
```

## Index Options

```go
func (User) Indexes() []ent.Index {
    return []ent.Index{
        // Index name (explicit)
        index.Fields("email").
            Unique().
            StorageKey("idx_user_email"),

        // Comment
        index.Fields("phone").
            Comment("For phone lookup"),

        // Conditional index (partial index)
        index.Fields("deleted_at").
            Where(index.FieldIsNull("deleted_at")),

        // Schema type (database-specific)
        index.Fields("name").
            SchemaType(map[string]string{
                dialect.MySQL: "FULLTEXT",
                dialect.Postgres: "GIN",
            }),
    }
}
```

## Index Storage Key

```go
func (User) Indexes() []ent.Index {
    return []ent.Index{
        // Explicit index name
        index.Fields("email").
            StorageKey("user_email_idx"),

        // Composite with explicit name
        index.Fields("first_name", "last_name").
            StorageKey("user_name_idx"),
    }
}
```
