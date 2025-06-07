// Package casbin 提供 Casbin 身份鉴权提供者
package casbin

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/casbin/casbin/v2"
	"github.com/casbin/casbin/v2/model"
	"github.com/casbin/casbin/v2/persist"
	fileadapter "github.com/casbin/casbin/v2/persist/file-adapter"
	"github.com/go-kratos/kratos/v2/log"

	"backend-service/pkg/go-auth/authz"
	"backend-service/pkg/go-auth/config"
	autherrors "backend-service/pkg/go-auth/errors"
)

// CasbinAuthorizer 实现 Casbin 身份鉴权
type CasbinAuthorizer struct {
	// 配置
	config *config.CasbinConfig
	// Casbin 执行器
	enforcer *casbin.Enforcer
	// 日志记录器
	logger *log.Helper
}

// CasbinProvider 实现 Casbin 提供者
type CasbinProvider struct {
	// 日志记录器
	logger *log.Helper
}

// NewCasbinProvider 创建 Casbin 提供者
func NewCasbinProvider(logger log.Logger) *CasbinProvider {
	if logger == nil {
		logger = log.GetLogger()
	}

	return &CasbinProvider{
		logger: log.NewHelper(logger),
	}
}

// Name 返回提供者名称
func (p *CasbinProvider) Name() string {
	return "casbin"
}

// Create 创建 Casbin 身份鉴权器
func (p *CasbinProvider) Create(ctx context.Context, config interface{}) (authz.Authorizer, error) {
	cfg, ok := config.(*config.CasbinConfig)
	if !ok {
		return nil, fmt.Errorf("无效的 Casbin 配置类型")
	}

	return NewCasbinAuthorizer(cfg, log.NewHelper(log.GetLogger()))
}

// NewCasbinAuthorizer 创建 Casbin 身份鉴权器
func NewCasbinAuthorizer(config *config.CasbinConfig, logger *log.Helper) (*CasbinAuthorizer, error) {
	if config == nil {
		return nil, errors.New("Casbin 配置不能为空")
	}

	if logger == nil {
		logger = log.NewHelper(log.GetLogger())
	}

	// 创建 Casbin 身份鉴权器
	auth := &CasbinAuthorizer{
		config: config,
		logger: logger,
	}

	// 初始化 Casbin 执行器
	if err := auth.initEnforcer(); err != nil {
		return nil, err
	}

	return auth, nil
}

// 初始化 Casbin 执行器
func (a *CasbinAuthorizer) initEnforcer() error {
	if a.config.ModelPath == "" {
		return errors.New("模型路径不能为空")
	}

	// 加载模型
	m, err := model.NewModelFromFile(a.config.ModelPath)
	if err != nil {
		return fmt.Errorf("加载模型失败: %v", err)
	}

	// 创建适配器
	var adapter persist.Adapter
	if a.config.Adapter == "" || a.config.Adapter == "file" {
		// 使用文件适配器
		if a.config.PolicyPath == "" {
			return errors.New("策略路径不能为空")
		}
		adapter = fileadapter.NewAdapter(a.config.PolicyPath)
	} else {
		// 其他适配器可以在需要时添加
		return fmt.Errorf("不支持的适配器类型: %s", a.config.Adapter)
	}

	// 创建执行器
	enforcer, err := casbin.NewEnforcer(m, adapter)
	if err != nil {
		return fmt.Errorf("创建执行器失败: %v", err)
	}

	// 设置自动保存
	enforcer.EnableAutoSave(a.config.AutoSave)

	// 加载策略
	if a.config.AutoLoadPolicy {
		if err := enforcer.LoadPolicy(); err != nil {
			return fmt.Errorf("加载策略失败: %v", err)
		}
	}

	a.enforcer = enforcer
	return nil
}

// Init 初始化身份鉴权提供者
func (a *CasbinAuthorizer) Init(ctx context.Context, config interface{}) error {
	cfg, ok := config.(*config.CasbinConfig)
	if !ok {
		return fmt.Errorf("无效的 Casbin 配置类型")
	}

	a.config = cfg
	return a.initEnforcer()
}

// Authorize 进行鉴权
func (a *CasbinAuthorizer) Authorize(ctx context.Context, subject *authz.Subject, action *authz.Action, resource *authz.Resource, options *authz.AuthorizeOptions) (*authz.AuthorizeResult, error) {
	if subject == nil || subject.ID == "" {
		return nil, autherrors.ErrInvalidSubject
	}

	if action == nil || action.Name == "" {
		return nil, autherrors.ErrInvalidAction
	}

	if resource == nil || resource.Type == "" {
		return nil, autherrors.ErrInvalidResource
	}

	// 构建资源标识符
	resourceID := resource.Type
	if resource.ID != "" {
		resourceID = fmt.Sprintf("%s:%s", resource.Type, resource.ID)
	}

	// 检查主体是否有权限
	allowed, err := a.enforcer.Enforce(subject.ID, resourceID, action.Name)
	if err != nil {
		return nil, fmt.Errorf("执行鉴权失败: %v", err)
	}

	// 如果主体没有直接权限，检查角色权限
	if !allowed && len(subject.Roles) > 0 {
		for _, role := range subject.Roles {
			allowed, err = a.enforcer.Enforce(role, resourceID, action.Name)
			if err != nil {
				return nil, fmt.Errorf("执行角色鉴权失败: %v", err)
			}

			if allowed {
				break
			}
		}
	}

	// 返回鉴权结果
	result := &authz.AuthorizeResult{
		Allowed: allowed,
		Metadata: map[string]interface{}{
			"subject":  subject.ID,
			"action":   action.Name,
			"resource": resourceID,
		},
	}

	if !allowed {
		result.Reason = fmt.Sprintf("主体 %s 没有权限执行操作 %s 在资源 %s 上", subject.ID, action.Name, resourceID)
	}

	return result, nil
}

