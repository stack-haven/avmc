// Package goauth 提供身份认证模块的核心功能
package goauth

import (
	"github.com/go-kratos/kratos/v2/log"

	"backend-service/pkg/go-auth/authn/provider/jwt"
	"backend-service/pkg/go-auth/authz/provider/casbin"
)

// 初始化函数，注册默认提供者
func init() {
	// 创建日志记录器
	logger := log.GetLogger()

	// 注册默认的身份验证提供者
	RegisterAuthnProvider(jwt.NewJWTProvider(logger))

	// 注册默认的身份鉴权提供者
	RegisterAuthzProvider(casbin.NewCasbinProvider(logger))
}
