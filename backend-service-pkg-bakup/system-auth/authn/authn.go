package auth

import "context"

type Authenticator interface {
	Name() string
	Authenticate(ctx context.Context, req *AuthRequest) (*AuthClaims, error)
	IssueToken(ctx context.Context, req *IssueRequest) (string, error)
}

type AuthRequest struct {
	Token       string
	Headers     map[string]string
	QueryParams map[string]string
	Meta        map[string]string
	RawContext  context.Context
}

type IssueRequest struct {
	Claims *AuthClaims
	Meta   map[string]string
}

type AuthClaims struct {
	Subject   string
	Issuer    string
	Audience  []string
	ExpiresAt int64
	Scopes    []string
	Roles     []string
	Extra     map[string]any
}
