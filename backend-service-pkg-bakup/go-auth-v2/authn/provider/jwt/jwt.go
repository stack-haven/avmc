// Package jwt 提供 JWT 身份验证提供者
package jwt

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/go-kratos/kratos/v2/log"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"backend-service/pkg/go-auth/authn"
	"backend-service/pkg/go-auth/config"
	autherrors "backend-service/pkg/go-auth/errors"
)

// JWTAuthenticator 实现 JWT 身份验证
type JWTAuthenticator struct {
	// 配置
	config *config.JWTConfig
	// 签名方法
	signMethod jwt.SigningMethod
	// 签名密钥
	signKey interface{}
	// 验证密钥
	verifyKey interface{}
	// 日志记录器
	logger *log.Helper
	// 令牌黑名单
	blacklist map[string]time.Time
}

// JWTProvider 实现 JWT 提供者
type JWTProvider struct {
	// 日志记录器
	logger *log.Helper
}

// NewJWTProvider 创建 JWT 提供者
func NewJWTProvider(logger log.Logger) *JWTProvider {
	if logger == nil {
		logger = log.GetLogger()
	}

	return &JWTProvider{
		logger: log.NewHelper(logger),
	}
}

// Name 返回提供者名称
func (p *JWTProvider) Name() string {
	return "jwt"
}

// Create 创建 JWT 身份验证器
func (p *JWTProvider) Create(ctx context.Context, config interface{}) (authn.Authenticator, error) {
	cfg, ok := config.(*config.JWTConfig)
	if !ok {
		return nil, fmt.Errorf("无效的 JWT 配置类型")
	}

	return NewJWTAuthenticator(cfg, log.NewHelper(log.GetLogger()))
}

// NewJWTAuthenticator 创建 JWT 身份验证器
func NewJWTAuthenticator(config *config.JWTConfig, logger *log.Helper) (*JWTAuthenticator, error) {
	if config == nil {
		return nil, errors.New("JWT 配置不能为空")
	}

	if logger == nil {
		logger = log.NewHelper(log.GetLogger())
	}

	// 创建 JWT 身份验证器
	auth := &JWTAuthenticator{
		config:    config,
		logger:    logger,
		blacklist: make(map[string]time.Time),
	}

	// 初始化签名方法和密钥
	if err := auth.initSigningMethod(); err != nil {
		return nil, err
	}

	return auth, nil
}

// 初始化签名方法和密钥
func (a *JWTAuthenticator) initSigningMethod() error {
	// 默认使用 HS256 算法
	algorithm := a.config.Algorithm
	if algorithm == "" {
		algorithm = "HS256"
	}

	switch algorithm {
	case "HS256", "HS384", "HS512":
		if a.config.Secret == "" {
			return errors.New("HMAC 算法需要提供密钥")
		}
		a.signMethod = jwt.GetSigningMethod(algorithm)
		a.signKey = []byte(a.config.Secret)
		a.verifyKey = []byte(a.config.Secret)

	case "RS256", "RS384", "RS512":
		if a.config.PrivateKey == "" || a.config.PublicKey == "" {
			return errors.New("RSA 算法需要提供公钥和私钥")
		}
		a.signMethod = jwt.GetSigningMethod(algorithm)

		// 解析私钥
		privateKey, err := jwt.ParseRSAPrivateKeyFromPEM([]byte(a.config.PrivateKey))
		if err != nil {
			return fmt.Errorf("解析 RSA 私钥失败: %v", err)
		}
		a.signKey = privateKey

		// 解析公钥
		publicKey, err := jwt.ParseRSAPublicKeyFromPEM([]byte(a.config.PublicKey))
		if err != nil {
			return fmt.Errorf("解析 RSA 公钥失败: %v", err)
		}
		a.verifyKey = publicKey

	case "ES256", "ES384", "ES512":
		// ECDSA 算法支持可以在需要时添加
		return errors.New("暂不支持 ECDSA 算法")

	default:
		return fmt.Errorf("不支持的算法: %s", algorithm)
	}

	return nil
}

