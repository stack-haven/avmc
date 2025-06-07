package authz

import (
	"context"
)

// 组合授权器和写入器接口
type Authorized interface {
	Authorizer
	Writer
}

// 定义授权方法接口
type Authorizer interface {
	// 检查主体在指定资源和操作下的授权项目
	ProjectsAuthorized(context.Context, Subjects, Action, Resource, Projects) (Projects, error)

	// 过滤主体授权的资源对
	FilterAuthorizedPairs(context.Context, Subjects, Pairs) (Pairs, error)

	// 过滤主体授权的项目列表
	FilterAuthorizedProjects(context.Context, Subjects) (Projects, error)

	// 检查主体是否有权限访问资源
	IsAuthorized(context.Context, Subject, Action, Resource, Project) (bool, error)
}

// 定义写入策略接口
type Writer interface {
	// 设置授权策略和角色映射
	SetPolicies(context.Context, PolicyMap, RoleMap) error
}
