---
name: entgo-skills
description: |
  Comprehensive knowledge base for entgo.io - Go's entity framework for building and maintaining applications with large data models.

  **Use this skill when:**
  - Defining database schemas with type-safe ORM
  - Building CRUD operations with complex relationships
  - Implementing database hooks and privacy policies
  - Managing database migrations with Atlas
  - Optimizing queries with eager loading and pagination
  - Setting up multi-tenant data access control

  **Features:**
  - Complete schema definition patterns (fields, edges, indexes, mixins)
  - Type-safe CRUD with generated code
  - Advanced query patterns (predicates, aggregation, traversal)
  - Production patterns (hooks, privacy, soft delete)
  - Migration strategies (auto and versioned)
license: MIT
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
---

# Entgo Skills for AI Agents

This skill provides comprehensive entgo entity framework knowledge, optimized for AI agents helping developers build production-ready Go applications with type-safe database operations.

## 🎯 When to Use This Skill

Invoke this skill when working with entgo:
- **Schema design**: Defining entities, fields, relationships, indexes
- **CRUD operations**: Creating type-safe database operations
- **Query optimization**: Eager loading, pagination, aggregation
- **Access control**: Privacy policies, multi-tenant filtering
- **Business logic**: Hooks, validation, default values
- **Database migrations**: Schema versioning with Atlas
- **Troubleshooting**: Fixing entgo issues, understanding errors

## 📚 Knowledge Structure

**Load specific guides as needed** rather than reading everything at once:

### Quick Start
**Link**: [Official Ent Documentation](https://entgo.io/docs/getting-started)
**Contains**: Installation, creating schemas, code generation, database connection

### Pattern Guides

#### Schema Definition
| File | When to Load |
|------|-------------|
| [references/schema-fields.md](references/schema-fields.md) | Field types, validation, constraints |
| [references/schema-edges.md](references/schema-edges.md) | Relationships (O2O, O2M, M2M), through tables |
| [references/schema-indexes.md](references/schema-indexes.md) | Single, composite, unique indexes |
| [references/schema-mixins.md](references/schema-mixins.md) | Reusable field groups (timestamp, soft delete) |
| [references/schema-annotations.md](references/schema-annotations.md) | Code generation hints, GraphQL, gRPC |

#### CRUD Operations
| File | When to Load |
|------|-------------|
| [references/crud-create.md](references/crud-create.md) | Create, CreateBulk, relations on create |
| [references/crud-query.md](references/crud-query.md) | Query, Where, predicates, sorting, pagination |
| [references/crud-update.md](references/crud-update.md) | UpdateOne, Update, upsert operations |
| [references/crud-delete.md](references/crud-delete.md) | DeleteOne, Delete, soft delete patterns |

#### Advanced Queries
| File | When to Load |
|------|-------------|
| [references/query-predicates.md](references/query-predicates.md) | Where conditions, operators, custom SQL |
| [references/query-eager-load.md](references/query-eager-load.md) | WithX methods, nested loading, N+1 prevention |
| [references/query-traversal.md](references/query-traversal.md) | Edge traversal, graph queries |
| [references/query-aggregation.md](references/query-aggregation.md) | Count, Sum, GroupBy, custom aggregates |
| [references/query-pagination.md](references/query-pagination.md) | Offset/Limit, cursor pagination |

#### Business Logic
| File | When to Load |
|------|-------------|
| [references/hooks.md](references/hooks.md) | Schema hooks, global hooks, validation |
| [references/privacy.md](references/privacy.md) | Policy rules, multi-tenant, RBAC |
| [references/validation.md](references/validation.md) | Field validation, mutation validation |
| [references/transactions.md](references/transactions.md) | Tx, WithTx, context propagation |

#### Database & Migrations
| File | When to Load |
|------|-------------|
| [references/migrations-auto.md](references/migrations-auto.md) | Schema.Create, auto migration |
| [references/migrations-versioned.md](references/migrations-versioned.md) | Atlas, versioned migrations |
| [references/database-config.md](references/database-config.md) | MySQL, PostgreSQL, SQLite, connection pool |
| [references/postgresql-specific.md](references/postgresql-specific.md) | PostgreSQL arrays, enums, JSONB, FTS |
| [references/codegen.md](references/codegen.md) | Generate command, features, templates |
| [references/custom-templates.md](references/custom-templates.md) | External templates, extensions |

#### Integration & Extensions
| File | When to Load |
|------|-------------|
| [references/graphql-entgql.md](references/graphql-entgql.md) | GraphQL integration with gqlgen |
| [references/grpc-entproto.md](references/grpc-entproto.md) | gRPC/Protobuf integration |

#### Advanced Features
| File | When to Load |
|------|-------------|
| [references/json-operations.md](references/json-operations.md) | JSON field operations, predicates |
| [references/locking.md](references/locking.md) | Pessimistic/Optimistic locking |
| [references/interceptors.md](references/interceptors.md) | Query interceptors |
| [references/views.md](references/views.md) | SQL views, materialized views |

### Best Practices
| File | When to Load |
|------|-------------|
| [best-practices/project-structure.md](best-practices/project-structure.md) | Directory layout, naming conventions |
| [best-practices/error-handling.md](best-practices/error-handling.md) | Error types, wrapping, checking |
| [best-practices/soft-delete.md](best-practices/soft-delete.md) | Soft delete implementation |
| [best-practices/testing.md](best-practices/testing.md) | Testing with ent, fixtures |

### Troubleshooting
| File | When to Load |
|------|-------------|
| [troubleshooting/common-errors.md](troubleshooting/common-errors.md) | Not found, constraint errors |
| [troubleshooting/migration-issues.md](troubleshooting/migration-issues.md) | Migration failures, schema drift |
| [troubleshooting/performance.md](troubleshooting/performance.md) | N+1, query optimization |

## 🚀 Quick Examples

### Basic Schema
```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name").NotEmpty(),
        field.String("email").Unique(),
        field.Int("age").Positive(),
    }
}

func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("pets", Pet.Type),
    }
}
```

### CRUD Operations
```go
// Create
user, err := client.User.Create().
    SetName("Alice").
    SetEmail("alice@example.com").
    Save(ctx)

// Query with eager loading
users, err := client.User.Query().
    Where(user.AgeGT(18)).
    WithPets().
    All(ctx)

// Update
_, err := client.User.UpdateOneID(id).
    SetName("Bob").
    Save(ctx)

// Delete
err := client.User.DeleteOneID(id).Exec(ctx)
```

### Transaction
```go
err := WithTx(ctx, client, func(tx *ent.Tx) error {
    u, err := tx.User.Create().SetName("Alice").Save(ctx)
    if err != nil {
        return err
    }
    _, err = tx.Pet.Create().SetName("Fluffy").SetOwner(u).Save(ctx)
    return err
})
```

## 🔗 External Resources

- **Official Docs**: https://entgo.io/docs
- **GitHub**: https://github.com/ent/ent
- **Atlas Migration**: https://atlasgo.io
- **Examples**: https://github.com/ent/ent/tree/master/examples
