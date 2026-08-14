# 后端 Vibe Coding 实践指南

> Go + go-kratos 微服务开发规范与最佳实践

## 📋 文档概述

本指南基于 Vibe Coding 基础规范，针对 Ark Tech Platform 及其产品服务的后端开发提供详细的实践指导。主要涵盖：

- **Go 语言开发规范**
- **go-kratos 框架使用最佳实践**
- **微服务架构设计原则**
- **目录结构与代码组织**
- **数据库访问与 ORM 使用**
- **API 设计与实现**
- **认证授权与中间件**
- **错误处理与日志记录**
- **测试与部署策略**
- **性能优化与监控**

## 当前实现基线

- 当前后端实现是 Go + go-kratos v2，不使用旧产品文档中出现的 Spring Boot、Django 等泛化方案。
- API 契约以 `backend-service/proto` 为源头，生成到 `backend-service/api`。
- 业务实现按 `service -> biz/usecase -> data/repo -> ent schema` 分层。
- 活跃基础服务为 `backend-service/app/platform/admin` 和 `backend-service/app/ai/service`；`backend-service/app/platform/admin` 当前作为底座管理后台基础服务；`backend-service/app/version/service` 是已存在版本发布服务雏形，当前冻结，迭代 3 前不作为新增业务落点。
- 生成代码、Swagger UI bundle、Ent gen 目录不手工修改。
- Buf 与 Protobuf 生成流程见 [Buf 与 Protobuf 标准生成流程](./proto-buf-generation.md)。

## 🎯 技术栈

- **语言**：Go 1.24+（当前基线 1.24.6）
- **框架**：go-kratos v2
- **API 协议**：gRPC + HTTP
- **ORM**：entgo
- **数据库**：MySQL / PostgreSQL
- **缓存**：Redis（可选）
- **配置管理**：服务 `configs/config.yaml` 与生成的 `internal/conf` 配置结构；Apollo / Nacos 仅作为可扩展方向
- **服务注册与发现**：按当前服务配置启用；etcd / Consul 仅作为可扩展方向

## 📁 后端项目结构

```
backend-service/
├── api/                 # 生成的 API 代码
│   ├── platform/            # 底座管理后台 API
│   │   └── admin/v1/     # 底座管理后台基础服务接口
│   ├── common/          # 公共 API 定义
│   └── core/            # 核心服务 API
├── app/                 # 应用服务
│   ├── platform/admin/      # 底座管理后台基础服务
│   │   ├── cmd/         # 命令行入口
│   │   │   └── server/  # 服务器启动
│   │   ├── configs/     # 配置文件
│   │   ├── internal/    # 内部实现
│   │   │   ├── biz/      # 业务逻辑
│   │   │   ├── data/     # 数据访问
│   │   │   ├── server/   # 服务器配置
│   │   │   └── service/  # 服务实现
│   │   ├── proto/        # Protobuf 定义
│   │   └── README.md     # 服务说明
│   ├── ai/service/      # 底座 AI/chat 通用能力
│   └── version/service/ # 版本发布服务雏形，当前冻结
├── pkg/                 # 公共包
│   ├── auth/            # 认证授权
│   │   ├── authn/        # 认证
│   │   ├── authz/        # 授权
│   │   └── middleware/   # 中间件
│   ├── bootstrap/       # 启动配置
│   │   └── databases/    # 数据库启动
│   ├── entgo/           # entgo 工具
│   │   ├── mixin/        # 混合器
│   │   └── paging/        # 分页
│   ├── utils/           # 工具函数
│   │   ├── convert/       # 类型转换
│   │   ├── crypto/        # 加密
│   │   ├── id/            # ID 生成
│   │   ├── ip/            # IP 工具
│   │   ├── pagination/    # 分页
│   │   └── trans/         # 翻译
│   └── viewer/          # 视图工具
├── proto/               # Protobuf 定义文件
│   ├── platform/            # 底座管理后台 proto
│   │   └── admin/v1/      # 管理接口
│   ├── common/          # 公共定义
│   │   ├── conf/          # 配置
│   │   └── enum/          # 枚举
│   └── core/            # 核心服务
│       └── service/v1/    # 服务定义
├── go.mod               # Go 模块文件
├── go.sum               # 依赖校验文件
└── Makefile             # 构建脚本
```

