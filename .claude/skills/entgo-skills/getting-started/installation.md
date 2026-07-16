# Installation and Setup

## Prerequisites

- Go 1.20 or later
- Database: MySQL, PostgreSQL, or SQLite

## Install Ent Tool

```bash
# Install the ent CLI tool
go install entgo.io/ent/cmd/ent@latest

# Verify installation
ent --help
```

## Project Setup

### 1. Initialize Project

```bash
mkdir myproject
cd myproject
go mod init myproject
```

### 2. Create First Schema

```bash
# Run from project root
go run -mod=mod entgo.io/ent/cmd/ent new User
go run -mod=mod entgo.io/ent/cmd/ent new Pet
```

This creates:
```
ent/
└── schema/
    ├── user.go
    └── pet.go
```

### 3. Setup Code Generation

Create `ent/generate.go`:

```go
package ent

//go:generate go run -mod=mod entgo.io/ent/cmd/ent generate ./schema
```

### 4. Generate Code

```bash
go generate ./ent
```

Generated structure:
```
ent/
├── schema/          # Your schema definitions
├── generate.go      # Generation entry point
├── client.go        # Generated client
├── config.go        # Client configuration
├── ent.go           # Core types
├── mutation.go      # Mutation builders
├── runtime/
│   └── runtime.go   # Runtime configuration
├── user/
│   ├── user.go      # User predicates
│   └── where.go     # Where conditions
├── pet/
│   ├── pet.go
│   └── where.go
├── user.go          # User model
├── user_create.go   # Create builder
├── user_query.go    # Query builder
├── user_update.go   # Update builder
├── user_delete.go   # Delete builder
├── pet.go
├── pet_create.go
├── pet_query.go
├── pet_update.go
└── pet_delete.go
```

## Database Drivers

Install the driver for your database:

```bash
# MySQL
go get -u github.com/go-sql-driver/mysql

# PostgreSQL
go get -u github.com/lib/pq

# SQLite
go get -u github.com/mattn/go-sqlite3
```

## Next Steps

- Define fields: [Schema Fields](../references/schema-fields.md)
- Define relationships: [Schema Edges](../references/schema-edges.md)
- Learn CRUD: [CRUD Operations](../references/crud-create.md)
