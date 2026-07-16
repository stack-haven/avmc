# Privacy (Access Control)

## Enable Privacy

```bash
# Generate with privacy feature
go run -mod=mod entgo.io/ent/cmd/ent generate --feature privacy ./schema
```

## Basic Policy

```go
import "entgo.io/ent/schema/privacy"

func (User) Policy() ent.Policy {
    return privacy.Policy{
        // Allow all queries
        Query: privacy.QueryPolicy{
            privacy.AlwaysAllowRule(),
        },
        // Allow all mutations
        Mutation: privacy.MutationPolicy{
            privacy.AlwaysAllowRule(),
        },
    }
}
```

## Deny by Default

```go
func (User) Policy() ent.Policy {
    return privacy.Policy{
        Query: privacy.QueryPolicy{
            privacy.AlwaysDenyRule(),
        },
        Mutation: privacy.MutationPolicy{
            privacy.AlwaysDenyRule(),
        },
    }
}
```

## Context-Based Rules

```go
// Deny if no viewer
func DenyIfNoViewer() privacy.QueryMutationRule {
    return privacy.ContextQueryMutationRule(func(ctx context.Context) error {
        viewer := viewer.FromContext(ctx)
        if viewer == nil {
            return privacy.Denyf("missing viewer context")
        }
        return privacy.Skip
    })
}

// Allow if admin
func AllowIfAdmin() privacy.QueryMutationRule {
    return privacy.ContextMutationRule(func(ctx context.Context) error {
        viewer := viewer.FromContext(ctx)
        if viewer != nil && viewer.IsAdmin() {
            return privacy.Allow
        }
        return privacy.Skip
    })
}

func (User) Policy() ent.Policy {
    return privacy.Policy{
        Query: privacy.QueryPolicy{
            DenyIfNoViewer(),
            privacy.AlwaysAllowRule(),
        },
        Mutation: privacy.MutationPolicy{
            DenyIfNoViewer(),
            AllowIfAdmin(),
            privacy.AlwaysDenyRule(),
        },
    }
}
```

## Multi-Tenant Filtering

```go
// Filter by tenant
func FilterTenantRule() privacy.QueryRule {
    type tenantFilter interface {
        WhereEntQL(entql.BoolExpr)
    }

    return privacy.ContextQueryRule(func(ctx context.Context, q ent.Query) error {
        viewer := viewer.FromContext(ctx)
        if viewer == nil {
            return privacy.Denyf("missing viewer")
        }

        tf, ok := q.(tenantFilter)
        if !ok {
            return privacy.Denyf("unexpected query type")
        }

        tf.WhereEntQL(entql.IntEQ("tenant_id", viewer.TenantID()))
        return privacy.Skip
    })
}

func (Organization) Policy() ent.Policy {
    return privacy.Policy{
        Query: privacy.QueryPolicy{
            FilterTenantRule(),
            privacy.AlwaysAllowRule(),
        },
    }
}
```

## Resource Ownership

```go
func AllowIfOwner() privacy.QueryMutationRule {
    return privacy.ContextMutationRule(func(ctx context.Context, m ent.Mutation) error {
        viewer := viewer.FromContext(ctx)
        if viewer == nil {
            return privacy.Skip
        }

        // Get owner ID from mutation
        if ownerID, ok := m.Field("owner_id"); ok {
            if ownerID == viewer.ID() {
                return privacy.Allow
            }
        }
        return privacy.Skip
    })
}

func (Document) Policy() ent.Policy {
    return privacy.Policy{
        Query: privacy.QueryPolicy{
            DenyIfNoViewer(),
            AllowIfOwner(),
            privacy.AlwaysDenyRule(),
        },
        Mutation: privacy.MutationPolicy{
            DenyIfNoViewer(),
            AllowIfOwner(),
            privacy.AlwaysDenyRule(),
        },
    }
}
```

## Testing Privacy

```go
func TestTenantPrivacy(t *testing.T) {
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
    defer client.Close()

    ctx := context.Background()

    // Without viewer - should fail
    err := client.Tenant.Create().SetName("Test").Exec(ctx)
    assert.True(t, errors.Is(err, privacy.Deny))

    // With viewer - should succeed
    viewerCtx := viewer.NewContext(ctx, viewer.User{TenantID: 1})
    tenant, err := client.Tenant.Create().SetName("Test").Save(viewerCtx)
    assert.NoError(t, err)
    assert.NotNil(t, tenant)
}
```

## Rule Evaluation Order

```go
func (User) Policy() ent.Policy {
    return privacy.Policy{
        Mutation: privacy.MutationPolicy{
            // 1. Check if viewer exists
            DenyIfNoViewer(),
            // 2. Allow if admin
            AllowIfAdmin(),
            // 3. Allow if owner
            AllowIfOwner(),
            // 4. Deny by default
            privacy.AlwaysDenyRule(),
        },
    }
}
```
