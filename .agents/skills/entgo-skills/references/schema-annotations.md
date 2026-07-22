# Schema Annotations

## GraphQL Annotations

```go
import "entgo.io/contrib/entgql"

func (User) Annotations() []schema.Annotation {
    return []schema.Annotation{
        entgql.QueryField(),
        entgql.Mutations(
            entgql.MutationCreate(),
            entgql.MutationUpdate(),
        ),
    }
}
```

## gRPC Annotations

```go
import "entgo.io/contrib/entproto"

func (User) Annotations() []schema.Annotation {
    return []schema.Annotation{
        entproto.Message(),
        entproto.Service(),
    }
}

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name").
            Annotations(
                entproto.Field(2),
            ),
    }
}
```

## OpenAPI Annotations

```go
func (User) Annotations() []schema.Annotation {
    return []schema.Annotation{
        entswagger.Schemas(
            entswagger.WithTitle("User"),
            entswagger.WithDescription("A user in the system"),
        ),
    }
}
```

## Multi-annotation Example

```go
func (User) Annotations() []schema.Annotation {
    return []schema.Annotation{
        // GraphQL
        entgql.QueryField(),
        entgql.Mutations(
            entgql.MutationCreate(),
            entgql.MutationUpdate(),
        ),
        // gRPC
        entproto.Message(),
        entproto.Service(),
        // OpenAPI
        entswagger.Schemas(
            entswagger.WithDescription("System user entity"),
        ),
    }
}
```

## Field Annotations

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("id").
            Annotations(
                entproto.Field(1),
                entgql.OrderField("ID"),
            ),
        field.String("name").
            Annotations(
                entproto.Field(2),
                entgql.OrderField("NAME"),
                entswagger.WithDescription("User's full name"),
            ),
    }
}
```

## Edge Annotations

```go
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("pets", Pet.Type).
            Annotations(
                entgql.Bind(),
                entproto.Field(5),
            ),
    }
}
```
