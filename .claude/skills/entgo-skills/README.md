# Entgo Skills

Comprehensive knowledge base for [entgo.io](https://entgo.io) - Go's powerful entity framework for building applications with large data models.

[![GitHub](https://img.shields.io/badge/GitHub-lwx--cloud%2Fentgo--skills-blue)](https://github.com/lwx-cloud/entgo-skills)
[![Entgo](https://img.shields.io/badge/Entgo-v0.12+-green)](https://entgo.io)
[![Go](https://img.shields.io/badge/Go-1.20+-00ADD8)](https://golang.org)

[中文](README_CN.md) | **English**

## Overview

Ent is a powerful entity framework for Go that simplifies building and maintaining applications with large data models. It enables modeling database schemas as graph structures using programmatic Go code and static typing via code generation.

## Key Features

- **Type-Safe**: Generated code provides compile-time type safety
- **Graph-Based**: Model data as interconnected entities
- **Code Generation**: Generate clients, builders, and query types from schemas
- **Multiple Storage**: Support for MySQL, PostgreSQL, SQLite, Gremlin
- **Extensible**: Hooks, Privacy, Validation, and custom extensions

## Installation

### Install Ent CLI Tool

```bash
go install entgo.io/ent/cmd/ent@latest
```

### Install as Claude Code Skill

#### Method 1: Using npx (Recommended)

```bash
# Project-level (recommended)
npx skills add lwx-cloud/entgo-skills

# Personal-level (all projects)
npx skills add lwx-cloud/entgo-skills -g
```

#### Method 2: Clone to Local Skills Directory

```bash
# Clone to Claude Code skills directory
git clone https://github.com/lwx-cloud/entgo-skills.git ~/.claude/skills/entgo-skills
```

#### Method 3: Use with Claude Code

Add to your Claude Code configuration:

```json
{
  "skills": [
    {
      "name": "entgo-skills",
      "path": "~/.claude/skills/entgo-skills"
    }
  ]
}
```

Or use directly in Claude Code:

```
skill: entgo-skills
```

## Quick Start

```bash
# Create a new Ent project
mkdir myproject && cd myproject
go mod init myproject

# Create schema
go run -mod=mod entgo.io/ent/cmd/ent new User

# Generate code
go generate ./ent
```

```go
// schema/user.go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name"),
        field.Int("age"),
    }
}

// Usage
user, err := client.User.Create().
    SetName("Alice").
    SetAge(30).
    Save(ctx)
```

## Directory Structure

```
entgo-skills/
├── SKILL.md                    # Main skill definition
├── README.md                   # This file
├── README_CN.md                # Chinese documentation
├── getting-started/            # Quick start guides
│   ├── installation.md
│   ├── database-connection.md
│   └── first-schema.md
├── references/                 # Detailed pattern references
│   ├── schema-fields.md
│   ├── schema-edges.md
│   ├── schema-indexes.md
│   ├── schema-mixins.md
│   ├── crud-create.md
│   ├── crud-query.md
│   ├── crud-update.md
│   ├── crud-delete.md
│   ├── hooks.md
│   ├── privacy.md
│   ├── transactions.md
│   └── ... (33 files total)
├── best-practices/             # Production best practices
│   ├── project-structure.md
│   ├── error-handling.md
│   ├── soft-delete.md
│   └── testing.md
└── troubleshooting/            # Common issues and solutions
    ├── common-errors.md
    ├── migration-issues.md
    └── performance.md
```

## Documentation Map

### Getting Started
- [Installation](getting-started/installation.md) - Install ent tool and setup project
- [Database Connection](getting-started/database-connection.md) - Connect to MySQL, PostgreSQL, SQLite
- [First Schema](getting-started/first-schema.md) - Create your first Ent schema

### Schema Definition
- [Schema Fields](references/schema-fields.md) - Field types, validation, constraints
- [Schema Edges](references/schema-edges.md) - Relationships (O2O, O2M, M2M)
- [Schema Indexes](references/schema-indexes.md) - Single, composite, unique indexes
- [Schema Mixins](references/schema-mixins.md) - Reusable field groups
- [Schema Annotations](references/schema-annotations.md) - Code generation hints

### CRUD Operations
- [Create](references/crud-create.md) - Create, CreateBulk, relations on create
- [Query](references/crud-query.md) - Query, Where, predicates, sorting
- [Update](references/crud-update.md) - UpdateOne, Update, upsert operations
- [Delete](references/crud-delete.md) - DeleteOne, Delete, soft delete patterns

### Advanced Queries
- [Predicates](references/query-predicates.md) - Where conditions, operators, custom SQL
- [Eager Loading](references/query-eager-load.md) - WithX methods, N+1 prevention
- [Graph Traversal](references/query-traversal.md) - Edge traversal, graph queries
- [Aggregation](references/query-aggregation.md) - Count, Sum, GroupBy
- [Pagination](references/query-pagination.md) - Offset/Limit, cursor pagination

### Business Logic
- [Hooks](references/hooks.md) - Schema hooks, global hooks, validation
- [Privacy](references/privacy.md) - Policy rules, multi-tenant, RBAC
- [Validation](references/validation.md) - Field validation, mutation validation
- [Transactions](references/transactions.md) - Tx, WithTx, context propagation

### Database & Migrations
- [Auto Migrations](references/migrations-auto.md) - Schema.Create, auto migration
- [Versioned Migrations](references/migrations-versioned.md) - Atlas, versioned migrations
- [Database Config](references/database-config.md) - MySQL, PostgreSQL, SQLite
- [PostgreSQL Specific](references/postgresql-specific.md) - Arrays, enums, JSONB, FTS

### Integration & Extensions
- [GraphQL (entgql)](references/graphql-entgql.md) - GraphQL integration with gqlgen
- [gRPC (entproto)](references/grpc-entproto.md) - gRPC/Protobuf integration
- [Custom Templates](references/custom-templates.md) - External templates, extensions

### Advanced Features
- [JSON Operations](references/json-operations.md) - JSON field operations, predicates
- [Locking](references/locking.md) - Pessimistic/Optimistic locking
- [Interceptors](references/interceptors.md) - Query interceptors
- [Views](references/views.md) - SQL views, materialized views

### Best Practices
- [Project Structure](best-practices/project-structure.md) - Directory layout, naming conventions
- [Error Handling](best-practices/error-handling.md) - Error types, wrapping, checking
- [Soft Delete](best-practices/soft-delete.md) - Soft delete implementation
- [Testing](best-practices/testing.md) - Testing with ent, fixtures

### Troubleshooting
- [Common Errors](troubleshooting/common-errors.md) - Not found, constraint errors
- [Migration Issues](troubleshooting/migration-issues.md) - Migration failures, schema drift
- [Performance](troubleshooting/performance.md) - N+1, query optimization

## External Resources

- [Official Documentation](https://entgo.io/docs)
- [GitHub Repository](https://github.com/ent/ent)
- [Atlas Migration Tool](https://atlasgo.io)
- [Examples](https://github.com/ent/ent/tree/master/examples)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**[中文文档](README_CN.md)**
