# Database Connection

## MySQL

```go
package main

import (
    "context"
    "log"
    "time"

    "myproject/ent"
    "entgo.io/ent/dialect/sql"
    _ "github.com/go-sql-driver/mysql"
)

func main() {
    // Simple connection
    client, err := ent.Open("mysql", "user:pass@tcp(localhost:3306)/dbname?parseTime=True")
    if err != nil {
        log.Fatalf("failed opening connection: %v", err)
    }
    defer client.Close()

    // With connection pool configuration
    drv, err := sql.Open("mysql", "user:pass@tcp(localhost:3306)/dbname?parseTime=True")
    if err != nil {
        log.Fatalf("failed opening connection: %v", err)
    }

    db := drv.DB()
    db.SetMaxIdleConns(10)
    db.SetMaxOpenConns(100)
    db.SetConnMaxLifetime(time.Hour)

    client = ent.NewClient(ent.Driver(drv))

    // Run auto migration
    if err := client.Schema.Create(context.Background()); err != nil {
        log.Fatalf("failed creating schema: %v", err)
    }
}
```

## PostgreSQL

```go
client, err := ent.Open("postgres", "host=localhost port=5432 user=postgres dbname=mydb password=mypass sslmode=disable")
if err != nil {
    log.Fatalf("failed opening connection: %v", err)
}
defer client.Close()
```

## SQLite

```go
// File-based
client, err := ent.Open("sqlite3", "file:ent.db?_fk=1")
if err != nil {
    log.Fatalf("failed opening connection: %v", err)
}

// In-memory
client, err := ent.Open("sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
if err != nil {
    log.Fatalf("failed opening connection: %v", err)
}
```

## Using Existing sql.DB

```go
package main

import (
    "database/sql"
    "myproject/ent"
    entsql "entgo.io/ent/dialect/sql"
)

func main() {
    db, err := sql.Open("mysql", "user:pass@tcp(localhost:3306)/dbname")
    if err != nil {
        log.Fatal(err)
    }

    // Create ent driver from existing sql.DB
    drv := entsql.OpenDB("mysql", db)
    client := ent.NewClient(ent.Driver(drv))
    defer client.Close()
}
```

## Connection Options

```go
import "entgo.io/ent/dialect/sql"

func createClient() (*ent.Client, error) {
    drv, err := sql.Open("mysql", dsn)
    if err != nil {
        return nil, err
    }

    db := drv.DB()

    // Connection pool settings
    db.SetMaxIdleConns(10)           // Maximum idle connections
    db.SetMaxOpenConns(100)          // Maximum open connections
    db.SetConnMaxLifetime(time.Hour) // Maximum lifetime of a connection
    db.SetConnMaxIdleTime(30 * time.Minute)

    // Create client with options
    client := ent.NewClient(
        ent.Driver(drv),
        ent.Log(log.Println),              // Log all SQL statements
        ent.Debug(),                        // Debug mode
        ent.Dialect("mysql"),               // Explicit dialect
    )

    return client, nil
}
```

## Environment-Based Configuration

```go
package main

import (
    "fmt"
    "os"
    "myproject/ent"
)

func NewClient() (*ent.Client, error) {
    host := getEnv("DB_HOST", "localhost")
    port := getEnv("DB_PORT", "3306")
    user := getEnv("DB_USER", "root")
    pass := getEnv("DB_PASS", "")
    name := getEnv("DB_NAME", "myapp")

    dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=True",
        user, pass, host, port, name)

    return ent.Open("mysql", dsn)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```
