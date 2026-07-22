# Schema Fields

## Basic Field Types

```go
import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
)

func (User) Fields() []ent.Field {
    return []ent.Field{
        // Boolean
        field.Bool("active").Default(true),

        // Integers
        field.Int("age"),
        field.Int8("tiny"),
        field.Int16("small"),
        field.Int32("medium"),
        field.Int64("large"),
        field.Uint("positive"),

        // Floats
        field.Float("score"),
        field.Float32("rating"),

        // Strings
        field.String("name"),
        field.Text("description"),

        // Time
        field.Time("created_at"),
        field.Time("updated_at"),

        // Binary
        field.Bytes("data"),

        // JSON
        field.JSON("metadata", map[string]interface{}{}),
        field.JSON("tags", []string{}),

        // UUID
        field.UUID("uuid", uuid.UUID{}).Default(uuid.New),

        // Enum
        field.Enum("status").
            Values("active", "inactive", "pending").
            Default("pending"),

        // Other
        field.Strings("labels"),      // []string
        field.Ints("scores"),         // []int
        field.Floats("ratings"),      // []float64
    }
}
```

## Field Constraints

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        // Required field
        field.String("name").
            NotEmpty(),

        // Optional field
        field.String("nickname").
            Optional(),

        // Nullable field
        field.String("phone").
            Optional().
            Nillable(),

        // Unique field
        field.String("email").
            Unique(),

        // Immutable field (can't be updated)
        field.Time("created_at").
            Default(time.Now).
            Immutable(),

        // Default value
        field.String("role").
            Default("user"),

        // Default function
        field.Time("created_at").
            Default(time.Now),

        // Update default
        field.Time("updated_at").
            Default(time.Now).
            UpdateDefault(time.Now),

        // Max length
        field.String("name").
            MaxLen(100),

        // Min length
        field.String("password").
            MinLen(8),

        // Match regex
        field.String("email").
            Match(regexp.MustCompile(`^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$`)),

        // Range
        field.Int("age").
            Range(0, 150),

        // Positive
        field.Int("count").
            Positive(),

        // Non-negative
        field.Int("views").
            NonNegative(),

        // Comment
        field.String("name").
            Comment("User display name"),

        // Storage key (database column name)
        field.String("userName").
            StorageKey("user_name"),

        // Struct tag
        field.String("name").
            StructTag(`json:"name,omitempty"`),

        // Schema type (database-specific)
        field.String("description").
            SchemaType(map[string]string{
                dialect.MySQL: "longtext",
                dialect.Postgres: "text",
            }),
    }
}
```

## Field Validators

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("email").
            Validate(func(s string) error {
                if !strings.Contains(s, "@") {
                    return fmt.Errorf("invalid email format")
                }
                return nil
            }),

        field.Int("age").
            Validate(func(i int) error {
                if i < 0 || i > 150 {
                    return fmt.Errorf("age must be between 0 and 150")
                }
                return nil
            }),
    }
}
```

## Sensitive Fields

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("password").
            Sensitive(),  // Won't be printed or logged
    }
}
```

## Field Annotations

```go
import "entgo.io/ent/schema/annotation"

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name").
            Annotations(
                annotation.Field{
                    StructTag: `json:"name" validate:"required"`,
                },
            ),
    }
}
```