// AddPolicy 添加策略
func (a *CasbinAuthorizer) AddPolicy(ctx context.Context, policy *authz.Policy) error {
	if policy == nil {
		return autherrors.ErrInvalidPolicy
	}

	if len(policy.Subjects) == 0 || len(policy.Resources) == 0 || len(policy.Actions) == 0 {
		return autherrors.NewInvalidPolicyError("主体、资源和操作不能为空")
	}

	if policy.Effect != "allow" && policy.Effect != "deny" {
		return autherrors.NewInvalidPolicyError("效果必须是 allow 或 deny")
	}

	// 添加策略
	for _, subject := range policy.Subjects {
		for _, resource := range policy.Resources {
			for _, action := range policy.Actions {
				// 对于 deny 策略，需要检查模型是否支持
				if policy.Effect == "deny" {
					if !a.enforcer.GetModel().HasPolicy("p", "p", []string{subject, resource, action, "deny"}) {
						return autherrors.NewInvalidPolicyError("模型不支持 deny 效果")
					}
					_, err := a.enforcer.AddPolicy(subject, resource, action, "deny")
					if err != nil {
						return fmt.Errorf("添加 deny 策略失败: %v", err)
					}
				} else {
					_, err := a.enforcer.AddPolicy(subject, resource, action)
					if err != nil {
						return fmt.Errorf("添加策略失败: %v", err)
					}
				}
			}
		}
	}

	return nil
}

// RemovePolicy 移除策略
func (a *CasbinAuthorizer) RemovePolicy(ctx context.Context, policyID string) error {
	if policyID == "" {
		return autherrors.ErrInvalidPolicy
	}

	// 解析策略 ID
	parts := strings.Split(policyID, ":")
	if len(parts) < 3 {
		return autherrors.NewInvalidPolicyError("无效的策略 ID 格式，应为 subject:resource:action")
	}

	subject := parts[0]
	resource := parts[1]
	action := parts[2]

	// 移除策略
	removed, err := a.enforcer.RemovePolicy(subject, resource, action)
	if err != nil {
		return fmt.Errorf("移除策略失败: %v", err)
	}

	if !removed {
		return autherrors.NewPolicyNotFoundError("策略未找到: %s", policyID)
	}

	return nil
}

// ListPolicies 列出策略
func (a *CasbinAuthorizer) ListPolicies(ctx context.Context, filter map[string]interface{}) ([]*authz.Policy, error) {
	// 获取所有策略
	policies := a.enforcer.GetPolicy()

	// 过滤策略
	result := make([]*authz.Policy, 0)
	for _, p := range policies {
		if len(p) < 3 {
			continue
		}

		subject := p[0]
		resource := p[1]
		action := p[2]
		effect := "allow"

		// 检查是否有 deny 效果
		if len(p) > 3 && p[3] == "deny" {
			effect = "deny"
		}

		// 应用过滤器
		if filter != nil {
			if subjectFilter, ok := filter["subject"].(string); ok && subjectFilter != "" {
				if subjectFilter != subject {
					continue
				}
			}

			if resourceFilter, ok := filter["resource"].(string); ok && resourceFilter != "" {
				if resourceFilter != resource {
					continue
				}
			}

			if actionFilter, ok := filter["action"].(string); ok && actionFilter != "" {
				if actionFilter != action {
					continue
				}
			}

			if effectFilter, ok := filter["effect"].(string); ok && effectFilter != "" {
				if effectFilter != effect {
					continue
				}
			}
		}

		// 创建策略对象
		policy := &authz.Policy{
			ID:        fmt.Sprintf("%s:%s:%s", subject, resource, action),
			Subjects:  []string{subject},
			Resources: []string{resource},
			Actions:   []string{action},
			Effect:    effect,
		}

		result = append(result, policy)
	}

	return result, nil
}

// Name 返回提供者名称
func (a *CasbinAuthorizer) Name() string {
	return "casbin"
}

// Close 关闭身份鉴权提供者
func (a *CasbinAuthorizer) Close(ctx context.Context) error {
	// 保存策略
	if a.enforcer != nil && a.config.AutoSave {
		if err := a.enforcer.SavePolicy(); err != nil {
			return fmt.Errorf("保存策略失败: %v", err)
		}
	}

	return nil
}
