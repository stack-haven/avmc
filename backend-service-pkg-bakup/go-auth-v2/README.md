# Go-Auth 模块

## 简介

`go-auth` 是一个基于 Go-Kratos 微服务框架的通用身份认证模块，同时支持身份验证（Authn）与身份鉴权（Authz）。该模块设计具备通用可扩展特性，逻辑解耦、可插拔，能够兼容多种主流协议与后端提供者。

## 设计原则

- **接口驱动设计**：通过接口定义行为，实现与具体实现的解耦
- **依赖反转原则**：高层模块不依赖低层模块，两者都依赖抽象
- **开闭原则**：对扩展开放，对修改关闭

## 设计目标

- 模块通用、可插拔、协议无关
- 易扩展，支持多种认证与鉴权提供者
- 松耦合，使用 interface-based 设计
- 遵循 SOLID 原则（特别是开闭原则与依赖反转）

## 模块结构

```
pkg/go-auth/
├── authn/                  # 身份验证相关
│   ├── interface.go        # 身份验证接口定义
│   ├── provider/           # 身份验证提供者实现
│   │   ├── jwt/            # JWT 提供者
│   │   ├── oidc/           # OIDC 提供者（预留）
│   │   └── psk/            # PSK 提供者（预留）
├── authz/                  # 身份鉴权相关
│   ├── interface.go        # 身份鉴权接口定义
│   ├── provider/           # 身份鉴权提供者实现
│   │   ├── casbin/         # Casbin 提供者
│   │   ├── opa/            # OPA 提供者（预留）
│   │   └── zanzibar/       # Zanzibar 提供者（预留）
├── middleware/             # 中间件
│   ├── authn.go            # 身份验证中间件
│   └── authz.go            # 身份鉴权中间件
├── errors/                 # 错误定义
├── config/                 # 配置结构
├── wire.go                 # 依赖注入
└── registry.go             # 提供者注册
```

## 使用方式

### 初始化

```go
// 使用 Wire 进行依赖注入
auth, cleanup, err := InitAuth(ctx, cfg)
if err != nil {
    return nil, nil, err
}
defer cleanup()

// 或手动初始化
authenticator := jwt.NewAuthenticator(cfg.JWT)
authorizer := casbin.NewAuthorizer(cfg.Casbin)
```

### 中间件使用

```go
// HTTP 服务器中使用
server := http.NewServer(
    http.Address(":8000"),
    http.Middleware(
        middleware.AuthnMiddleware(authenticator),
        middleware.AuthzMiddleware(authorizer),
    ),
)

// gRPC 服务器中使用
server := grpc.NewServer(
    grpc.Address(":9000"),
    grpc.Middleware(
        middleware.AuthnMiddleware(authenticator),
        middleware.AuthzMiddleware(authorizer),
    ),
)
```

## 扩展方式

### 添加新的身份验证提供者

实现 `authn.Authenticator` 接口，并在 `registry.go` 中注册。

### 添加新的身份鉴权提供者

实现 `authz.Authorizer` 接口，并在 `registry.go` 中注册。