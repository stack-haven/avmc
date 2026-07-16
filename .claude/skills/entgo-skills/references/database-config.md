# Database Configuration

## MySQL

```go
import (
    "myproject/ent"
    "entgo.io/ent/dialect/sql"
    _ "github.com/go-sql-driver/mysql"
)

// Basic connection
client, err := ent.Open("mysql", "user:password@tcp(localhost:3306)/dbname?parseTime=True")

// With options
client, err := ent.Open("mysql", "user:password@tcp(localhost:3306)/dbname?parseTime=True&loc=Local&charset=utf8mb4")

// Advanced with connection pool
drv, err := sql.Open("mysql", dsn)
db := drv.DB()
db.SetMaxIdleConns(10)
db.SetMaxOpenConns(100)
db.SetConnMaxLifetime(time.Hour)
client = ent.NewClient(ent.Driver(drv))
```

## PostgreSQL

```go
import _ "github.com/lib/pq"

// Basic connection
client, err := ent.Open("postgres", "host=localhost port=5432 user=postgres dbname=mydb password=secret sslmode=disable")

// With options
client, err := ent.Open("postgres", "host=localhost port=5432 user=postgres dbname=mydb password=secret sslmode=require search_path=myschema")

// URL format
client, err := ent.Open("postgres", "postgres://user:password@localhost:5432/mydb?sslmode=disable")
```

## SQLite

```go
import _ "github.com/mattn/go-sqlite3"

// File-based
client, err := ent.Open("sqlite3", "file:database.db?_fk=1")

// In-memory
client, err := ent.Open("sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")

// With WAL mode
client, err := ent.Open("sqlite3", "file:database.db?_fk=1&_journal=WAL&_timeout=5000")
```

## Connection Pool Settings

```go
func createClient(dialect, dsn string) (*ent.Client, error) {
    drv, err := sql.Open(dialect, dsn)
    if err != nil {
        return nil, err
    }

    db := drv.DB()

    // Pool settings
    db.SetMaxOpenConns(25)           // Maximum open connections
    db.SetMaxIdleConns(25)           // Maximum idle connections
    db.SetConnMaxLifetime(5 * time.Minute)  // Connection lifetime
    db.SetConnMaxIdleTime(1 * time.Minute)  // Idle connection timeout

    return ent.NewClient(ent.Driver(drv)), nil
}
```

## Client Options

```go
client := ent.NewClient(
    ent.Driver(drv),

    // Enable logging
    ent.Log(log.Println),

    // Enable debug logging
    ent.Debug(),

    // Custom logger
    ent.Log(func(args ...interface{}) {
        log.Println(args...)
    }),
)
```

## Multiple Databases

```go
type Database struct {
    Read  *ent.Client
    Write *ent.Client
}

func NewDatabase(readDSN, writeDSN string) (*Database, error) {
    readClient, err := ent.Open("mysql", readDSN)
    if err != nil {
        return nil, err
    }

    writeClient, err := ent.Open("mysql", writeDSN)
    if err != nil {
        return nil, err
    }

    return &Database{
        Read:  readClient,
        Write: writeClient,
    }, nil
}
```

## Environment-Based Config

```go
func NewClientFromEnv() (*ent.Client, error) {
    host := os.Getenv("DB_HOST")
    if host == "" {
        host = "localhost"
    }

    port := os.Getenv("DB_PORT")
    if port == "" {
        port = "3306"
    }

    user := os.Getenv("DB_USER")
    pass := os.Getenv("DB_PASSWORD")
    name := os.Getenv("DB_NAME")

    dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=True",
        user, pass, host, port, name)

    return ent.Open("mysql", dsn)
}
```
