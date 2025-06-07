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
	"backend-service/pkg/go-auth/authz"
	autherrors "backend-service/pkg/go-auth/errors"
)

// AuthzMiddlewareOptions 身份鉴权中间件选项
type AuthzMiddlewareOptions struct {
	// Authorizer 是身份鉴权器
	Authorizer authz.Authorizer
	// SkipPaths 是跳过身份鉴权的路径
	SkipPaths []string
	// ClaimsContextKey 是声明上下文键名
	ClaimsContextKey interface{}
	// SubjectExtractor 是主体提取器
	SubjectExtractor func(ctx context.Context, claims authn.Claims) (*authz.Subject, error)
	// ActionExtractor 是操作提取器
	ActionExtractor func(ctx context.Context, tr transport.Transport) (*authz.Action, error)
	// ResourceExtractor 是资源提取器
	ResourceExtractor func(ctx context.Context, tr transport.Transport, req interface{}) (*authz.Resource, error)
	// AuthorizeOptions 是鉴权选项
	AuthorizeOptions *authz.AuthorizeOptions
	// Logger 是日志记录器
	Logger log.Logger
}

// DefaultAuthzMiddlewareOptions 默认身份鉴权中间件选项
var DefaultAuthzMiddlewareOptions = &AuthzMiddlewareOptions{
	SkipPaths:         []string{},
	ClaimsContextKey:  DefaultAuthnMiddlewareOptions.ContextKey,
	SubjectExtractor:  DefaultSubjectExtractor,
	ActionExtractor:   DefaultActionExtractor,
	ResourceExtractor: DefaultResourceExtractor,
	AuthorizeOptions:  &authz.AuthorizeOptions{},
	Logger:            nil,
}

// DefaultSubjectExtractor 默认主体提取器
func DefaultSubjectExtractor(ctx context.Context, claims authn.Claims) (*authz.Subject, error) {
	if claims == nil {
		return nil, autherrors.ErrInvalidSubject
	}

	// 提取主体 ID
	subjectID, ok := claims["sub"].(string)
	if !ok || subjectID == "" {
		subjectID, ok = claims["id"].(string)
		if !ok || subjectID == "" {
			return nil, autherrors.NewInvalidSubjectError("主体 ID 未找到")
		}
	}

	// 提取主体类型
	subjectType := ""
	if t, ok := claims["type"].(string); ok {
		subjectType = t
	}

	// 提取主体角色
	roles := []string{}
	if r, ok := claims["roles"].([]string); ok {
		roles = r
	} else if r, ok := claims["roles"].([]interface{}); ok {
		for _, role := range r {
			if s, ok := role.(string); ok {
				roles = append(roles, s)
			}
		}
	}

	// 提取主体属性
	attributes := make(map[string]interface{})
	for k, v := range claims {
		if k != "sub" && k != "id" && k != "type" && k != "roles" {
			attributes[k] = v
		}
	}

	return &authz.Subject{
		ID:         subjectID,
		Type:       subjectType,
		Roles:      roles,
		Attributes: attributes,
	}, nil
}

// DefaultActionExtractor 默认操作提取器
func DefaultActionExtractor(ctx context.Context, tr transport.Transport) (*authz.Action, error) {
	if tr == nil {
		return nil, autherrors.NewInvalidActionError("传输未找到")
	}

	method := ""
	path := ""

	// 从 HTTP 或 gRPC 传输中提取操作
	if ht, ok := tr.(*http.Transport); ok {
		method = ht.Request().Method
		path = ht.Request().URL.Path
	} else {
		// 对于 gRPC，使用操作名称作为方法
		method = "INVOKE"
		path = tr.Operation()
	}

	// 将 HTTP 方法映射到操作名称
	actionName := method
	switch method {
	case "GET":
		actionName = "read"
	case "POST":
		actionName = "create"
	case "PUT":
		actionName = "update"
	case "PATCH":
		actionName = "patch"
	case "DELETE":
		actionName = "delete"
	case "INVOKE":
		// 对于 gRPC，从路径中提取操作名称
		parts := strings.Split(path, "/")
		if len(parts) > 0 {
			actionName = parts[len(parts)-1]
		}
	}

	return &authz.Action{
		Name: actionName,
		Attributes: map[string]interface{}{
			"method": method,
			"path":   path,
		},
	}, nil
}

