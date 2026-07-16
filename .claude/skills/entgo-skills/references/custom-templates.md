# Custom Templates

## Template Basics

```go
// ent/template/debug.tmpl
{{ define "debug" }}

{{ $pkg := base $.Config.Package }}
{{ template "header" $ }}

// DebugInfo returns debug information about the entity
func ({{ $.Receiver }} *{{ $.Name }}) DebugInfo() string {
    return fmt.Sprintf("{{ $.Name }}(id=%d)", {{ $.Receiver }}.ID)
}

{{ end }}
```

## Enable Custom Templates

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
        entc.TemplateFiles(
            "template/debug.tmpl",
            "template/stringer.tmpl",
        ),
    }

    if err := entc.Generate("./schema", &gen.Config{}, opts...); err != nil {
        log.Fatal(err)
    }
}
```

## Template with Functions

```go
// ent/template/stringer.tmpl
{{ define "stringer" }}

{{ $pkg := base $.Config.Package }}
{{ template "header" $ }}

// String implements fmt.Stringer
func ({{ $.Receiver }} *{{ $.Name }}) String() string {
    return fmt.Sprintf("{{ $.Name }}(id=%d, %s)",
        {{ $.Receiver }}.ID,
        {{ $.Receiver }}.{{ pascal $.Config.IDType.Name }},
    )
}

{{ end }}
```

## Template Structure

```go
// ent/template/custom.tmpl
{{ define "custom" }}

{{/* Header */}}
{{ $pkg := base $.Config.Package }}
{{ template "header" $ }}

{{/* Imports */}}
import "fmt"

{{/* Loop over nodes */}}
{{ range $n := $.Nodes }}

{{ $receiver := $n.Receiver }}
{{ $name := $n.Name }}

// Greet returns a greeting for {{ $name }}
func ({{ $receiver }} *{{ $name }}) Greet() string {
    return fmt.Sprintf("Hello, {{ $name }} #%d", {{ $receiver }}.ID)
}

// Validate performs custom validation
func ({{ $receiver }} *{{ $name }}) Validate() error {
    {{ range $f := $n.Fields }}
    {{ if $f.Optional }}
    // Optional field: {{ $f.Name }}
    {{ else }}
    // Required field: {{ $f.Name }}
    if {{ $receiver }}.{{ $f.StructField }} == {{ zero $f.Type }} {
        return fmt.Errorf("{{ $f.Name }} is required")
    }
    {{ end }}
    {{ end }}
    return nil
}

{{ end }}
{{ end }}
```

## Extension with Templates

```go
// ent/extension.go
package ent

import (
    "entgo.io/ent/entc"
    "entgo.io/ent/entc/gen"
)

// CustomExtension implements entc.Extension
type CustomExtension struct {
    entc.DefaultExtension
}

func (e *CustomExtension) Templates() []*gen.Template {
    return []*gen.Template{
        gen.MustParse(gen.NewTemplate("greet").
            Parse(`
{{ define "greet" }}
{{ $pkg := base $.Config.Package }}
{{ template "header" $ }}

{{ range $n := $.Nodes }}
{{ $receiver := $n.Receiver }}
func ({{ $receiver }} *{{ $n.Name }}) Greet() string {
    return "Hello, {{ $n.Name }}"
}
{{ end }}
{{ end }}
`)),
    }
}

func (e *CustomExtension) Hooks() []gen.Hook {
    return []gen.Hook{
        func(next gen.Generator) gen.Generator {
            return gen.GenerateFunc(func(g *gen.Graph) error {
                // Modify graph before generation
                for _, n := range g.Nodes {
                    n.Annotations["custom"] = "value"
                }
                return next.Generate(g)
            })
        },
    }
}
```

## Using Extension

```go
// ent/entc.go
func main() {
    ex := &CustomExtension{}

    opts := []entc.Option{
        entc.Extensions(ex),
    }

    if err := entc.Generate("./schema", &gen.Config{}, opts...); err != nil {
        log.Fatal(err)
    }
}
```

## Custom MarshalJSON

```go
// ent/template/json.tmpl
{{ define "model/additional/json" }}

{{ if $.Edges }}
// MarshalJSON implements json.Marshaler
func ({{ $.Receiver }} *{{ $.Name }}) MarshalJSON() ([]byte, error) {
    type Alias {{ $.Name }}
    return json.Marshal(&struct {
        *Alias
        {{ $.Name }}Edges
    }{
        Alias:           (*Alias)({{ $.Receiver }}),
        {{ $.Name }}Edges: {{ $.Receiver }}.Edges,
    })
}
{{ end }}

{{ end }}
```

```go
// ent/extension.go
func (e *Extension) Templates() []*gen.Template {
    return []*gen.Template{
        gen.MustParse(gen.NewTemplate("json").
            ParseFiles("template/json.tmpl")),
    }
}

func (e *Extension) Hooks() []gen.Hook {
    return []gen.Hook{
        func(next gen.Generator) gen.Generator {
            return gen.GenerateFunc(func(g *gen.Graph) error {
                // Set edge annotation to omit from JSON
                tag := edge.Annotation{StructTag: `json:"-"`}
                for _, n := range g.Nodes {
                    n.Annotations.Set(tag.Name(), tag)
                }
                return next.Generate(g)
            })
        },
    }
}
```

## Template Variables

| Variable | Description |
|----------|-------------|
| `$.Config` | Code generation config |
| `$.Nodes` | All schema nodes |
| `$.Edges` | All edges |
| `$n.Name` | Node name |
| `$n.Receiver` | Receiver variable name |
| `$n.Fields` | Node fields |
| `$f.Name` | Field name |
| `$f.Type` | Field type |
| `$f.Optional` | Is field optional |
