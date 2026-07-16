# First Schema

## Create User Schema

```bash
go run -mod=mod entgo.io/ent/cmd/ent new User
```

Generated file: `ent/schema/user.go`

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
)

// User holds the schema definition for the User entity.
type User struct {
    ent.Schema
}

// Fields of the User.
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.Int("age").
            Positive(),
        field.String("name").
            Default("unknown"),
    }
}

// Edges of the User.
func (User) Edges() []ent.Edge {
    return nil
}
```

## Add More Fields

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.Int("id"),
        field.String("name").
            NotEmpty().
            MaxLen(100),
        field.String("email").
            Unique(),
        field.Int("age").
            Positive().
            Range(0, 150),
        field.Bool("active").
            Default(true),
        field.Time("created_at").
            Default(time.Now).
            Immutable(),
    }
}
```

## Create Pet Schema with Relation

```bash
go run -mod=mod entgo.io/ent/cmd/ent new Pet
```

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/edge"
    "entgo.io/ent/schema/field"
)

type Pet struct {
    ent.Schema
}

func (Pet) Fields() []ent.Field {
    return []ent.Field{
        field.String("name"),
        field.Enum("species").
            Values("dog", "cat", "bird"),
    }
}

func (Pet) Edges() []ent.Edge {
    return []ent.Edge{
        edge.From("owner", User.Type).
            Ref("pets").
            Unique(),
    }
}
```

Update User schema to add the reverse edge:

```go
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("pets", Pet.Type),
    }
}
```

## Generate Code

```bash
go generate ./ent
```

## Use the Generated Client

```go
package main

import (
    "context"
    "log"

    "myproject/ent"
    "myproject/ent/user"
    _ "github.com/mattn/go-sqlite3"
)

func main() {
    client, err := ent.Open("sqlite3", "file:ent.db?_fk=1")
    if err != nil {
        log.Fatalf("failed opening connection: %v", err)
    }
    defer client.Close()

    ctx := context.Background()

    // Run migration
    if err := client.Schema.Create(ctx); err != nil {
        log.Fatalf("failed creating schema: %v", err)
    }

    // Create user
    u, err := client.User.Create().
        SetName("Alice").
        SetEmail("alice@example.com").
        SetAge(30).
        Save(ctx)
    if err != nil {
        log.Fatalf("failed creating user: %v", err)
    }
    log.Printf("created user: %v", u)

    // Query user
    found, err := client.User.Query().
        Where(user.Email("alice@example.com")).
        Only(ctx)
    if err != nil {
        log.Fatalf("failed querying user: %v", err)
    }
    log.Printf("found user: %v", found)
}
```