## 🎨 Go 语言开发规范

### 1. 代码风格

- **缩进**：使用 2 个空格（与前端保持一致）
- **换行**：每行代码长度建议不超过 100 个字符
- **空行**：
  - 函数之间使用 1 个空行
  - 逻辑块之间使用 1 个空行
  - 文件末尾保留 1 个空行

- **命名规范**：
  - **变量**：使用驼峰命名法（camelCase）
  - **常量**：使用全大写 + 下划线（SNAKE_CASE）
  - **函数**：使用驼峰命名法（camelCase），动词 + 名词
  - **类型**：使用大驼峰命名法（PascalCase）
  - **包名**：使用小写字母，简短且有意义

### 2. 包管理

- **使用 Go Modules**：
  ```bash
  # 初始化模块
  go mod init backend-service
  
  # 添加依赖
  go get github.com/go-kratos/kratos/v2
  
  # 整理依赖
  go mod tidy
  ```

- **依赖版本管理**：
  - 固定依赖版本，避免使用 `latest`
  - 使用 `go.sum` 确保依赖一致性
  - 定期更新依赖，修复安全漏洞

### 3. 错误处理

- **使用标准错误**：
  ```go
  // ✅ 推荐
  func getUser(id int) (*User, error) {
    user, err := repo.FindByID(id)
    if err != nil {
      return nil, errors.Wrap(err, "find user by id failed")
    }
    return user, nil
  }
  
  // ❌ 不推荐
  func getUser(id int) (*User, error) {
    user, err := repo.FindByID(id)
    if err != nil {
      return nil, err
    }
    return user, nil
  }
  ```

- **错误包装**：使用 `github.com/pkg/errors` 包进行错误包装
  - 保留错误链，便于排查问题
  - 添加上下文信息，提高错误可读性

- **错误返回**：
  - 函数应返回错误作为最后一个返回值
  - 处理错误后应返回，避免继续执行
  - 不要忽略错误，即使是临时调试

### 4. 日志记录

- **使用 go-kratos 日志**：
  ```go
  import "github.com/go-kratos/kratos/v2/log"
  
  type UserService struct {
    repo UserRepo
    log  *log.Helper
  }
  
  func NewUserService(repo UserRepo, logger log.Logger) *UserService {
    return &UserService{
      repo: repo,
      log:  log.NewHelper(logger),
    }
  }
  
  func (s *UserService) GetUser(ctx context.Context, id int64) (*User, error) {
    s.log.WithContext(ctx).Infof("get user by id: %d", id)
    // ...
  }
  ```

- **日志级别**：
  - `Debug`：调试信息，仅开发环境
  - `Info`：普通信息，如操作成功
  - `Warn`：警告信息，如参数错误
  - `Error`：错误信息，如数据库异常
  - `Fatal`：致命错误，如服务启动失败

- **日志内容**：
  - 包含上下文信息，如用户 ID、操作类型
  - 包含错误详情，便于排查
  - 避免敏感信息，如密码、令牌

## 🚀 go-kratos 框架使用规范

### 1. 服务定义

- **Protobuf 定义**：
  ```protobuf
  // proto/avmc/admin/v1/i_user.proto
  syntax = "proto3";
  
  package avmc.admin.v1;
  
  import "google/api/annotations.proto";
  import "common/conf/base.proto";
  
  service IUser {
    rpc CreateUser(CreateUserRequest) returns (CreateUserResponse) {
      option (google.api.http) = {
        post: "/api/v1/users"
        body: "*"
      };
    }
    
    rpc GetUser(GetUserRequest) returns (GetUserResponse) {
      option (google.api.http) = {
        get: "/api/v1/users/{id}"
      };
    }
    
    rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse) {
      option (google.api.http) = {
        put: "/api/v1/users/{id}"
        body: "*"
      };
    }
    
    rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse) {
      option (google.api.http) = {
        delete: "/api/v1/users/{id}"
      };
    }
    
    rpc ListUsers(ListUsersRequest) returns (ListUsersResponse) {
      option (google.api.http) = {
        get: "/api/v1/users"
      };
    }
  }
  
  message CreateUserRequest {
    string username = 1;
    string password = 2;
    string email = 3;
    string phone = 4;
  }
  
  message CreateUserResponse {
    int64 id = 1;
    string username = 2;
  }
  
  // 其他消息定义...
  ```