// DefaultResourceExtractor 默认资源提取器
func DefaultResourceExtractor(ctx context.Context, tr transport.Transport, req interface{}) (*authz.Resource, error) {
	if tr == nil {
		return nil, autherrors.NewInvalidResourceError("传输未找到")
	}

	path := ""
	resourceType := "api"
	resourceID := ""

	// 从 HTTP 或 gRPC 传输中提取资源
	if ht, ok := tr.(*http.Transport); ok {
		path = ht.Request().URL.Path
		// 尝试从路径中提取资源 ID
		parts := strings.Split(path, "/")
		if len(parts) > 2 {
			resourceType = parts[1]
			if len(parts) > 3 && parts[2] != "" {
				resourceID = parts[2]
			}
		}
	} else {
		path = tr.Operation()
		// 尝试从操作名称中提取资源类型
		parts := strings.Split(path, "/")
		if len(parts) > 1 {
			resourceType = parts[1]
		}
	}

	return &authz.Resource{
		Type: resourceType,
		ID:   resourceID,
		Attributes: map[string]interface{}{
			"path": path,
		},
	}, nil
}

// AuthzMiddleware 创建身份鉴权中间件
func AuthzMiddleware(authorizer authz.Authorizer, opts ...*AuthzMiddlewareOptions) middleware.Middleware {
	options := DefaultAuthzMiddlewareOptions
	if authorizer == nil {
		panic("身份鉴权器不能为空")
	}
	options.Authorizer = authorizer

	// 应用选项
	if len(opts) > 0 && opts[0] != nil {
		opt := opts[0]
		if opt.SkipPaths != nil {
			options.SkipPaths = opt.SkipPaths
		}
		if opt.ClaimsContextKey != nil {
			options.ClaimsContextKey = opt.ClaimsContextKey
		}
		if opt.SubjectExtractor != nil {
			options.SubjectExtractor = opt.SubjectExtractor
		}
		if opt.ActionExtractor != nil {
			options.ActionExtractor = opt.ActionExtractor
		}
		if opt.ResourceExtractor != nil {
			options.ResourceExtractor = opt.ResourceExtractor
		}
		if opt.AuthorizeOptions != nil {
			options.AuthorizeOptions = opt.AuthorizeOptions
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

	return func(handler middleware.Handler) middleware.Handler {
		return func(ctx context.Context, req interface{}) (interface{}, error) {
			tr, ok := transport.FromServerContext(ctx)
			if !ok {
				return handler(ctx, req)
			}

			// 检查是否跳过身份鉴权
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

			// 从上下文中获取声明信息
			claims, ok := ClaimsFromContext(ctx, options.ClaimsContextKey)
			if !ok || claims == nil {
				logger.Warnf("声明信息未找到")
				return nil, autherrors.ErrUnauthorized
			}

			// 提取主体
			subject, err := options.SubjectExtractor(ctx, claims)
			if err != nil {
				logger.Errorf("提取主体失败: %v", err)
				return nil, autherrors.FromError(err)
			}

			// 提取操作
			action, err := options.ActionExtractor(ctx, tr)
			if err != nil {
				logger.Errorf("提取操作失败: %v", err)
				return nil, autherrors.FromError(err)
			}

			// 提取资源
			resource, err := options.ResourceExtractor(ctx, tr, req)
			if err != nil {
				logger.Errorf("提取资源失败: %v", err)
				return nil, autherrors.FromError(err)
			}

			// 进行鉴权
			result, err := options.Authorizer.Authorize(ctx, subject, action, resource, options.AuthorizeOptions)
			if err != nil {
				logger.Errorf("鉴权失败: %v", err)
				return nil, autherrors.FromError(err)
			}

			if !result.Allowed {
				logger.Warnf("鉴权拒绝: %s", result.Reason)
				return nil, autherrors.NewForbiddenError("鉴权拒绝: %s", result.Reason)
			}

			return handler(ctx, req)
		}
	}
}
