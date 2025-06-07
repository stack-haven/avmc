// Package errors 提供身份认证模块的错误定义
package errors

import (
	"fmt"
	"net/http"

	"github.com/go-kratos/kratos/v2/errors"
)

// 错误码定义
// 身份认证错误码范围：100001-100099
// 身份鉴权错误码范围：100101-100199
const (
	// ErrReasonUnauthorized 未授权
	ErrReasonUnauthorized = "UNAUTHORIZED"
	// ErrReasonForbidden 禁止访问
	ErrReasonForbidden = "FORBIDDEN"
	// ErrReasonInvalidToken 无效令牌
	ErrReasonInvalidToken = "INVALID_TOKEN"
	// ErrReasonTokenExpired 令牌过期
	ErrReasonTokenExpired = "TOKEN_EXPIRED"
	// ErrReasonInvalidCredentials 无效凭证
	ErrReasonInvalidCredentials = "INVALID_CREDENTIALS"
	// ErrReasonInvalidSubject 无效主体
	ErrReasonInvalidSubject = "INVALID_SUBJECT"
	// ErrReasonInvalidClaims 无效声明
	ErrReasonInvalidClaims = "INVALID_CLAIMS"
	// ErrReasonProviderNotFound 提供者未找到
	ErrReasonProviderNotFound = "PROVIDER_NOT_FOUND"
	// ErrReasonProviderError 提供者错误
	ErrReasonProviderError = "PROVIDER_ERROR"
	// ErrReasonInvalidPolicy 无效策略
	ErrReasonInvalidPolicy = "INVALID_POLICY"
	// ErrReasonPolicyNotFound 策略未找到
	ErrReasonPolicyNotFound = "POLICY_NOT_FOUND"
	// ErrReasonInvalidResource 无效资源
	ErrReasonInvalidResource = "INVALID_RESOURCE"
	// ErrReasonInvalidAction 无效操作
	ErrReasonInvalidAction = "INVALID_ACTION"
	// ErrReasonInternalError 内部错误
	ErrReasonInternalError = "INTERNAL_ERROR"
)

// 错误码定义
var (
	// ErrUnauthorized 未授权错误
	ErrUnauthorized = errors.New(http.StatusUnauthorized, ErrReasonUnauthorized, "未授权")
	// ErrForbidden 禁止访问错误
	ErrForbidden = errors.New(http.StatusForbidden, ErrReasonForbidden, "禁止访问")
	// ErrInvalidToken 无效令牌错误
	ErrInvalidToken = errors.New(http.StatusUnauthorized, ErrReasonInvalidToken, "无效令牌")
	// ErrTokenExpired 令牌过期错误
	ErrTokenExpired = errors.New(http.StatusUnauthorized, ErrReasonTokenExpired, "令牌已过期")
	// ErrInvalidCredentials 无效凭证错误
	ErrInvalidCredentials = errors.New(http.StatusUnauthorized, ErrReasonInvalidCredentials, "无效凭证")
	// ErrInvalidSubject 无效主体错误
	ErrInvalidSubject = errors.New(http.StatusBadRequest, ErrReasonInvalidSubject, "无效主体")
	// ErrInvalidClaims 无效声明错误
	ErrInvalidClaims = errors.New(http.StatusBadRequest, ErrReasonInvalidClaims, "无效声明")
	// ErrProviderNotFound 提供者未找到错误
	ErrProviderNotFound = errors.New(http.StatusInternalServerError, ErrReasonProviderNotFound, "提供者未找到")
	// ErrProviderError 提供者错误
	ErrProviderError = errors.New(http.StatusInternalServerError, ErrReasonProviderError, "提供者错误")
	// ErrInvalidPolicy 无效策略错误
	ErrInvalidPolicy = errors.New(http.StatusBadRequest, ErrReasonInvalidPolicy, "无效策略")
	// ErrPolicyNotFound 策略未找到错误
	ErrPolicyNotFound = errors.New(http.StatusNotFound, ErrReasonPolicyNotFound, "策略未找到")
	// ErrInvalidResource 无效资源错误
	ErrInvalidResource = errors.New(http.StatusBadRequest, ErrReasonInvalidResource, "无效资源")
	// ErrInvalidAction 无效操作错误
	ErrInvalidAction = errors.New(http.StatusBadRequest, ErrReasonInvalidAction, "无效操作")
	// ErrInternalError 内部错误
	ErrInternalError = errors.New(http.StatusInternalServerError, ErrReasonInternalError, "内部错误")
)

// NewUnauthorizedError 创建未授权错误
func NewUnauthorizedError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrUnauthorized).WithMessage(fmt.Sprintf(format, args...))
}

// NewForbiddenError 创建禁止访问错误
func NewForbiddenError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrForbidden).WithMessage(fmt.Sprintf(format, args...))
}

// NewInvalidTokenError 创建无效令牌错误
func NewInvalidTokenError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInvalidToken).WithMessage(fmt.Sprintf(format, args...))
}

// NewTokenExpiredError 创建令牌过期错误
func NewTokenExpiredError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrTokenExpired).WithMessage(fmt.Sprintf(format, args...))
}

// NewInvalidCredentialsError 创建无效凭证错误
func NewInvalidCredentialsError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInvalidCredentials).WithMessage(fmt.Sprintf(format, args...))
}

// NewInvalidSubjectError 创建无效主体错误
func NewInvalidSubjectError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInvalidSubject).WithMessage(fmt.Sprintf(format, args...))
}

// NewInvalidClaimsError 创建无效声明错误
func NewInvalidClaimsError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInvalidClaims).WithMessage(fmt.Sprintf(format, args...))
}

// NewProviderNotFoundError 创建提供者未找到错误
func NewProviderNotFoundError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrProviderNotFound).WithMessage(fmt.Sprintf(format, args...))
}

// NewProviderError 创建提供者错误
func NewProviderError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrProviderError).WithMessage(fmt.Sprintf(format, args...))
}

// NewInvalidPolicyError 创建无效策略错误
func NewInvalidPolicyError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInvalidPolicy).WithMessage(fmt.Sprintf(format, args...))
}

// NewPolicyNotFoundError 创建策略未找到错误
func NewPolicyNotFoundError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrPolicyNotFound).WithMessage(fmt.Sprintf(format, args...))
}

// NewInvalidResourceError 创建无效资源错误
func NewInvalidResourceError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInvalidResource).WithMessage(fmt.Sprintf(format, args...))
}

// NewInvalidActionError 创建无效操作错误
func NewInvalidActionError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInvalidAction).WithMessage(fmt.Sprintf(format, args...))
}

// NewInternalError 创建内部错误
func NewInternalError(format string, args ...interface{}) *errors.Error {
	return errors.Clone(ErrInternalError).WithMessage(fmt.Sprintf(format, args...))
}

// FromError 从错误中提取 errors.Error
func FromError(err error) *errors.Error {
	if err == nil {
		return nil
	}
	e, ok := err.(*errors.Error)
	if ok {
		return e
	}
	return ErrInternalError
}