- **生成 API 代码**：
  ```bash
  # 使用 buf 生成代码
  make proto
  
  # 或直接使用 kratos 命令
  kratos proto add proto/avmc/admin/v1/i_user.proto
  kratos proto client proto/avmc/admin/v1
  kratos proto server proto/avmc/admin/v1
  ```

### 2. 服务实现

- **六边形架构**：
  - **API 层**：处理请求和响应
  - **服务层**：实现业务逻辑
  - **领域层**：核心业务规则
  - **数据层**：数据访问和持久化

- **服务定义**：
  ```go
  // internal/service/user_service.go
  type UserService struct {
    userRepo  UserRepo
    roleRepo  RoleRepo
    authRepo  AuthRepo
    log       *log.Helper
  }
  
  func NewUserService(
    userRepo UserRepo,
    roleRepo RoleRepo,
    authRepo AuthRepo,
    logger log.Logger,
  ) *UserService {
    return &UserService{
      userRepo:  userRepo,
      roleRepo:  roleRepo,
      authRepo:  authRepo,
      log:       log.NewHelper(logger),
    }
  }
  
  func (s *UserService) CreateUser(ctx context.Context, req *pb.CreateUserRequest) (*pb.CreateUserResponse, error) {
    // 业务逻辑实现
  }
  ```

### 3. 依赖注入

- **使用 wire**：
  ```go
  // cmd/server/wire.go
  //go:build wireinject
  // +build wireinject
  
  package main
  
  import (
    "github.com/google/wire"
    "backend-service/app/platform/admin/internal/biz"
    "backend-service/app/platform/admin/internal/data"
    "backend-service/app/platform/admin/internal/service"
    "backend-service/app/platform/admin/internal/server"
  )
  
  func initApp() (*App, error) {
    panic(wire.Build(
      // 数据层
      data.ProviderSet,
      // 业务层
      biz.ProviderSet,
      // 服务层
      service.ProviderSet,
      // 服务器
      server.ProviderSet,
      // 应用
      NewApp,
    ))
  }
  ```

- **生成依赖注入代码**：
  ```bash
  make wire
  ```

## 📚 数据库访问规范

### 1. entgo ORM 使用

- **Schema 定义**：
  ```go
  // internal/data/ent/schema/user.go
  package schema
  
  import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "entgo.io/ent/schema/index"
  )
  
  type User struct {
    ent.Schema
  }
  
  func (User) Fields() []ent.Field {
    return []ent.Field{
      field.Int64("id").Unique().Immutable(),
      field.String("username").Unique().NotEmpty(),
      field.String("password").NotEmpty(),
      field.String("email").Unique().Optional(),
      field.String("phone").Unique().Optional(),
      field.Int64("role_id").Optional(),
      field.Bool("status").Default(true),
      field.Time("created_at").Immutable(),
      field.Time("updated_at"),
    }
  }
  
  func (User) Indexes() []ent.Index {
    return []ent.Index{
      index.Fields("username"),
      index.Fields("email"),
      index.Fields("phone"),
      index.Fields("role_id"),
    }
  }
  ```

- **生成 ORM 代码**：
  ```bash
  make ent
  ```

### 2. 数据访问层

- **Repository 模式**：
  ```go
  // internal/data/user_repo.go
  type UserRepo interface {
    Create(ctx context.Context, user *User) (*User, error)
    Update(ctx context.Context, user *User) (*User, error)
    Delete(ctx context.Context, id int64) error
    FindByID(ctx context.Context, id int64) (*User, error)
    FindByUsername(ctx context.Context, username string) (*User, error)
    List(ctx context.Context, page, pageSize int) ([]*User, int64, error)
  }
  
  type userRepo struct {
    client *ent.Client
  }
  
  func NewUserRepo(client *ent.Client) UserRepo {
    return &userRepo{client: client}
  }
  
  func (r *userRepo) Create(ctx context.Context, user *User) (*User, error) {
    // 实现
  }
  ```

