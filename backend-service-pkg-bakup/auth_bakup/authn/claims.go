package authn

import (
	"context"
	"strings"

	"github.com/go-kratos/kratos/v2/transport"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type ctxKey string
type ContextType int

const (
	HeaderAuthorize = "Authorization"
	BearerWord      = "Bearer"
)

const (
	ContextTypeGrpc ContextType = iota
	ContextTypeKratosMetaData
)

var (
	authClaimsContextKey = ctxKey("authn-claims")
)

func ParseContextTokenFun(headerKey string, scheme string) func(context.Context) (string, error) {
	return func(ctx context.Context) (string, error) {
		if header, ok := transport.FromServerContext(ctx); ok {
			tokenStr := header.RequestHeader().Get(headerKey)
			if tokenStr == "" {
				return "", status.Errorf(codes.Unauthenticated, "Request unauthenticated with "+scheme)
			}
			splits := strings.SplitN(tokenStr, " ", 2)
			if len(splits) < 2 {
				return "", status.Errorf(codes.Unauthenticated, "Bad authorization string")
			}

			if !strings.EqualFold(splits[0], scheme) {
				return "", status.Errorf(codes.Unauthenticated, "Request unauthenticated with "+scheme)
			}
			return splits[1], nil
		}
		return "", nil
	}
}

type AuthClaims map[string]interface{}

// ContextWithAuthClaims injects the provided AuthClaims into the parent context.
func ContextWithAuthClaims(parent context.Context, claims *AuthClaims) context.Context {
	return context.WithValue(parent, authClaimsContextKey, claims)
}

// AuthClaimsFromContext extracts the AuthClaims from the provided ctx (if any).
func AuthClaimsFromContext(ctx context.Context) (*AuthClaims, bool) {
	claims, ok := ctx.Value(authClaimsContextKey).(*AuthClaims)
	if !ok {
		return nil, false
	}

	return claims, true
}

func (a *AuthClaims) GetSubject() string {
	return ""
}
