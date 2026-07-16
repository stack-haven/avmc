# Project Structure

## Recommended Layout

```
myapp/
├── cmd/
│   └── server/
│       └── main.go           # Application entry point
├── ent/
│   ├── schema/               # Schema definitions
│   │   ├── user.go
│   │   ├── pet.go
│   │   └── mixin/
│   │       └── timestamp.go
│   ├── generate.go           # go:generate directive
│   └── ent.go                # (generated)
├── internal/
│   ├── db/                   # Database initialization
│   │   └── client.go
│   ├── service/              # Business logic
│   │   └── user_service.go
│   └── viewer/               # Viewer context
│       └── viewer.go
├── migrations/               # Versioned migrations
│   └── *.sql
├── go.mod
└── go.sum
```

## Schema Organization

```go
// ent/schema/user.go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/edge"
    "entgo.io/ent/schema/field"
    "entgo.io/ent/schema/index"
    "myapp/ent/schema/mixin"
)

// User holds the schema definition for the User entity.
type User struct {
    ent.Schema
}

// Mixin of the User.
func (User) Mixin() []ent.Mixin {
    return []ent.Mixin{
        mixin.TimeMixin{},
        mixin.AuditMixin{},
    }
}

// Fields of the User.
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name").
            NotEmpty().
            MaxLen(100),
        field.String("email").
            Unique(),
    }
}

// Edges of the User.
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("pets", Pet.Type),
    }
}

// Indexes of the User.
func (User) Indexes() []ent.Index {
    return []ent.Index{
        index.Fields("email").Unique(),
    }
}
```

## Naming Conventions

### Schema Names
- Use PascalCase for entity names: `User`, `OrderItem`
- Use singular nouns: `User` not `Users`

### Field Names
- Use snake_case in Go: `created_at`, `first_name`
- This becomes `CreatedAt` in generated code

### Edge Names
- Use lowercase: `pets`, `owner`, `groups`
- Use singular for O2O and M2O: `owner`, `card`
- Use plural for O2M and M2M: `pets`, `friends`

### Variable Names
```go
// ✅ Good
user, err := client.User.Create().Save(ctx)
pets, err := user.QueryPets().All(ctx)

// ❌ Bad
u, _ := client.User.Create().Save(ctx)
p, _ := u.QueryPets().All(ctx)
```

## Package Organization

### Database Client

```go
// internal/db/client.go
package db

import (
    "myapp/ent"
)

type Client struct {
    *ent.Client
}

func New(dsn string) (*Client, error) {
    client, err := ent.Open("mysql", dsn)
    if err != nil {
        return nil, err
    }
    return &Client{client}, nil
}
```

### Service Layer

```go
// internal/service/user.go
package service

type UserService struct {
    client *ent.Client
}

func NewUserService(client *ent.Client) *UserService {
    return &UserService{client: client}
}

func (s *UserService) Create(ctx context.Context, input CreateUserInput) (*ent.User, error) {
    return s.client.User.Create().
        SetName(input.Name).
        SetEmail(input.Email).
        Save(ctx)
}
```

## Generate.go Pattern

```go
// ent/generate.go
package ent

//go:generate go run -mod=mod entgo.io/ent/cmd/ent generate --feature privacy,entql ./schema
```

## Configuration Pattern

```go
// config/database.go
package config

type Database struct {
    Host     string `env:"DB_HOST" default:"localhost"`
    Port     int    `env:"DB_PORT" default:"3306"`
    User     string `env:"DB_USER" required:"true"`
    Password string `env:"DB_PASSWORD" required:"true"`
    Name     string `env:"DB_NAME" required:"true"`
}

func (d Database) DSN() string {
    return fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=True",
        d.User, d.Password, d.Host, d.Port, d.Name)
}
```