- **事务管理**：
  ```go
  func (r *userRepo) CreateWithRole(ctx context.Context, user *User, roleIDs []int64) (*User, error) {
    return r.client.Tx(ctx, func(tx *ent.Tx) (*User, error) {
      // 创建用户
      createdUser, err := tx.User.Create().
        SetUsername(user.Username).
        SetPassword(user.Password).
        Save(ctx)
      if err != nil {
        return nil, err
      }
      
      // 关联角色
      for _, roleID := range roleIDs {
        if err := tx.UserRole.Create().
          SetUserID(createdUser.ID).
          SetRoleID(roleID).
          Save(ctx); err != nil {
          return nil, err
        }
      }
      
      return createdUser, nil
    })
  }
  ```

### 3. 数据库配置

- **配置文件**：
  ```yaml
  # configs/config.yaml
  data:
    database:
      driver: mysql
      source: user:password@tcp(localhost:3306)/avmc?charset=utf8mb4&parseTime=True&loc=Local
  ```

- **数据库连接**：
  ```go
  // internal/data/ent_client.go
  func NewEntClient(cfg *conf.Data_Database) (*ent.Client, error) {
    client, err := ent.Open(cfg.Driver, cfg.Source)
    if err != nil {
      return nil, errors.Wrap(err, "failed to connect to database")
    }
    
    // 自动迁移
    if err := client.Schema.Create(context.Background()); err != nil {
      return nil, errors.Wrap(err, "failed to migrate database schema")
    }
    
    return client, nil
  }
  ```

## 🔒 认证授权规范

### 1. JWT 认证

- **Token 生成**：
  ```go
  // pkg/auth/authn/jwt/jwt.go
  func GenerateToken(userID int64, username string, roles []string) (string, error) {
    claims := Claims{
      UserID:   userID,
      Username: username,
      Roles:    roles,
      StandardClaims: jwt.StandardClaims{
        ExpiresAt: time.Now().Add(24 * time.Hour).Unix(),
        IssuedAt:  time.Now().Unix(),
        Issuer:    "avmc",
      },
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secretKey))
  }
  ```

- **Token 验证**：
  ```go
  func ValidateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
      return []byte(secretKey), nil
    })
    
    if err != nil {
      return nil, err
    }
    
    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
      return claims, nil
    }
    
    return nil, errors.New("invalid token")
  }
  ```

### 2. 中间件

- **认证中间件**：
  ```go
  // pkg/auth/middleware/grpc.go
  func AuthMiddleware() middleware.Middleware {
    return func(handler middleware.Handler) middleware.Handler {
      return func(ctx context.Context, req interface{}) (interface{}, error) {
        // 从请求中获取 token
        token := getTokenFromContext(ctx)
        if token == "" {
          return nil, errors.Unauthorized("missing token")
        }
        
        // 验证 token
        claims, err := auth.ValidateToken(token)
        if err != nil {
          return nil, errors.Unauthorized("invalid token")
        }
        
        // 将用户信息添加到上下文
        ctx = context.WithValue(ctx, "user_id", claims.UserID)
        ctx = context.WithValue(ctx, "username", claims.Username)
        ctx = context.WithValue(ctx, "roles", claims.Roles)
        
        return handler(ctx, req)
      }
    }
  }
  ```

- **授权中间件**：
  ```go
  func RoleMiddleware(requiredRoles ...string) middleware.Middleware {
    return func(handler middleware.Handler) middleware.Handler {
      return func(ctx context.Context, req interface{}) (interface{}, error) {
        // 从上下文获取用户角色
        roles, ok := ctx.Value("roles").([]string)
        if !ok {
          return nil, errors.Unauthorized("unauthorized")
        }
        
        // 检查是否有 required role
        hasRole := false
        for _, role := range roles {
          for _, requiredRole := range requiredRoles {
            if role == requiredRole {
              hasRole = true
              break
            }
          }
          if hasRole {
            break
          }
        }
        
        if !hasRole {
          return nil, errors.Forbidden("insufficient permissions")
        }
        
        return handler(ctx, req)
      }
    }
  }
  ```

## 📡 API 设计规范

### 1. RESTful API 设计