// Init 初始化身份验证提供者
func (a *JWTAuthenticator) Init(ctx context.Context, config interface{}) error {
	cfg, ok := config.(*config.JWTConfig)
	if !ok {
		return fmt.Errorf("无效的 JWT 配置类型")
	}

	a.config = cfg
	return a.initSigningMethod()
}

// Authenticate 进行身份验证
func (a *JWTAuthenticator) Authenticate(ctx context.Context, subject *authn.Subject, options *authn.AuthenticateOptions) (*authn.TokenInfo, error) {
	if subject == nil {
		return nil, autherrors.ErrInvalidSubject
	}

	if subject.ID == "" {
		return nil, autherrors.NewInvalidSubjectError("主体 ID 不能为空")
	}

	// 创建声明
	claims := make(authn.Claims)
	claims["sub"] = subject.ID

	if subject.Name != "" {
		claims["name"] = subject.Name
	}

	if subject.Email != "" {
		claims["email"] = subject.Email
	}

	if len(subject.Roles) > 0 {
		claims["roles"] = subject.Roles
	}

	if subject.Metadata != nil {
		for k, v := range subject.Metadata {
			claims[k] = v
		}
	}

	// 添加选项中的凭证
	if options != nil && options.Credentials != nil {
		for k, v := range options.Credentials {
			if _, exists := claims[k]; !exists {
				claims[k] = v
			}
		}
	}

	// 发放令牌
	return a.Issue(ctx, claims, options)
}

// Verify 验证令牌
func (a *JWTAuthenticator) Verify(ctx context.Context, token string, options *authn.VerifyOptions) (authn.Claims, error) {
	if token == "" {
		return nil, autherrors.ErrInvalidToken
	}

	// 检查令牌是否在黑名单中
	if _, blacklisted := a.blacklist[token]; blacklisted {
		return nil, autherrors.NewInvalidTokenError("令牌已被注销")
	}

	// 解析令牌
	jwtToken, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
		// 验证签名方法
		if token.Method.Alg() != a.signMethod.Alg() {
			return nil, fmt.Errorf("意外的签名方法: %v", token.Header["alg"])
		}

		return a.verifyKey, nil
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, autherrors.ErrTokenExpired
		}
		return nil, autherrors.NewInvalidTokenError("令牌验证失败: %v", err)
	}

	if !jwtToken.Valid {
		return nil, autherrors.ErrInvalidToken
	}

	// 提取声明
	jwtClaims, ok := jwtToken.Claims.(jwt.MapClaims)
	if !ok {
		return nil, autherrors.NewInvalidClaimsError("无效的声明类型")
	}

	// 转换为 authn.Claims
	claims := make(authn.Claims)
	for k, v := range jwtClaims {
		claims[k] = v
	}

	// 验证必需的声明
	if options != nil && options.RequiredClaims != nil {
		for k, v := range options.RequiredClaims {
			claimValue, exists := claims[k]
			if !exists || claimValue != v {
				return nil, autherrors.NewInvalidClaimsError("缺少必需的声明: %s", k)
			}
		}
	}

	return claims, nil
}

