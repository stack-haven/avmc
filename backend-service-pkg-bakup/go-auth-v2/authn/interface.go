// Package authn 提供身份验证相关的接口和实现
package authn

import (
	"context"
	"time"
)

// TokenInfo 表示令牌信息
type TokenInfo struct {
	// Token 是令牌字符串
	Token string `json:"token"`
	// ExpiresAt 是令牌过期时间
	ExpiresAt time.Time `json:"expires_at"`
	// RefreshToken 是用于刷新令牌的字符串
	RefreshToken string `json:"refresh_token,omitempty"`
	// RefreshExpiresAt 是刷新令牌的过期时间
	RefreshExpiresAt time.Time `json:"refresh_expires_at,omitempty"`
	// Metadata 是令牌的元数据
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// Claims 表示令牌中的声明信息
type Claims map[string]interface{}

// Subject 表示身份主体
type Subject struct {
	// ID 是主体的唯一标识符
	ID string `json:"id"`
	// Name 是主体的名称
	Name string `json:"name,omitempty"`
	// Email 是主体的电子邮件
	Email string `json:"email,omitempty"`
	// Roles 是主体的角色列表
	Roles []string `json:"roles,omitempty"`
	// Metadata 是主体的元数据
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// AuthenticateOptions 表示身份验证选项
type AuthenticateOptions struct {
	// Credentials 是身份验证凭证
	Credentials map[string]interface{} `json:"credentials"`
	// Scope 是身份验证范围
	Scope []string `json:"scope,omitempty"`
	// ExpiresIn 是令牌有效期（秒）
	ExpiresIn int64 `json:"expires_in,omitempty"`
	// Metadata 是身份验证的元数据
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// VerifyOptions 表示令牌验证选项
type VerifyOptions struct {
	// SkipExpiration 是否跳过过期检查
	SkipExpiration bool `json:"skip_expiration,omitempty"`
	// RequiredClaims 是必须存在的声明
	RequiredClaims map[string]interface{} `json:"required_claims,omitempty"`
	// Metadata 是验证的元数据
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// Authenticator 定义身份验证接口
type Authenticator interface {
	// Init 初始化身份验证提供者
	// ctx 是上下文
	// config 是配置信息
	// 返回错误信息
	Init(ctx context.Context, config interface{}) error

	// Authenticate 进行身份验证
	// ctx 是上下文
	// subject 是身份主体
	// options 是身份验证选项
	// 返回令牌信息和错误信息
	Authenticate(ctx context.Context, subject *Subject, options *AuthenticateOptions) (*TokenInfo, error)

	// Verify 验证令牌
	// ctx 是上下文
	// token 是令牌字符串
	// options 是验证选项
	// 返回声明信息和错误信息
	Verify(ctx context.Context, token string, options *VerifyOptions) (Claims, error)

	// Issue 发放令牌
	// ctx 是上下文
	// claims 是声明信息
	// options 是身份验证选项
	// 返回令牌信息和错误信息
	Issue(ctx context.Context, claims Claims, options *AuthenticateOptions) (*TokenInfo, error)

	// Refresh 刷新令牌
	// ctx 是上下文
	// refreshToken 是刷新令牌字符串
	// options 是身份验证选项
	// 返回新的令牌信息和错误信息
	Refresh(ctx context.Context, refreshToken string, options *AuthenticateOptions) (*TokenInfo, error)

	// Revoke 注销令牌
	// ctx 是上下文
	// token 是令牌字符串
	// 返回错误信息
	Revoke(ctx context.Context, token string) error

	// Name 返回提供者名称
	// 返回提供者名称字符串
	Name() string

	// Close 关闭身份验证提供者
	// ctx 是上下文
	// 返回错误信息
	Close(ctx context.Context) error
}

// Provider 定义身份验证提供者接口，用于注册和获取身份验证提供者
type Provider interface {
	// Name 返回提供者名称
	// 返回提供者名称字符串
	Name() string

	// Create 创建身份验证提供者实例
	// ctx 是上下文
	// config 是配置信息
	// 返回身份验证提供者和错误信息
	Create(ctx context.Context, config interface{}) (Authenticator, error)
}