- **HTTP 方法**：
  - `GET`：获取资源
  - `POST`：创建资源
  - `PUT`：更新资源
  - `DELETE`：删除资源
  - `PATCH`：部分更新资源

- **URL 设计**：
  - 使用小写字母和短横线
  - 资源使用复数形式
  - 避免使用动词
  
  ```
  // ✅ 推荐
  GET    /api/v1/users           # 获取用户列表
  POST   /api/v1/users           # 创建用户
  GET    /api/v1/users/{id}      # 获取用户详情
  PUT    /api/v1/users/{id}      # 更新用户
  DELETE /api/v1/users/{id}      # 删除用户
  
  // ❌ 不推荐
  GET    /api/v1/getUsers        # 使用动词
  POST   /api/v1/createUser      # 使用动词
  GET    /api/v1/user/{id}       # 单数形式
  ```

### 2. gRPC API 设计

- **服务命名**：使用 PascalCase，后缀为 `Service`
  ```protobuf
  service UserService {
    // 方法定义
  }
  ```

- **方法命名**：使用 PascalCase，动词 + 名词
  ```protobuf
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  ```

- **消息命名**：
  - 请求消息：`MethodNameRequest`
  - 响应消息：`MethodNameResponse`
  - 数据消息：使用 PascalCase

### 3. 响应格式

- **统一响应结构**：
  ```protobuf
  message BaseResponse {
    int32 code = 1;
    string msg = 2;
    google.protobuf.Any data = 3;
  }
  ```

- **错误码定义**：
  ```protobuf
  enum ErrorCode {
    SUCCESS = 0;
    BAD_REQUEST = 400;
    UNAUTHORIZED = 401;
    FORBIDDEN = 403;
    NOT_FOUND = 404;
    INTERNAL_ERROR = 500;
  }
  ```

## 🧪 测试规范

### 1. 测试分层

- **单元测试**：测试单个函数或方法
- **集成测试**：测试模块间的交互
- **端到端测试**：测试完整的业务流程

### 2. 测试文件命名

- **测试文件**：使用 `_test.go` 后缀
  ```
  user_service_test.go
  user_repo_test.go
  auth_middleware_test.go
  ```

- **测试函数**：使用 `Test` 前缀，PascalCase
  ```go
  func TestUserService_CreateUser(t *testing.T) {
    // 测试
  }
  
  func TestUserRepo_FindByID(t *testing.T) {
    // 测试
  }
  ```

### 3. 测试工具

- **使用表驱动测试**：
  ```go
  func TestUserService_CreateUser(t *testing.T) {
    tests := []struct {
      name     string
      req      *pb.CreateUserRequest
      wantErr  bool
      errMsg   string
    }{
      {
        name: "success",
        req: &pb.CreateUserRequest{
          Username: "test",
          Password: "123456",
        },
        wantErr: false,
      },
      {
        name: "empty username",
        req: &pb.CreateUserRequest{
          Username: "",
          Password: "123456",
        },
        wantErr: true,
        errMsg:  "username is required",
      },
    }
    
    for _, tt := range tests {
      t.Run(tt.name, func(t *testing.T) {
        // 测试逻辑
      })
    }
  }
  ```

- **使用 mock**：
  ```go
  import "github.com/stretchr/testify/mock"
  
  type MockUserRepo struct {
    mock.Mock
  }
  
  func (m *MockUserRepo) Create(ctx context.Context, user *User) (*User, error) {
    args := m.Called(ctx, user)
    return args.Get(0).(*User), args.Error(1)
  }
  
  func TestUserService_CreateUser(t *testing.T) {
    mockRepo := &MockUserRepo{}
    service := NewUserService(mockRepo, nil, nil, log.Default())
    
    // 设置 mock 预期
    mockRepo.On("Create", mock.Anything, mock.Anything).
      Return(&User{ID: 1, Username: "test"}, nil)
    
    // 执行测试
    req := &pb.CreateUserRequest{Username: "test", Password: "123456"}
    resp, err := service.CreateUser(context.Background(), req)
    
    // 验证结果
    assert.NoError(t, err)
    assert.Equal(t, int64(1), resp.Id)
    mockRepo.AssertExpectations(t)
  }
  ```

