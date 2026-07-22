# GraphQL Integration (entgql)

## Installation

```bash
go get entgo.io/contrib/entgql
```

## Setup entgql Extension

```go
// ent/entc.go
//go:build ignore

package main

import (
    "log"
    "entgo.io/ent/entc"
    "entgo.io/ent/entc/gen"
    "entgo.io/contrib/entgql"
)

func main() {
    ex, err := entgql.NewExtension(
        // Generate GraphQL schema
        entgql.WithSchemaGenerator(),
        // Output path for GraphQL schema
        entgql.WithSchemaPath("ent.graphql"),
        // gqlgen config path
        entgql.WithConfigPath("gqlgen.yml"),
    )
    if err != nil {
        log.Fatalf("creating entgql extension: %v", err)
    }

    opts := []entc.Option{
        entc.Extensions(ex),
    }

    if err := entc.Generate("./ent/schema", &gen.Config{}, opts...); err != nil {
        log.Fatalf("running ent codegen: %v", err)
    }
}
```

## Schema Annotations

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "entgo.io/contrib/entgql"
)

func (User) Annotations() []schema.Annotation {
    return []schema.Annotation{
        // Generate Query and Mutation fields
        entgql.QueryField(),
        entgql.Mutations(
            entgql.MutationCreate(),
            entgql.MutationUpdate(),
            entgql.MutationDelete(),
        ),
    }
}

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name").
            Annotations(
                entgql.OrderField("NAME"),
            ),
        field.Int("age").
            Annotations(
                entgql.OrderField("AGE"),
            ),
    }
}
```

## Generated GraphQL Schema

```graphql
type User implements Node {
  id: ID!
  name: String!
  age: Int!
}

input CreateUserInput {
  name: String!
  age: Int!
}

input UpdateUserInput {
  name: String
  age: Int
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): ID!
}

type Query {
  user(id: ID!): User
  users(
    after: Cursor
    first: Int
    before: Cursor
    last: Int
    orderBy: UserOrder
    where: UserWhereInput
  ): UserConnection!
}
```

## GraphQL Server Setup

```go
package main

import (
    "context"
    "log"
    "net/http"

    "myapp/ent"
    "myapp/ent/migrate"

    "entgo.io/ent/dialect"
    "github.com/99designs/gqlgen/graphql/handler"
    "github.com/99designs/gqlgen/graphql/playground"
    _ "github.com/mattn/go-sqlite3"
)

func main() {
    // Create ent client
    client, err := ent.Open(dialect.SQLite, "file:ent?mode=memory&cache=shared&_fk=1")
    if err != nil {
        log.Fatal("opening ent client", err)
    }

    // Run migrations
    if err := client.Schema.Create(
        context.Background(),
        migrate.WithGlobalUniqueID(true),
    ); err != nil {
        log.Fatal("running schema migration", err)
    }

    // Create GraphQL server
    srv := handler.NewDefaultServer(NewSchema(client))

    http.Handle("/", playground.Handler("GraphQL Playground", "/query"))
    http.Handle("/query", srv)

    log.Println("listening on :8081")
    if err := http.ListenAndServe(":8081", nil); err != nil {
        log.Fatal("http server terminated", err)
    }
}
```

## Resolver Implementation

```go
package myapp

import (
    "context"
    "myapp/ent"
    "github.com/99designs/gqlgen/graphql"
)

type Resolver struct {
    client *ent.Client
}

func NewSchema(client *ent.Client) graphql.ExecutableSchema {
    return NewExecutableSchema(Config{
        Resolvers: &Resolver{client: client},
    })
}

// User resolver
func (r *Resolver) User() UserResolver {
    return &userResolver{r}
}

type userResolver struct{ *Resolver }

func (r *userResolver) Pets(ctx context.Context, obj *ent.User) ([]*ent.Pet, error) {
    return obj.QueryPets().All(ctx)
}
```

## Transactional Mutations

```go
package myapp

import (
    "context"
    "entgo.io/contrib/entgql"
)

func main() {
    srv := handler.NewDefaultServer(NewSchema(client))

    // Add transaction middleware
    srv.Use(entgql.Transactioner{
        TxOpener: client,
    })
}

// In resolver
func (r *mutationResolver) CreateUser(ctx context.Context, input ent.CreateUserInput) (*ent.User, error) {
    // Get transactional client from context
    client := ent.FromContext(ctx)
    return client.User.Create().SetInput(input).Save(ctx)
}
```
