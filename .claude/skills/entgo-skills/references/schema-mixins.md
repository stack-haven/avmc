# Schema Mixins

## TimeMixin (Timestamps)

```go
package mixin

import (
    "time"
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "entgo.io/ent/schema/mixin"
)

// TimeMixin adds created_at and updated_at fields.
type TimeMixin struct {
    mixin.Schema
}

func (TimeMixin) Fields() []ent.Field {
    return []ent.Field{
        field.Time("created_at").
            Default(time.Now).
            Immutable(),
        field.Time("updated_at").
            Default(time.Now).
            UpdateDefault(time.Now),
    }
}
```

## SoftDeleteMixin

```go
package mixin

import (
    "time"
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "entgo.io/ent/schema/mixin"
)

type SoftDeleteMixin struct {
    mixin.Schema
}

func (SoftDeleteMixin) Fields() []ent.Field {
    return []ent.Field{
        field.Time("deleted_at").
            Optional().
            Nillable(),
    }
}
```

## TenantMixin (Multi-tenancy)

```go
package mixin

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "entgo.io/ent/schema/mixin"
    "entgo.io/ent/schema/privacy"
)

type TenantMixin struct {
    mixin.Schema
}

func (TenantMixin) Fields() []ent.Field {
    return []ent.Field{
        field.Int("tenant_id").
            Immutable(),
    }
}

func (TenantMixin) Policy() ent.Policy {
    return privacy.Policy{
        Query: privacy.QueryPolicy{
            // Filter by tenant
            privacy.AlwaysAllowRule(),
        },
        Mutation: privacy.MutationPolicy{
            privacy.AlwaysAllowRule(),
        },
    }
}
```

## Using Mixins

```go
package schema

import (
    "myproject/ent/schema/mixin"
    "entgo.io/ent"
)

type User struct {
    ent.Schema
}

func (User) Mixin() []ent.Mixin {
    return []ent.Mixin{
        mixin.TimeMixin{},
        mixin.SoftDeleteMixin{},
        mixin.TenantMixin{},
    }
}

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name"),
        field.String("email").Unique(),
    }
}
```

## Mixin with Hooks

```go
type AuditMixin struct {
    mixin.Schema
}

func (AuditMixin) Fields() []ent.Field {
    return []ent.Field{
        field.String("created_by"),
        field.String("updated_by").Optional(),
    }
}

func (AuditMixin) Hooks() []ent.Hook {
    return []ent.Hook{
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return ent.MutateFunc(func(ctx context.Context, m ent.Mutation) (ent.Value, error) {
                    // Get user from context
                    user := viewer.FromContext(ctx)
                    if user != nil {
                        if m.Op().Is(ent.OpCreate) {
                            m.SetField("created_by", user.ID())
                        }
                        if m.Op().Is(ent.OpUpdate) {
                            m.SetField("updated_by", user.ID())
                        }
                    }
                    return next.Mutate(ctx, m)
                })
            },
            ent.OpCreate|ent.OpUpdate,
        ),
    }
}
```