### 4. 测试覆盖率

- **目标**：
  - 核心业务逻辑：≥ 80%
  - 关键路径：≥ 90%
  - 工具函数：≥ 95%

- **运行测试**：
  ```bash
  # 运行所有测试
  make test
  
  # 运行特定包测试
  go test ./internal/service/...
  
  # 查看测试覆盖率
  go test -cover ./internal/service/...
  
  # 生成覆盖率报告
  go test -coverprofile=coverage.out ./...
  go tool cover -html=coverage.out
  ```

## 🚀 部署策略

### 1. 构建与打包

- **Makefile**：
  ```makefile
  # Makefile
  .PHONY: build
  build:
    mkdir -p output
    go build -o output/avmc ./cmd/server
    cp configs/config.yaml output/
    cp -r scripts output/
  
  .PHONY: docker
  docker:
    docker build -t avmc:latest .
    docker push avmc:latest
  ```

- **Dockerfile**：
  ```dockerfile
  # Dockerfile
  FROM golang:1.24-alpine as builder
  
  WORKDIR /app
  COPY . .
  
  RUN go mod tidy
  RUN go build -o server ./cmd/server
  
  FROM alpine:latest
  
  WORKDIR /app
  COPY --from=builder /app/server /app/
  COPY --from=builder /app/configs /app/configs
  
  EXPOSE 8000 9000
  
  CMD ["./server"]
  ```

### 2. 环境配置

- **多环境配置**：
  - `configs/config.dev.yaml`：开发环境
  - `configs/config.test.yaml`：测试环境
  - `configs/config.prod.yaml`：生产环境

- **配置中心**：
  - 使用 Apollo 或 Nacos 管理配置
  - 支持动态配置更新
  - 配置版本管理

### 3. 服务注册与发现

- **使用 etcd**：
  ```go
  // internal/server/grpc.go
  func NewGRPCServer(cfg *conf.Server, logger log.Logger) *grpc.Server {
    // 创建 etcd 客户端
    etcdClient, err := clientv3.New(clientv3.Config{
      Endpoints: []string{"localhost:2379"},
    })
    if err != nil {
      log.Fatal(err)
    }
    
    // 创建注册器
    registrar := etcd.NewEtcdRegistry(etcdClient)
    
    // 创建 gRPC 服务器
    srv := grpc.NewServer(
      grpc.Address(cfg.Grpc.Addr),
      grpc.Registrar(registrar),
    )
    
    return srv
  }
  ```

- **服务发现**：
  ```go
  // 客户端服务发现
  func NewUserClient(cfg *conf.Client) (userpb.UserServiceClient, error) {
    // 创建 etcd 客户端
    etcdClient, err := clientv3.New(clientv3.Config{
      Endpoints: []string{"localhost:2379"},
    })
    if err != nil {
      return nil, err
    }
    
    // 创建解析器
    resolver := etcd.NewEtcdResolver(etcdClient)
    
    // 创建 gRPC 客户端
    conn, err := grpc.Dial(
      "user-service",
      grpc.WithResolver(resolver),
      grpc.WithInsecure(),
    )
    if err != nil {
      return nil, err
    }
    
    return userpb.NewUserServiceClient(conn), nil
  }
  ```

## ⚡ 性能优化

### 1. 代码优化

- **避免内存分配**：
  - 使用对象池
  - 避免频繁创建临时对象
  - 使用 `sync.Pool` 管理复用对象

- **并发优化**：
  - 使用 goroutine 处理并发任务
  - 合理使用 channel 进行通信
  - 避免共享变量，使用互斥锁或原子操作

- **数据库优化**：
  - 使用索引
  - 避免全表扫描
  - 批量操作减少数据库访问次数
  - 使用连接池

### 2. 监控与告警

- **指标监控**：
  - 使用 Prometheus 收集指标
  - 监控 QPS、响应时间、错误率
  - 监控数据库连接池、内存使用

- **日志监控**：
  - 使用 ELK 或 Loki 收集日志
  - 设置日志级别和保留策略
  - 配置错误日志告警

- **分布式追踪**：
  - 使用 Jaeger 或 Zipkin
  - 追踪请求链路
  - 识别性能瓶颈

