# Testing

## Test Setup

```go
import (
    "testing"
    "myapp/ent"
    "myapp/ent/enttest"
    _ "github.com/mattn/go-sqlite3"
)

func TestUser(t *testing.T) {
    // Create in-memory test client
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
    defer client.Close()

    ctx := context.Background()

    // Run migration
    client.Schema.Create(ctx)

    // Your test code...
}
```

## Test Fixtures

```go
// fixtures/user.go
package fixtures

import (
    "context"
    "testing"
    "myapp/ent"
)

func NewUser(ctx context.Context, t *testing.T, client *ent.Client) *ent.User {
    t.Helper()

    user, err := client.User.Create().
        SetName("Test User").
        SetEmail("test@example.com").
        Save(ctx)
    if err != nil {
        t.Fatalf("creating test user: %v", err)
    }

    return user
}

func NewUserWithPets(ctx context.Context, t *testing.T, client *ent.Client, petCount int) *ent.User {
    t.Helper()

    user := NewUser(ctx, t, client)

    for i := 0; i < petCount; i++ {
        _, err := client.Pet.Create().
            SetName(fmt.Sprintf("Pet %d", i)).
            SetOwner(user).
            Save(ctx)
        if err != nil {
            t.Fatalf("creating test pet: %v", err)
        }
    }

    return user
}
```

## Test Patterns

### CRUD Test

```go
func TestUserCRUD(t *testing.T) {
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&_fk=1")
    defer client.Close()

    ctx := context.Background()

    // Create
    user, err := client.User.Create().
        SetName("Alice").
        SetEmail("alice@example.com").
        Save(ctx)
    require.NoError(t, err)
    require.NotNil(t, user)

    // Read
    found, err := client.User.Get(ctx, user.ID)
    require.NoError(t, err)
    assert.Equal(t, "Alice", found.Name)

    // Update
    updated, err := user.Update().SetName("Bob").Save(ctx)
    require.NoError(t, err)
    assert.Equal(t, "Bob", updated.Name)

    // Delete
    err = client.User.DeleteOne(user).Exec(ctx)
    require.NoError(t, err)

    // Verify delete
    _, err = client.User.Get(ctx, user.ID)
    assert.True(t, ent.IsNotFound(err))
}
```

### Transaction Test

```go
func TestTransfer(t *testing.T) {
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&_fk=1")
    defer client.Close()

    ctx := context.Background()

    // Setup
    from, _ := client.User.Create().SetName("From").SetCredits(100).Save(ctx)
    to, _ := client.User.Create().SetName("To").SetCredits(0).Save(ctx)

    // Test transaction
    err := Transfer(ctx, client, from.ID, to.ID, 50)
    require.NoError(t, err)

    // Verify
    from, _ = client.User.Get(ctx, from.ID)
    to, _ = client.User.Get(ctx, to.ID)
    assert.Equal(t, 50, from.Credits)
    assert.Equal(t, 50, to.Credits)
}
```

### Hook Test

```go
func TestValidationHook(t *testing.T) {
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&_fk=1")
    defer client.Close()

    ctx := context.Background()

    // Try invalid age
    _, err := client.User.Create().
        SetName("Test").
        SetAge(-1).
        Save(ctx)

    assert.Error(t, err)
    assert.Contains(t, err.Error(), "cannot be negative")
}
```

### Privacy Test

```go
func TestPrivacyPolicy(t *testing.T) {
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&_fk=1")
    defer client.Close()

    ctx := context.Background()

    // Without viewer - should fail
    err := client.Tenant.Create().SetName("Test").Exec(ctx)
    assert.True(t, errors.Is(err, privacy.Deny))

    // With admin viewer - should succeed
    adminCtx := viewer.NewContext(ctx, viewer.User{Role: viewer.Admin})
    tenant, err := client.Tenant.Create().SetName("Test").Save(adminCtx)
    assert.NoError(t, err)
    assert.NotNil(t, tenant)
}
```

## Test Database Cleanup

```go
func TestMain(m *testing.M) {
    // Global test setup
    code := m.Run()
    // Global test teardown
    os.Exit(code)
}

func cleanup(t *testing.T, client *ent.Client) {
    t.Helper()
    ctx := context.Background()

    // Clean tables
    client.Pet.Delete().ExecX(ctx)
    client.User.Delete().ExecX(ctx)
}
```

## Parallel Tests

```go
func TestParallel(t *testing.T) {
    t.Parallel()

    // Each test gets its own database
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&_fk=1")
    defer client.Close()

    // Run tests...
}
```
