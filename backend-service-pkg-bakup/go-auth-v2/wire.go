//go:build wireinject
// +build wireinject

// Package goauth 提供身份认证模块的核心功能
package goauth

import (
	"context"

	"github.com/go-kratos/kratos/v2/log"
	"github.com/google/wire"

	"backend-service/pkg/go-auth/authn"
	"backend-service/pkg/go-auth/authn/provider/jwt"
	"backend-service/pkg/go-auth/authz"
	"backend-service/pkg/go-auth/authz/provider/casbin"
	"backend-service/pkg/go-auth/config"
)

// ProviderSet 提供者集合
var ProviderSet = wire.NewSet(
	NewAuth,
	ProvideAuthenticator,
	ProvideAuthorizer,
	ProvideJWTProvider,
	ProvideCasbinProvider,
)

// ProvideJWTProvider 提供 JWT 提供者
func ProvideJWTProvider(logger log.Logger) authn.Provider {
	return jwt.NewJWTProvider(logger)
}

// ProvideCasbinProvider 提供 Casbin 提供者
func ProvideCasbinProvider(logger log.Logger) authz.Provider {
	return casbin.NewCasbinProvider(logger)
}

// ProvideAuthenticator 提供身份验证器
func ProvideAuthenticator(ctx context.Context, cfg *config.Config, logger log.Logger) (authn.Authenticator, func(), error) {
	if cfg.Authn == nil || cfg.Authn.Default == "" {
		return nil, func() {}, nil
	}

	// 获取提供者配置
	providerCfg, ok := cfg.Authn.Providers[cfg.Authn.Default]
	if !ok {
		return nil, func() {}, nil
	}

	// 创建身份验证器
	authenticator, err := CreateAuthenticator(ctx, cfg.Authn.Default, providerCfg)
	if err != nil {
		return nil, func() {}, err
	}

	// 清理函数
	cleanup := func() {
		if authenticator != nil {
			_ = authenticator.Close(ctx)
		}
	}

	return authenticator, cleanup, nil
}

// ProvideAuthorizer 提供身份鉴权器
func ProvideAuthorizer(ctx context.Context, cfg *config.Config, logger log.Logger) (authz.Authorizer, func(), error) {
	if cfg.Authz == nil || cfg.Authz.Default == "" {
		return nil, func() {}, nil
	}

	// 获取提供者配置
	providerCfg, ok := cfg.Authz.Providers[cfg.Authz.Default]
	if !ok {
		return nil, func() {}, nil
	}

	// 创建身份鉴权器
	authorizer, err := CreateAuthorizer(ctx, cfg.Authz.Default, providerCfg)
	if err != nil {
		return nil, func() {}, err
	}

	// 清理函数
	cleanup := func() {
		if authorizer != nil {
			_ = authorizer.Close(ctx)
		}
	}

	return authorizer, cleanup, nil
}

// InitAuth 初始化身份认证服务
func InitAuth(ctx context.Context, cfg *config.Config, logger log.Logger) (*Auth, func(), error) {
	panic(wire.Build(ProviderSet))
}