### 3. 缓存策略

- **Redis 缓存**：
  - 缓存热点数据
  - 设置合理的过期时间
  - 实现缓存预热
  - 处理缓存穿透、击穿、雪崩

- **本地缓存**：
  - 使用 `sync.Map` 或第三方库
  - 缓存不常变化的数据
  - 减少网络请求

## 🎯 最佳实践总结

### 项目特有约定（优先于通用规范）

以下规则基于 Ark Tech Platform 租户管理/用户部门模块梳理提炼：

1. **安全三件套（Data 层必守）**：每个数据面方法（List/Get/Create/Update/Delete/其他写操作）必须按顺序执行：
   - ① `RequireTenantID(ctx)` — 从 context 提取租户 ID，租户隔离第一道防线
   - ② 业务校验 — 存在性、唯一性、状态合法性、循环引用检测等
   - ③ 事务包裹（写操作） — 多表变更用 `InTx` 保证原子性
2. **Proto 类型贯穿**：Service → Biz → Data 接口签名全部使用 `pbCore.Xxx`，转换只在 Data 层做 `ent ↔ proto`
3. **字段命名**：Proto `snake_case` ↔ Go `PascalCase`（生成代码），手写 Go 用 `camelCase`；`uint32` 做 ID 类型，枚举首个值必为 `*_UNSPECIFIED = 0`
4. **错误码**：使用 kratos errors `UPPER_SNAKE_CASE`，区分 `BadRequest`/`NotFound`/`Conflict`/`Forbidden`，前端能据此给出差异化反馈
5. **供应商模式（provider pattern）**：对外部服务商（对象存储、短信、推送、邮件等）统一采用工厂注册模式，与 `pkg/objectstorage`、`pkg/notifier` 同构：
   - **统一接口层**：`pkg/xxx` 定义唯一 `Client`/`Sender` 接口 + `Message`/类型 + 工厂 `Register`/`NewClient`；不在渠道下再定义独立接口
   - **两层维度分离**：当存在「渠道（业务维度）→ 提供商（技术维度）」嵌套时，用 `channel` + `provider_type` 两个字段区分，工厂按 **provider_type** 注册，不按 channel（避免后注册覆盖）
   - **目录结构**：`pkg/xxx/{channel}/{provider}/`（如 `pkg/notifier/sms/aliyun`），每个提供商独立包实现接口 + `init()` 注册
   - **平台级配置表**：`XxxProvider` 存渠道/提供商/密钥/默认标记/状态，密钥脱敏返回（`secret_configured` 不回传明文），提供连通测试
   - **resolver**：按业务维度（channel/type）查默认配置 → 读 `provider_type` → `NewClient(provider_type, config)`
   - 新增提供商只需实现接口 + 注册工厂，**框架零改动**

### 通用规范

1. **遵循 Go 语言规范**：使用标准库，遵循官方代码风格
2. **采用六边形架构**：清晰的分层结构，易于测试和维护
3. **使用依赖注入**：通过 wire 实现依赖注入，减少耦合
4. **统一错误处理**：使用标准错误，添加上下文信息
5. **完善日志记录**：合理的日志级别，包含必要信息
6. **重视测试**：单元测试、集成测试、端到端测试
7. **优化数据库访问**：使用索引，批量操作，事务管理
8. **设计良好的 API**：RESTful 风格，统一响应格式
9. **实现认证授权**：JWT 认证，基于角色的授权
10. **关注性能**：并发优化，缓存策略，监控告警
11. **规范部署**：Docker 容器化，配置中心，服务注册与发现

## 📚 参考资料

- [Go 官方文档](https://golang.org/doc/)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [go-kratos 官方文档](https://go-kratos.dev/)
- [entgo 官方文档](https://entgo.io/)
- [gRPC 官方文档](https://grpc.io/docs/)
- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Jaeger 官方文档](https://www.jaegertracing.io/docs/)

## 🤝 贡献指南

欢迎对后端 Vibe Coding 实践指南提出改进建议：

1. 创建 Issue 描述问题或建议
2. 提交 PR 包含具体的改进内容
3. 参与讨论，完善指南内容

---

**后端 Vibe Coding 实践指南** | 持续更新中 🚀
