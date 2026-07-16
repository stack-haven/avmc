# Interceptors

## Enable Interceptors

```go
// ent/generate.go
package ent

//go:generate go run -mod=mod entgo.io/ent/cmd/ent generate --feature intercept ./schema
```

Or via Go config:

```go
opts := []entc.Option{
    entc.FeatureNames("intercept"),
}
```

## Basic Interceptor

```go
// Create interceptor
interceptor := ent.InterceptFunc(func(next ent.Querier) ent.Querier {
    return ent.QuerierFunc(func(ctx context.Context, query ent.Query) (ent.Value, error) {
        // Before query
        start := time.Now()

        // Execute query
        value, err := next.Query(ctx, query)

        // After query
        log.Printf("Query took %v", time.Since(start))

        return value, err
    })
})

// Apply to client
client.Intercept(interceptor)
```

## Query Logging Interceptor

```go
func QueryLoggingInterceptor() ent.InterceptFunc {
    return func(next ent.Querier) ent.Querier {
        return ent.QuerierFunc(func(ctx context.Context, query ent.Query) (ent.Value, error) {
            start := time.Now()
            value, err := next.Query(ctx, query)
            duration := time.Since(start)

            // Log slow queries
            if duration > 100*time.Millisecond {
                log.Printf("SLOW QUERY: %T took %v", query, duration)
            }

            return value, err
        })
    }
}

// Usage
client.Intercept(QueryLoggingInterceptor())
```

## Default Limit Interceptor

```go
func DefaultLimitInterceptor(limit int) ent.InterceptFunc {
    return func(next ent.Querier) ent.Querier {
        return ent.QuerierFunc(func(ctx context.Context, query ent.Query) (ent.Value, error) {
            // Type assert to specific query type
            if q, ok := query.(*ent.UserQuery); ok {
                // Check if limit is already set
                if _, ok := ctx.Value("user_query_limit").(bool); !ok {
                    q.Limit(limit)
                }
            }
            return next.Query(ctx, query)
        })
    }
}

// Usage
client.Intercept(DefaultLimitInterceptor(100))
```

## Multi-Tenant Interceptor

```go
func TenantInterceptor() ent.InterceptFunc {
    return func(next ent.Querier) ent.Querier {
        return ent.QuerierFunc(func(ctx context.Context, query ent.Query) (ent.Value, error) {
            // Get tenant from context
            tenantID, ok := ctx.Value("tenant_id").(int)
            if !ok {
                return nil, fmt.Errorf("tenant_id not in context")
            }

            // Apply filter based on query type
            switch q := query.(type) {
            case *ent.UserQuery:
                q.Where(user.TenantIDEQ(tenantID))
            case *ent.OrderQuery:
                q.Where(order.TenantIDEQ(tenantID))
            }

            return next.Query(ctx, query)
        })
    }
}

// Usage with specific entities
client.User.Intercept(
    intercept.TraverseUser(func(ctx context.Context, q *ent.UserQuery) error {
        tenantID := ctx.Value("tenant_id").(int)
        q.Where(user.TenantIDEQ(tenantID))
        return nil
    }),
)
```

## Soft Delete Interceptor

```go
func SoftDeleteInterceptor() ent.InterceptFunc {
    return func(next ent.Querier) ent.Querier {
        return ent.QuerierFunc(func(ctx context.Context, query ent.Query) (ent.Value, error) {
            // Skip if explicitly requesting deleted
            if ctx.Value("include_deleted") != nil {
                return next.Query(ctx, query)
            }

            // Add deleted_at is null filter
            switch q := query.(type) {
            case *ent.UserQuery:
                q.Where(user.DeletedAtIsNil())
            }

            return next.Query(ctx, query)
        })
    }
}
```

## Schema-Level Interceptors

```go
func (User) Interceptors() []ent.Interceptor {
    return []ent.Interceptor{
        intercept.TraverseUser(func(ctx context.Context, q *ent.UserQuery) error {
            // Always filter active users by default
            q.Where(user.Active(true))
            return nil
        }),
    }
}
```

## Conditional Interceptors

```go
func ConditionalInterceptor() ent.InterceptFunc {
    return func(next ent.Querier) ent.Querier {
        return ent.QuerierFunc(func(ctx context.Context, query ent.Query) (ent.Value, error) {
            // Only apply in certain conditions
            if shouldSkipInterceptor(ctx) {
                return next.Query(ctx, query)
            }

            // Apply interceptor logic
            // ...

            return next.Query(ctx, query)
        })
    }
}
```
