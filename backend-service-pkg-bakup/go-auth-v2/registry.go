// Package goauth 提供身份认证模块的核心功能
package goauth

import (
	"context"
	"fmt"
	"sync"

	"github.com/go-kratos/kratos/v2/log"

	"backend-service/pkg/go-auth/authn"
	"backend-service/pkg/go-auth/authz"
	"backend-service/pkg/go-auth/config"
	"backend-service/pkg/go-auth/errors"
)

var (
	// 全局提供者注册表
	globalRegistry = NewRegistry()

	// 默认日志记录器
	defaultLogger = log.NewHelper(log.GetLogger())
)

// Registry 提供者注册表
type Registry struct {
	// 身份验证提供者映射
	authnProviders map[string]authn.Provider
	// 身份鉴权提供者映射
	authzProviders map[string]authz.Provider
	// 互斥锁
	mutex sync.RWMutex
}

// NewRegistry 创建新的提供者注册表
func NewRegistry() *Registry {
	return &Registry{
		authnProviders: make(map[string]authn.Provider),
		authzProviders: make(map[string]authz.Provider),
		mutex:          sync.RWMutex{},
	}
}

// RegisterAuthnProvider 注册身份验证提供者
func (r *Registry) RegisterAuthnProvider(provider authn.Provider) {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	name := provider.Name()
	if _, exists := r.authnProviders[name]; exists {
		defaultLogger.Warnf("身份验证提供者 %s 已存在，将被覆盖", name)
	}

	r.authnProviders[name] = provider
	defaultLogger.Infof("身份验证提供者 %s 已注册", name)
}

// RegisterAuthzProvider 注册身份鉴权提供者
func (r *Registry) RegisterAuthzProvider(provider authz.Provider) {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	name := provider.Name()
	if _, exists := r.authzProviders[name]; exists {
		defaultLogger.Warnf("身份鉴权提供者 %s 已存在，将被覆盖", name)
	}

	r.authzProviders[name] = provider
	defaultLogger.Infof("身份鉴权提供者 %s 已注册", name)
}

// GetAuthnProvider 获取身份验证提供者
func (r *Registry) GetAuthnProvider(name string) (authn.Provider, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	provider, exists := r.authnProviders[name]
	if !exists {
		return nil, errors.NewProviderNotFoundError("身份验证提供者 %s 未找到", name)
	}

	return provider, nil
}

// GetAuthzProvider 获取身份鉴权提供者
func (r *Registry) GetAuthzProvider(name string) (authz.Provider, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	provider, exists := r.authzProviders[name]
	if !exists {
		return nil, errors.NewProviderNotFoundError("身份鉴权提供者 %s 未找到", name)
	}

	return provider, nil
}

// ListAuthnProviders 列出所有身份验证提供者
func (r *Registry) ListAuthnProviders() []string {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	providers := make([]string, 0, len(r.authnProviders))
	for name := range r.authnProviders {
		providers = append(providers, name)
	}

	return providers
}

// ListAuthzProviders 列出所有身份鉴权提供者
func (r *Registry) ListAuthzProviders() []string {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	providers := make([]string, 0, len(r.authzProviders))
	for name := range r.authzProviders {
		providers = append(providers, name)
	}

	return providers
}

// CreateAuthenticator 创建身份验证器
func (r *Registry) CreateAuthenticator(ctx context.Context, name string, cfg interface{}) (authn.Authenticator, error) {
	provider, err := r.GetAuthnProvider(name)
	if err != nil {
		return nil, err
	}

	authenticator, err := provider.Create(ctx, cfg)
	if err != nil {
		return nil, errors.NewProviderError("创建身份验证器失败: %v", err)
	}

	return authenticator, nil
}

// CreateAuthorizer 创建身份鉴权器
func (r *Registry) CreateAuthorizer(ctx context.Context, name string, cfg interface{}) (authz.Authorizer, error) {
	provider, err := r.GetAuthzProvider(name)
	if err != nil {
		return nil, err
	}

	authorizer, err := provider.Create(ctx, cfg)
	if err != nil {
		return nil, errors.NewProviderError("创建身份鉴权器失败: %v", err)
	}

	return authorizer, nil
}

