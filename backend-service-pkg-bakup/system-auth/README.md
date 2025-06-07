# go-auth

这是一个使用 Go 构建的通用认证系统模板，适用于 Kratos 框架。当前支持 JWT 验证和令牌签发，结构清晰，方便扩展 OIDC、API Key 等认证方式。

## 包结构

- `auth/interface.go`: 定义认证相关的核心接口与结构体
- `auth/jwt/jwt_provider.go`: JWT 的认证与签发实现
- `auth/middleware.go`: 可插拔 HTTP 中间件，提取认证信息
``` chatgpt
## 模块生成系统提示词

请作为一个golang技术专家与我交流，我有一个项目使用go-kratos进行一个web项目开发，正在编写一个 authn 身份验证的公共接口，希望这个authn 可以接入jwt认证，oidc或者其他的身份验证方式。请提供一些思路给我，还有针对身份验证的核心接口方法有哪些，我知道有身份验证器，生成验证码，类似以下这种接口：

	Authenticate(requestContext context.Context, contextType ContextType) (*AuthClaims, error)
	AuthenticateToken(token string) (*AuthClaims, error)
	CreateIdentityWithContext(requestContext context.Context, contextType ContextType, claims AuthClaims) (context.Context, error)
	CreateIdentity(claims AuthClaims) (string, error)
	Close()
}
以上接口定义但是我觉得太复杂了，而且通用型不足，我希望你站在架构的视角在检查一下我的接口是否还需要优化或者补充接口方法，我的目的是打造一个通用切具备通用特点的认证系统。
```

``` gemini
请作为一个golang编程语言的架构师或者是资深开发工程师与我交流，使用go-kratos微服务框架搭建项目。在开发项目过程中需要有身份认证和身份鉴权功能，基于这个业务需求正在设计一个通用的身份认证/鉴权系统开发工具 go-auth 包，其中包含了身份验证模块（简写：anthn）和身份鉴权模块（简写：anthz）。
要求：解耦设计，实现可插拔，能够接入兼容多种主流协议与后端提供者。
参考：你在提供设计思路以及编码过程可以参照go-kratos和go-micro的一些可接口设计，我也更加偏向这些框架的设计方式。
使用场景说明：项目中实例化模块提供者，可以使用（google的wire/uber的dig）进行代码生成工具依赖注入自动连接组件，系统只需要在功能点中调用接口。

服务接口基础方法：
身份验证（Authenticator）：身份初始化（Init）、身份验证、令牌验证、令牌发放、令牌续期（刷新）、令牌注销（Destroy）、提供者名称（String/Name）、等；
身份鉴权（Authorizer）：权限初始化（Init）、权限验证、添加权限策略、权限策略注销（Destroy）、提供者名称（String/Name）、等；
备注：接口方法需要你来优化和补充，我只是给你一些基础提示。

服务提供者：
身份验证提供者（AuthnProvider）：Jwt 、OIDC、PSK、等；
身份鉴权提供者（AuthzProvider）：Casbin、OPA、Zanzibar、等；

服务中间件：
身份验证中间件（AuthnMiddleware）：身份验证中间件，用于身份验证和令牌验证；
身份鉴权中间件（AuthzMiddleware）：身份鉴权中间件，用于权限验证；

以上需求中需要你提供设计思路和编码过程，需实现至少一个提供者的。
```