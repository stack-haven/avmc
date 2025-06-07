// Package config 提供身份认证模块的配置定义
package config

// Config 表示身份认证模块的配置
type Config struct {
	// Authn 是身份验证配置
	Authn *AuthnConfig `json:"authn"`
	// Authz 是身份鉴权配置
	Authz *AuthzConfig `json:"authz"`
}

// AuthnConfig 表示身份验证配置
type AuthnConfig struct {
	// Default 是默认身份验证提供者名称
	Default string `json:"default"`
	// Providers 是身份验证提供者配置映射
	Providers map[string]interface{} `json:"providers"`
}

// AuthzConfig 表示身份鉴权配置
type AuthzConfig struct {
	// Default 是默认身份鉴权提供者名称
	Default string `json:"default"`
	// Providers 是身份鉴权提供者配置映射
	Providers map[string]interface{} `json:"providers"`
}

// JWTConfig 表示 JWT 提供者配置
type JWTConfig struct {
	// Secret 是 JWT 密钥
	Secret string `json:"secret"`
	// PublicKey 是 JWT 公钥（用于 RS256/ES256 等算法）
	PublicKey string `json:"public_key,omitempty"`
	// PrivateKey 是 JWT 私钥（用于 RS256/ES256 等算法）
	PrivateKey string `json:"private_key,omitempty"`
	// Algorithm 是 JWT 算法（如 HS256、RS256、ES256 等）
	Algorithm string `json:"algorithm,omitempty"`
	// Issuer 是 JWT 签发者
	Issuer string `json:"issuer,omitempty"`
	// Audience 是 JWT 接收者
	Audience []string `json:"audience,omitempty"`
	// ExpiresIn 是 JWT 有效期（秒）
	ExpiresIn int64 `json:"expires_in,omitempty"`
	// RefreshExpiresIn 是刷新令牌有效期（秒）
	RefreshExpiresIn int64 `json:"refresh_expires_in,omitempty"`
	// TokenLookup 是令牌查找位置（如 header:Authorization、query:token、cookie:jwt 等）
	TokenLookup string `json:"token_lookup,omitempty"`
	// TokenHeadName 是令牌头名称（如 Bearer）
	TokenHeadName string `json:"token_head_name,omitempty"`
	// ClaimsKey 是声明键名
	ClaimsKey string `json:"claims_key,omitempty"`
	// SubjectKey 是主体键名
	SubjectKey string `json:"subject_key,omitempty"`
	// RolesKey 是角色键名
	RolesKey string `json:"roles_key,omitempty"`
}

// CasbinConfig 表示 Casbin 提供者配置
type CasbinConfig struct {
	// ModelPath 是模型文件路径
	ModelPath string `json:"model_path"`
	// PolicyPath 是策略文件路径
	PolicyPath string `json:"policy_path,omitempty"`
	// Adapter 是适配器类型（如 file、mysql、redis 等）
	Adapter string `json:"adapter,omitempty"`
	// AdapterConfig 是适配器配置
	AdapterConfig map[string]interface{} `json:"adapter_config,omitempty"`
	// AutoSave 是否自动保存策略
	AutoSave bool `json:"auto_save,omitempty"`
	// AutoLoadPolicy 是否自动加载策略
	AutoLoadPolicy bool `json:"auto_load_policy,omitempty"`
	// SubjectKey 是主体键名
	SubjectKey string `json:"subject_key,omitempty"`
	// RolesKey 是角色键名
	RolesKey string `json:"roles_key,omitempty"`
}

// OIDCConfig 表示 OIDC 提供者配置
type OIDCConfig struct {
	// ClientID 是客户端 ID
	ClientID string `json:"client_id"`
	// ClientSecret 是客户端密钥
	ClientSecret string `json:"client_secret"`
	// Issuer 是签发者 URL
	Issuer string `json:"issuer"`
	// RedirectURL 是重定向 URL
	RedirectURL string `json:"redirect_url"`
	// Scopes 是请求范围
	Scopes []string `json:"scopes,omitempty"`
	// TokenLookup 是令牌查找位置
	TokenLookup string `json:"token_lookup,omitempty"`
	// TokenHeadName 是令牌头名称
	TokenHeadName string `json:"token_head_name,omitempty"`
	// ClaimsKey 是声明键名
	ClaimsKey string `json:"claims_key,omitempty"`
	// SubjectKey 是主体键名
	SubjectKey string `json:"subject_key,omitempty"`
	// RolesKey 是角色键名
	RolesKey string `json:"roles_key,omitempty"`
}

// OPAConfig 表示 OPA 提供者配置
type OPAConfig struct {
	// URL 是 OPA 服务 URL
	URL string `json:"url"`
	// PolicyPath 是策略路径
	PolicyPath string `json:"policy_path"`
	// DataPath 是数据路径
	DataPath string `json:"data_path,omitempty"`
	// LocalBundle 是本地包路径
	LocalBundle string `json:"local_bundle,omitempty"`
	// AuthorizationQuery 是授权查询
	AuthorizationQuery string `json:"authorization_query,omitempty"`
	// SubjectKey 是主体键名
	SubjectKey string `json:"subject_key,omitempty"`
	// RolesKey 是角色键名
	RolesKey string `json:"roles_key,omitempty"`
}