// RegisterAuthnProvider 注册身份验证提供者到全局注册表
func RegisterAuthnProvider(provider authn.Provider) {
	globalRegistry.RegisterAuthnProvider(provider)
}

// RegisterAuthzProvider 注册身份鉴权提供者到全局注册表
func RegisterAuthzProvider(provider authz.Provider) {
	globalRegistry.RegisterAuthzProvider(provider)
}

// GetAuthnProvider 从全局注册表获取身份验证提供者
func GetAuthnProvider(name string) (authn.Provider, error) {
	return globalRegistry.GetAuthnProvider(name)
}

// GetAuthzProvider 从全局注册表获取身份鉴权提供者
func GetAuthzProvider(name string) (authz.Provider, error) {
	return globalRegistry.GetAuthzProvider(name)
}

// ListAuthnProviders 从全局注册表列出所有身份验证提供者
func ListAuthnProviders() []string {
	return globalRegistry.ListAuthnProviders()
}

// ListAuthzProviders 从全局注册表列出所有身份鉴权提供者
func ListAuthzProviders() []string {
	return globalRegistry.ListAuthzProviders()
}

// CreateAuthenticator 从全局注册表创建身份验证器
func CreateAuthenticator(ctx context.Context, name string, cfg interface{}) (authn.Authenticator, error) {
	return globalRegistry.CreateAuthenticator(ctx, name, cfg)
}

// CreateAuthorizer 从全局注册表创建身份鉴权器
func CreateAuthorizer(ctx context.Context, name string, cfg interface{}) (authz.Authorizer, error) {
	return globalRegistry.CreateAuthorizer(ctx, name, cfg)
}

// Auth 身份认证服务
type Auth struct {
	// 身份验证器
	Authenticator authn.Authenticator
	// 身份鉴权器
	Authorizer authz.Authorizer
	// 日志记录器
	logger *log.Helper
}

// NewAuth 创建身份认证服务
func NewAuth(authenticator authn.Authenticator, authorizer authz.Authorizer, logger log.Logger) *Auth {
	if logger == nil {
		logger = log.GetLogger()
	}

	return &Auth{
		Authenticator: authenticator,
		Authorizer:    authorizer,
		logger:        log.NewHelper(logger),
	}
}

// NewAuthFromConfig 从配置创建身份认证服务
func NewAuthFromConfig(ctx context.Context, cfg *config.Config, logger log.Logger) (*Auth, error) {
	if cfg == nil {
		return nil, fmt.Errorf("配置不能为空")
	}

	if cfg.Authn == nil || cfg.Authn.Default == "" {
		return nil, fmt.Errorf("身份验证配置不能为空")
	}

	if cfg.Authz == nil || cfg.Authz.Default == "" {
		return nil, fmt.Errorf("身份鉴权配置不能为空")
	}

	// 创建身份验证器
	authnCfg, ok := cfg.Authn.Providers[cfg.Authn.Default]
	if !ok {
		return nil, fmt.Errorf("身份验证提供者 %s 的配置未找到", cfg.Authn.Default)
	}

	authenticator, err := CreateAuthenticator(ctx, cfg.Authn.Default, authnCfg)
	if err != nil {
		return nil, fmt.Errorf("创建身份验证器失败: %v", err)
	}

	// 创建身份鉴权器
	authzCfg, ok := cfg.Authz.Providers[cfg.Authz.Default]
	if !ok {
		return nil, fmt.Errorf("身份鉴权提供者 %s 的配置未找到", cfg.Authz.Default)
	}

	authorizer, err := CreateAuthorizer(ctx, cfg.Authz.Default, authzCfg)
	if err != nil {
		return nil, fmt.Errorf("创建身份鉴权器失败: %v", err)
	}

	return NewAuth(authenticator, authorizer, logger), nil
}
