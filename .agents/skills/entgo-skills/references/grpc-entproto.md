# gRPC Integration (entproto)

## Installation

```bash
go get entgo.io/contrib/entproto
```

## Setup entproto

```go
// ent/generate.go
package ent

//go:generate go run -mod=mod entgo.io/ent/cmd/ent generate ./schema
//go:generate go run -mod=mod entgo.io/contrib/entproto/cmd/entproto -path ./schema
```

## Schema Annotations

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema"
    "entgo.io/ent/schema/field"
    "entgo.io/contrib/entproto"
)

type User struct {
    ent.Schema
}

func (User) Annotations() []schema.Annotation {
    return []schema.Annotation{
        // Generate Protobuf message
        entproto.Message(),
        // Generate gRPC service
        entproto.Service(),
    }
}

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name").
            Annotations(
                entproto.Field(2),
            ),
        field.String("email").
            Annotations(
                entproto.Field(3),
            ),
        field.Int("age").
            Annotations(
                entproto.Field(4),
            ),
    }
}
```

## Generate Protobuf

```bash
# Install protoc plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install entgo.io/contrib/entproto/cmd/protoc-gen-entgrpc@latest

# Generate code
cd ent/proto
go generate ./...
```

## Generated Protobuf

```protobuf
// entpb/entpb.proto
syntax = "proto3";

package entpb;

option go_package = "myapp/ent/proto/entpb";

message User {
  int32 id = 1;
  string name = 2;
  string email = 3;
  int32 age = 4;
}

message CreateUserRequest {
  User user = 1;
}

message CreateUserResponse {
  User user = 1;
}

message GetUserRequest {
  int32 id = 1;
}

message GetUserResponse {
  User user = 1;
}

message UpdateUserRequest {
  User user = 1;
}

message UpdateUserResponse {
  User user = 1;
}

message DeleteUserRequest {
  int32 id = 1;
}

message DeleteUserResponse {
  bool deleted = 1;
}

message ListUserRequest {
  int32 page_size = 1;
  string page_token = 2;
}

message ListUserResponse {
  repeated User user_list = 1;
  string next_page_token = 2;
}

service UserService {
  rpc Create (CreateUserRequest) returns (CreateUserResponse);
  rpc Get (GetUserRequest) returns (GetUserResponse);
  rpc Update (UpdateUserRequest) returns (UpdateUserResponse);
  rpc Delete (DeleteUserRequest) returns (DeleteUserResponse);
  rpc List (ListUserRequest) returns (ListUserResponse);
}
```

## gRPC Server Implementation

```go
package main

import (
    "context"
    "log"
    "net"

    "myapp/ent"
    "myapp/ent/proto/entpb"

    "google.golang.org/grpc"
    _ "github.com/mattn/go-sqlite3"
)

type server struct {
    entpb.UnimplementedUserServiceServer
    client *ent.Client
}

func (s *server) Create(ctx context.Context, req *entpb.CreateUserRequest) (*entpb.CreateUserResponse, error) {
    user, err := s.client.User.Create().
        SetName(req.User.Name).
        SetEmail(req.User.Email).
        SetAge(int(req.User.Age)).
        Save(ctx)
    if err != nil {
        return nil, err
    }

    return &entpb.CreateUserResponse{
        User: toProtoUser(user),
    }, nil
}

func (s *server) Get(ctx context.Context, req *entpb.GetUserRequest) (*entpb.GetUserResponse, error) {
    user, err := s.client.User.Get(ctx, int(req.Id))
    if err != nil {
        return nil, err
    }

    return &entpb.GetUserResponse{
        User: toProtoUser(user),
    }, nil
}

func toProtoUser(u *ent.User) *entpb.User {
    return &entpb.User{
        Id:    int32(u.ID),
        Name:  u.Name,
        Email: u.Email,
        Age:   int32(u.Age),
    }
}

func main() {
    client, err := ent.Open("sqlite3", "file:ent.db?_fk=1")
    if err != nil {
        log.Fatalf("failed opening connection: %v", err)
    }
    defer client.Close()

    lis, err := net.Listen("tcp", ":50051")
    if err != nil {
        log.Fatalf("failed to listen: %v", err)
    }

    s := grpc.NewServer()
    entpb.RegisterUserServiceServer(s, &server{client: client})

    log.Println("gRPC server listening on :50051")
    if err := s.Serve(lis); err != nil {
        log.Fatalf("failed to serve: %v", err)
    }
}
```

## Custom Proto Options

```go
func (User) Annotations() []schema.Annotation {
    return []schema.Annotation{
        entproto.Message(
            entproto.Package("myapp.users"),
            entproto.MultiEdge(
                entproto.MapEdge("groups", "GroupsInput"),
            ),
        ),
    }
}
```
