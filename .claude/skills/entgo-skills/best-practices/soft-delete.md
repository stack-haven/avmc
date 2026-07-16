# Soft Delete

## Mixin Approach

```go
// ent/schema/mixin/softdelete.go
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

## Hook-Based Soft Delete

```go
// ent/schema/mixin/softdelete.go
func (SoftDeleteMixin) Hooks() []ent.Hook {
    return []ent.Hook{
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return ent.MutateFunc(func(ctx context.Context, m ent.Mutation) (ent.Value, error) {
                    // Convert Delete to Update
                    m.SetField("deleted_at", time.Now())
                    return next.Mutate(ctx, m)
                })
            },
            ent.OpDelete|ent.OpDeleteOne,
        ),
    }
}
```

## Privacy Filter

```go
// ent/schema/mixin/softdelete.go
import "entgo.io/ent/entql"

func (SoftDeleteMixin) Policy() ent.Policy {
    return privacy.Policy{
        Query: privacy.QueryPolicy{
            privacy.ContextQueryRule(func(ctx context.Context, q ent.Query) error {
                // Filter out deleted records
                if tq, ok := q.(interface{ WhereEntQL(entql.BoolExpr) }); ok {
                    tq.WhereEntQL(entql.FieldIsNull("deleted_at"))
                }
                return privacy.Skip
            }),
        },
    }
}
```

## Query Soft Deleted Records

```go
// To include deleted records, bypass the privacy policy
ctx := privacy.DecisionContext(parentCtx, privacy.Allow)

allUsers, err := client.User.Query().All(ctx)

// Only deleted records
deletedUsers, err := client.User.Query().
    Where(user.DeletedAtNotNil()).
    All(ctx)
```

## Restore Soft Deleted

```go
func RestoreUser(ctx context.Context, client *ent.Client, id int) (*ent.User, error) {
    return client.User.UpdateOneID(id).
        ClearDeletedAt().
        Save(ctx)
}
```

## Hard Delete

```go
func HardDeleteUser(ctx context.Context, client *ent.Client, id int) error {
    // Bypass soft delete hook
    ctx = privacy.DecisionContext(ctx, privacy.Allow)

    return client.User.DeleteOneID(id).Exec(ctx)
}
```

## Complete Example

```go
package schema

import (
    "time"
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "entgo.io/ent/schema/mixin"
    "entgo.io/ent/entql"
    "entgo.io/ent/schema/privacy"
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

func (SoftDeleteMixin) Policy() ent.Policy {
    return privacy.Policy{
        Query: privacy.QueryPolicy{
            privacy.ContextQueryRule(func(ctx context.Context, q ent.Query) error {
                if tq, ok := q.(interface{ WhereEntQL(entql.BoolExpr) }); ok {
                    tq.WhereEntQL(entql.FieldIsNull("deleted_at"))
                }
                return privacy.Skip
            }),
        },
    }
}
```
