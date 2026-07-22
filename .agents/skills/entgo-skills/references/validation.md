# Validation

## Field-Level Validation

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("email").
            Validate(func(s string) error {
                if !strings.Contains(s, "@") {
                    return fmt.Errorf("invalid email format")
                }
                return nil
            }),

        field.Int("age").
            Validate(func(i int) error {
                if i < 0 || i > 150 {
                    return fmt.Errorf("age must be between 0 and 150")
                }
                return nil
            }),

        field.String("name").
            NotEmpty().
            MaxLen(100).
            Match(regexp.MustCompile(`^[a-zA-Z\s]+$`)),
    }
}
```

## Hook-Based Validation

```go
func (User) Hooks() []ent.Hook {
    return []ent.Hook{
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return hook.UserFunc(func(ctx context.Context, m *ent.UserMutation) (ent.Value, error) {
                    // Cross-field validation
                    name, nameOK := m.Name()
                    email, emailOK := m.Email()

                    if nameOK && emailOK {
                        if strings.Contains(email, name) {
                            return nil, fmt.Errorf("email cannot contain name")
                        }
                    }

                    // Business rule validation
                    age, ageOK := m.Age()
                    if ageOK && age < 18 {
                        return nil, fmt.Errorf("must be 18 or older")
                    }

                    return next.Mutate(ctx, m)
                })
            },
            ent.OpCreate|ent.OpUpdate,
        ),
    }
}
```

## Schema-Level Validation

```go
import "github.com/go-playground/validator/v10"

type UserValidator struct {
    validate *validator.Validate
}

func (v *UserValidator) ValidateUser(user *ent.User) error {
    type UserInput struct {
        Name  string `validate:"required,min=2,max=50"`
        Email string `validate:"required,email"`
        Age   int    `validate:"gte=0,lte=150"`
    }

    input := UserInput{
        Name:  user.Name,
        Email: user.Email,
        Age:   user.Age,
    }

    return v.validate.Struct(input)
}

// Usage in resolver/service
func (s *Service) CreateUser(ctx context.Context, input CreateUserInput) (*ent.User, error) {
    // Validate input
    if err := s.validator.Validate(input); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }

    // Create in database
    return s.client.User.Create().
        SetName(input.Name).
        SetEmail(input.Email).
        SetAge(input.Age).
        Save(ctx)
}
```

## Constraint Validation

```go
func CreateUser(ctx context.Context, client *ent.Client, email string) (*ent.User, error) {
    user, err := client.User.Create().
        SetEmail(email).
        Save(ctx)

    if err != nil {
        if ent.IsConstraintError(err) {
            // Handle duplicate email
            return nil, fmt.Errorf("email already exists: %w", err)
        }
        return nil, err
    }

    return user, nil
}
```

## Required vs Optional Fields

```go
func (User) Fields() []ent.Field {
    return []ent.Field{
        // Required (NOT NULL)
        field.String("name").
            NotEmpty(),

        field.String("email").
            NotEmpty().
            Unique(),

        // Optional (nullable in Go, NOT NULL in DB)
        field.String("nickname").
            Optional(),

        // Nillable (nullable in DB)
        field.String("phone").
            Optional().
            Nillable(),

        // With default (can be empty in Go)
        field.String("status").
            Default("active"),
    }
}
```