// Issue 发放令牌
func (a *JWTAuthenticator) Issue(ctx context.Context, claims authn.Claims, options *authn.AuthenticateOptions) (*authn.TokenInfo, error) {
	if claims == nil {
		return nil, autherrors.ErrInvalidClaims
	}

	// 设置标准声明
	stdClaims := jwt.MapClaims{}
	for k, v := range claims {
		stdClaims[k] = v
	}

	// 设置 JWT ID
	stdClaims["jti"] = uuid.New().String()

	// 设置签发时间
	stdClaims["iat"] = time.Now().Unix()

	// 设置签发者
	if a.config.Issuer != "" {
		stdClaims["iss"] = a.config.Issuer
	}

	// 设置接收者
	if len(a.config.Audience) > 0 {
		stdClaims["aud"] = a.config.Audience
	}

	// 设置过期时间
	expiresIn := int64(3600) // 默认 1 小时
	if a.config.ExpiresIn > 0 {
		expiresIn = a.config.ExpiresIn
	}
	if options != nil && options.ExpiresIn > 0 {
		expiresIn = options.ExpiresIn
	}

	expiresAt := time.Now().Add(time.Duration(expiresIn) * time.Second)
	stdClaims["exp"] = expiresAt.Unix()

	// 创建令牌
	token := jwt.NewWithClaims(a.signMethod, stdClaims)

	// 签名令牌
	tokenString, err := token.SignedString(a.signKey)
	if err != nil {
		return nil, fmt.Errorf("签名令牌失败: %v", err)
	}

	// 创建刷新令牌
	refreshToken := ""
	refreshExpiresAt := time.Time{}

	if a.config.RefreshExpiresIn > 0 {
		refreshClaims := jwt.MapClaims{
			"jti":  uuid.New().String(),
			"sub":  stdClaims["sub"],
			"type": "refresh",
			"iat":  time.Now().Unix(),
		}

		if a.config.Issuer != "" {
			refreshClaims["iss"] = a.config.Issuer
		}

		refreshExpiresAt = time.Now().Add(time.Duration(a.config.RefreshExpiresIn) * time.Second)
		refreshClaims["exp"] = refreshExpiresAt.Unix()

		refreshJWT := jwt.NewWithClaims(a.signMethod, refreshClaims)
		refreshToken, err = refreshJWT.SignedString(a.signKey)
		if err != nil {
			a.logger.Warnf("创建刷新令牌失败: %v", err)
			// 继续，不返回错误，因为主令牌已经创建成功
		}
	}

	// 返回令牌信息
	return &authn.TokenInfo{
		Token:            tokenString,
		ExpiresAt:        expiresAt,
		RefreshToken:     refreshToken,
		RefreshExpiresAt: refreshExpiresAt,
		Metadata: map[string]interface{}{
			"jti": stdClaims["jti"],
		},
	}, nil
}

// Refresh 刷新令牌
func (a *JWTAuthenticator) Refresh(ctx context.Context, refreshToken string, options *authn.AuthenticateOptions) (*authn.TokenInfo, error) {
	if refreshToken == "" {
		return nil, autherrors.ErrInvalidToken
	}

	// 验证刷新令牌
	claims, err := a.Verify(ctx, refreshToken, &authn.VerifyOptions{
		RequiredClaims: map[string]interface{}{
			"type": "refresh",
		},
	})
	if err != nil {
		return nil, err
	}

	// 提取主体 ID
	subjectID, ok := claims["sub"].(string)
	if !ok || subjectID == "" {
		return nil, autherrors.NewInvalidSubjectError("主体 ID 未找到")
	}

	// 创建新的声明
	newClaims := make(authn.Claims)
	newClaims["sub"] = subjectID

	// 复制原始声明中的其他信息
	for k, v := range claims {
		if k != "jti" && k != "iat" && k != "exp" && k != "type" {
			newClaims[k] = v
		}
	}

	// 发放新令牌
	return a.Issue(ctx, newClaims, options)
}

// Revoke 注销令牌
func (a *JWTAuthenticator) Revoke(ctx context.Context, token string) error {
	if token == "" {
		return autherrors.ErrInvalidToken
	}

	// 验证令牌
	claims, err := a.Verify(ctx, token, nil)
	if err != nil {
		return err
	}

	// 获取过期时间
	var expiresAt time.Time
	if exp, ok := claims["exp"].(float64); ok {
		expiresAt = time.Unix(int64(exp), 0)
	} else {
		expiresAt = time.Now().Add(24 * time.Hour) // 默认 24 小时后过期
	}

	// 将令牌添加到黑名单
	a.blacklist[token] = expiresAt

	// 清理过期的黑名单条目
	a.cleanupBlacklist()

	return nil
}

// 清理过期的黑名单条目
func (a *JWTAuthenticator) cleanupBlacklist() {
	now := time.Now()
	for token, expiresAt := range a.blacklist {
		if now.After(expiresAt) {
			delete(a.blacklist, token)
		}
	}
}

// Name 返回提供者名称
func (a *JWTAuthenticator) Name() string {
	return "jwt"
}

// Close 关闭身份验证提供者
func (a *JWTAuthenticator) Close(ctx context.Context) error {
	// 清空黑名单
	a.blacklist = make(map[string]time.Time)
	return nil
}
