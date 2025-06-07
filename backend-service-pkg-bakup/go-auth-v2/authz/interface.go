// Package authz 提供身份鉴权相关的接口和实现
package authz

import (
	"context"
)

// Resource 表示资源
type Resource struct {
	// Type 是资源类型
	Type string `json:"type"`
	// ID 是资源标识符
	ID string `json:"id"`
	// Attributes 是资源属性
	Attributes map[string]interface{} `json:"attributes,omitempty"`
}

// Action 表示操作
type Action struct {
	// Name 是操作名称
	Name string `json:"name"`
	// Attributes 是操作属性
	Attributes map[string]interface{} `json:"attributes,omitempty"`
}

// Subject 表示主体
type Subject struct {
	// ID 是主体标识符
	ID string `json:"id"`
	// Type 是主体类型
	Type string `json:"type,omitempty"`
	// Roles 是主体角色
	Roles []string `json:"roles,omitempty"`
	// Attributes 是主体属性
	Attributes map[string]interface{} `json:"attributes,omitempty"`
}

// Policy 表示策略
type Policy struct {
	// ID 是策略标识符
	ID string `json:"id"`
	// Subjects 是主体列表
	Subjects []string `json:"subjects"`
	// Resources 是资源列表
	Resources []string `json:"resources"`
	// Actions 是操作列表
	Actions []string `json:"actions"`
	// Effect 是策略效果（allow/deny）
	Effect string `json:"effect"`
	// Conditions 是策略条件
	Conditions map[string]interface{} `json:"conditions,omitempty"`
}

// AuthorizeOptions 表示鉴权选项
type AuthorizeOptions struct {
	// Context 是鉴权上下文
	Context map[string]interface{} `json:"context,omitempty"`
	// Metadata 是鉴权元数据
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// AuthorizeResult 表示鉴权结果
type AuthorizeResult struct {
	// Allowed 是否允许
	Allowed bool `json:"allowed"`
	// Reason 是原因
	Reason string `json:"reason,omitempty"`
	// Metadata 是结果元数据
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// Authorizer 定义身份鉴权接口
type Authorizer interface {
	// Init 初始化鉴权提供者
	// ctx 是上下文
	// config 是配置信息
	// 返回错误信息
	Init(ctx context.Context, config interface{}) error

	// Authorize 进行鉴权
	// ctx 是上下文
	// subject 是主体
	// action 是操作
	// resource 是资源
	// options 是鉴权选项
	// 返回鉴权结果和错误信息
	Authorize(ctx context.Context, subject *Subject, action *Action, resource *Resource, options *AuthorizeOptions) (*AuthorizeResult, error)

	// AddPolicy 添加策略
	// ctx 是上下文
	// policy 是策略
	// 返回错误信息
	AddPolicy(ctx context.Context, policy *Policy) error

	// RemovePolicy 移除策略
	// ctx 是上下文
	// policyID 是策略标识符
	// 返回错误信息
	RemovePolicy(ctx context.Context, policyID string) error

	// ListPolicies 列出策略
	// ctx 是上下文
	// filter 是过滤条件
	// 返回策略列表和错误信息
	ListPolicies(ctx context.Context, filter map[string]interface{}) ([]*Policy, error)

	// Name 返回提供者名称
	// 返回提供者名称字符串
	Name() string

	// Close 关闭鉴权提供者
	// ctx 是上下文
	// 返回错误信息
	Close(ctx context.Context) error
}

// Provider 定义鉴权提供者接口，用于注册和获取鉴权提供者
type Provider interface {
	// Name 返回提供者名称
	// 返回提供者名称字符串
	Name() string

	// Create 创建鉴权提供者实例
	// ctx 是上下文
	// config 是配置信息
	// 返回鉴权提供者和错误信息
	Create(ctx context.Context, config interface{}) (Authorizer, error)
}