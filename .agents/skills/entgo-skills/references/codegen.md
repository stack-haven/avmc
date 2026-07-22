# Code Generation

## Basic Generation

```bash
# From project root
go generate ./ent

# Or directly
go run -mod=mod entgo.io/ent/cmd/ent generate ./schema

# With specific features
go run -mod=mod entgo.io/ent/cmd/ent generate --feature privacy,entql ./schema
```

## Generate.go File

```go
// ent/generate.go
package ent

//go:generate go run -mod=mod entgo.io/ent/cmd/ent generate ./schema
```

## Feature Flags

```bash
# Enable specific features
go run -mod=mod entgo.io/ent/cmd/ent generate \
  --feature privacy \
  --feature entql \
  --feature sql/lock \
  --feature sql/upsert \
  --feature sql/modifier \
  ./schema
```

### Available Features

| Feature | Description |
|---------|-------------|
| `privacy` | Enable privacy policy support |
| `entql` | Enable EntQL query language |
| `sql/lock` | Enable SELECT FOR UPDATE |
| `sql/upsert` | Enable ON CONFLICT support |
| `sql/modifier` | Enable SQL modifiers |
| `sql/versioned-migration` | Enable versioned migrations |
| `sql/schemaconfig` | Enable schema configuration |

## Template Extensions

```go
// ent/template/stringer.tmpl
{{ define "model/stringer" }}

func ({{ $.Receiver }} *{{ $.Name }}) String() string {
    return fmt.Sprintf("{{ $.Name }}(id=%d)", {{ $.Receiver }}.ID)
}

{{ end }}
```

```go
// ent/generate.go
package ent

//go:generate go run -mod=mod entgo.io/ent/cmd/ent generate --template ./template ./schema
```

## External Templates

```go
// ent/template/mutation.tmpl
{{ define "mutation/additional" }}

func (m *{{ $.MutationName }}) SetDefaultValues() {
    if _, ok := m.Name(); !ok {
        m.SetName("default")
    }
}

{{ end }}
```

## Generation Config

```go
// ent/entc.go
//go:build ignore

package main

import (
    "log"
    "entgo.io/ent/entc"
    "entgo.io/ent/entc/gen"
)

func main() {
    opts := []entc.Option{
        entc.FeatureNames("privacy", "entql", "sql/upsert"),
        entc.TemplateDir("./template"),
        entc.Target("./ent"),
    }

    if err := entc.Generate("./schema", opts...); err != nil {
        log.Fatalf("running ent codegen: %v", err)
    }
}
```

## Custom ID Type

```go
// ent/schema/user.go
import "entgo.io/ent/schema/field"

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.UUID("id", uuid.UUID{}).
            Default(uuid.New).
            Immutable(),
    }
}
```

## Generation Hooks

```go
// ent/entc.go
func main() {
    opts := []entc.Option{
        entc.Hook(func(next gen.Mutator) gen.Mutator {
            return gen.MutateFunc(func(ctx context.Context, graph *gen.Graph) error {
                // Modify graph before generation
                for _, node := range graph.Nodes {
                    // Add custom annotations
                    node.Annotations["custom"] = "value"
                }
                return next.Mutate(ctx, graph)
            })
        }),
    }

    if err := entc.Generate("./schema", opts...); err != nil {
        log.Fatal(err)
    }
}
```

## Common Generation Issues

```bash
# Regenerate after schema changes
go generate ./ent

# Force regeneration
go clean -cache
go generate ./ent

# Check for errors
go run -mod=mod entgo.io/ent/cmd/ent generate --target ./ent ./schema
```
