# Schema Edges (Relationships)

## One-to-One (O2O)

```go
// User has one Card
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("card", Card.Type).
            Unique(),  // One-to-one
    }
}

// Card belongs to one User
func (Card) Edges() []ent.Edge {
    return []ent.Edge{
        edge.From("owner", User.Type).
            Ref("card").
            Unique().
            Required(),  // Must have an owner
    }
}
```

## One-to-Many (O2M)

```go
// User has many Pets
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("pets", Pet.Type),
    }
}

// Pet belongs to one User
func (Pet) Edges() []ent.Edge {
    return []ent.Edge{
        edge.From("owner", User.Type).
            Ref("pets").
            Unique(),
    }
}
```

## Many-to-Many (M2M)

```go
// User belongs to many Groups
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.From("groups", Group.Type).
            Ref("users"),
    }
}

// Group has many Users
func (Group) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("users", User.Type),
    }
}
```

## Self-Referencing (Friends)

```go
// User has friends (other users)
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("friends", User.Type),
    }
}
```

## Many-to-Many with Through Table

```go
// User has many Tweets through UserTweet
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("tweets", Tweet.Type).
            Through("user_tweets", UserTweet.Type),
    }
}

// UserTweet is the join table
func (UserTweet) Fields() []ent.Field {
    return []ent.Field{
        field.Time("liked_at"),
    }
}

func (UserTweet) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("user", User.Type).
            Unique().
            Required(),
        edge.To("tweet", Tweet.Type).
            Unique().
            Required(),
    }
}
```

## Edge Options

```go
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        // Required edge
        edge.To("profile", Profile.Type).
            Required(),

        // Unique edge (O2O or O2M from other side)
        edge.To("card", Card.Type).
            Unique(),

        // Storage key (foreign key column name)
        edge.To("pets", Pet.Type).
            StorageKey(edge.Column("owner_id")),

        // Edge comment
        edge.To("pets", Pet.Type).
            Comment("User's pets"),

        // Cascade deletion
        edge.To("pets", Pet.Type).
            StorageKey(edge.Column("owner_id")).
            Annotations(
                annotation.OnDelete(annotation.Cascade),
            ),

        // Set null on delete
        edge.To("pets", Pet.Type).
            Annotations(
                annotation.OnDelete(annotation.SetNull),
            ),
    }
}
```

## Bidirectional Edges

```go
// Full example: User <-> Pet relationship
func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("pets", Pet.Type).
            StorageKey(edge.Column("owner_id")),
        edge.From("favorite_pet", Pet.Type).
            Ref("favorite_of").
            Unique(),
    }
}

func (Pet) Edges() []ent.Edge {
    return []ent.Edge{
        edge.From("owner", User.Type).
            Ref("pets").
            Unique(),
        edge.To("favorite_of", User.Type).
            Unique(),
    }
}
```
