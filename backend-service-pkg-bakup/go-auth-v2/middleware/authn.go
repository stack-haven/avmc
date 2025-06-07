// Package middleware 提供身份认证模块的中间件
package middleware

import (
	"context"
	"strings"

	"github.com/go-kratos/kratos/v2/log"
	"github.com/go-kratos/kratos/v2/middleware"
	"github.com/go-kratos/kratos/v2/transport"
	"github.com/go-kratos/kratos/v2/transport/http"

	"backend-service/pkg/go-auth/authn"
	autherrors "backend-service/pkg/go-auth/errors"
)

// AuthnMiddlewareOptions 身份验证中间件选项
type AuthnMiddlewareOptions struct {
	// Authenticator 是身份验证器
	Authenticator authn.Authenticator
	// SkipPaths 是跳过身份验证的路径
	SkipPaths []string
	// TokenLookup 是令牌查找位置（如 header:Authorization、query:token、cookie:jwt 等）
	TokenLookup string
	// TokenHeadName 是令牌头名称（如 Bearer）
	TokenHeadName string
	// ContextKey 是上下文键名
	ContextKey interface{}
	// VerifyOptions 是验证选项
	VerifyOptions *authn.VerifyOptions
	// Logger 是日志记录器
	Logger log.Logger
}

// DefaultAuthnMiddlewareOptions 默认身份验证中间件选项
var DefaultAuthnMiddlewareOptions = &AuthnMiddlewareOptions{
	SkipPaths:     []string{},
	TokenLookup:   "header:Authorization",
	TokenHeadName: "Bearer",
	ContextKey:    "auth-claims",
	VerifyOptions: &authn.VerifyOptions{},
	Logger:        nil,
}

// AuthnMiddleware 创建身份验证中间件
func AuthnMiddleware(authenticator authn.Authenticator, opts ...*AuthnMiddlewareOptions) middleware.Middleware {
	options := DefaultAuthnMiddlewareOptions
	if authenticator == nil {
		panic("身份验证器不能为空")
	}
	options.Authenticator = authenticator

	// 应用选项
	if len(opts) > 0 && opts[0] != nil {
		opt := opts[0]
		if opt.SkipPaths != nil {
			options.SkipPaths = opt.SkipPaths
		}
		if opt.TokenLookup != "" {
			options.TokenLookup = opt.TokenLookup
		}
		if opt.TokenHeadName != "" {
			options.TokenHeadName = opt.TokenHeadName
		}
		if opt.ContextKey != nil {
			options.ContextKey = opt.ContextKey
		}
		if opt.VerifyOptions != nil {
			options.VerifyOptions = opt.VerifyOptions
		}
		if opt.Logger != nil {
			options.Logger = opt.Logger
		}
	}

	// 创建日志记录器
	logger := log.NewHelper(options.Logger)
	if options.Logger == nil {
		logger = log.NewHelper(log.GetLogger())
	}

	// 解析令牌查找位置
	lookupParts := strings.Split(options.TokenLookup, ":")
	if len(lookupParts) != 2 {
		panic("无效的令牌查找位置格式: " + options.TokenLookup)
	}
	lookupSource := lookupParts[0]
	lookupKey := lookupParts[1]

	return func(handler middleware.Handler) middleware.Handler {
		return func(ctx context.Context, req interface{}) (interface{}, error) {
			tr, ok := transport.FromServerContext(ctx)
			if !ok {
				return handler(ctx, req)
			}

			// 检查是否跳过身份验证
			path := ""
			if info, ok := tr.(*http.Transport); ok {
				path = info.Request().URL.Path
			} else {
				path = tr.Operation()
			}

			for _, skipPath := range options.SkipPaths {
				if skipPath == path || (strings.HasSuffix(skipPath, "*") && strings.HasPrefix(path, skipPath[:len(skipPath)-1])) {
					return handler(ctx, req)
				}
			}

			// 提取令牌
			token := ""
			switch lookupSource {
			case "header":
				token = extractTokenFromHeader(tr, lookupKey, options.TokenHeadName)
			case "query":
				token = extractTokenFromQuery(tr, lookupKey)
			case "cookie":
				token = extractTokenFromCookie(tr, lookupKey)
			default:
				logger.Errorf("不支持的令牌查找位置: %s", lookupSource)
				return nil, autherrors.ErrInvalidToken
			}

			if token == "" {
				logger.Warnf("未找到令牌: %s", options.TokenLookup)
				return nil, autherrors.ErrInvalidToken
			}

			// 验证令牌
			claims, err := options.Authenticator.Verify(ctx, token, options.VerifyOptions)
			if err != nil {
				logger.Errorf("令牌验证失败: %v", err)
				return nil, autherrors.FromError(err)
			}

			// 将声明信息存储到上下文中
			ctx = context.WithValue(ctx, options.ContextKey, claims)

			return handler(ctx, req)
		}
	}
}

// 从请求头中提取令牌
func extractTokenFromHeader(tr transport.Transport, key, tokenHeadName string) string {
	if ht, ok := tr.(*http.Transport); ok {
		auth := ht.Request().Header.Get(key)
		if auth == "" {
			return ""
		}

		if tokenHeadName != "" {
			prefix := tokenHeadName + " "
			if !strings.HasPrefix(auth, prefix) {
				return ""
			}
			return auth[len(prefix):]
		}

		return auth
	}

	// 对于 gRPC，从元数据中提取
	md := tr.RequestHeader()
	vals := md.Get(key)
	if len(vals) == 0 {
		return ""
	}

	auth := vals[0]
	if tokenHeadName != "" {
		prefix := tokenHeadName + " "
		if !strings.HasPrefix(auth, prefix) {
			return ""
		}
		return auth[len(prefix):]
	}

	return auth
}

// 从查询参数中提取令牌
func extractTokenFromQuery(tr transport.Transport, key string) string {
	if ht, ok := tr.(*http.Transport); ok {
		return ht.Request().URL.Query().Get(key)
	}

	// gRPC 不支持查询参数
	return ""
}

// 从 Cookie 中提取令牌
func extractTokenFromCookie(tr transport.Transport, key string) string {
	if ht, ok := tr.(*http.Transport); ok {
		cookie, err := ht.Request().Cookie(key)
		if err != nil {
			return ""
		}
		return cookie.Value
	}

	// gRPC 不支持 Cookie
	return ""
}

// ClaimsFromContext 从上下文中获取声明信息
func ClaimsFromContext(ctx context.Context, key interface{}) (authn.Claims, bool) {
	if key == nil {
		key = DefaultAuthnMiddlewareOptions.ContextKey
	}

	claims, ok := ctx.Value(key).(authn.Claims)
	return claims, ok
}
