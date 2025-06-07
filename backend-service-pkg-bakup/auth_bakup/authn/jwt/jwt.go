package jwt

import (
	"context"
	"errors"

	"github.com/golang-jwt/jwt/v5"

	"backend-service/pkg/auth/authn"
)

var _ authn.Authenticator = (*Authenticator)(nil)

type Authenticator struct {
	options *Options
}

func NewAuthenticator(opts ...Option) (authn.Authenticator, error) {
	auth := &Authenticator{
		options: &Options{
			parseContextTokenFunc: authn.ParseContextTokenFun(authn.HeaderAuthorize, authn.BearerWord),
			tokenContextKey: map[string]interface{}{
				"sub": "sub",
				"exp": "sub",
				"iat": "sub",
				"nbf": "sub",
				"jti": "1",
				"iss": "test",
			},
		},
	}

	for _, o := range opts {
		o(auth.options)
	}

	if auth.options.signingMethod == nil {
		auth.options.signingMethod = jwt.SigningMethodHS256
	}

	return auth, nil
}

// Authenticate authenticates the token string and returns the claims.
func (a *Authenticator) Authenticate(ctx context.Context) (*authn.AuthClaims, error) {
	parseFun := a.options.parseContextTokenFunc
	if parseFun == nil {
		return nil, authn.ErrMissingKeyFunc
	}
	tokenString, err := parseFun(ctx)
	if err != nil {
		return nil, authn.ErrMissingBearerToken
	}
	return a.authenticateToken(tokenString)
}

// AuthenticateToken authenticates the token string and returns the claims.
func (a *Authenticator) authenticateToken(tokenString string) (*authn.AuthClaims, error) {
	jwtToken, err := a.parseToken(tokenString)

	if jwtToken == nil {
		return nil, authn.ErrInvalidToken
	}

	if err != nil {
		switch {
		case errors.Is(err, jwt.ErrTokenMalformed):
			return nil, authn.ErrInvalidToken
		case errors.Is(err, jwt.ErrTokenSignatureInvalid):
			return nil, authn.ErrSignTokenFailed
		case errors.Is(err, jwt.ErrTokenExpired) || errors.Is(err, jwt.ErrTokenNotValidYet):
			return nil, authn.ErrTokenExpired
		default:
			return nil, authn.ErrInvalidToken
		}
	}

	if !jwtToken.Valid {
		return nil, authn.ErrInvalidToken
	}
	if jwtToken.Method != a.options.signingMethod {
		return nil, authn.ErrUnsupportedSigningMethod
	}
	if jwtToken.Claims == nil {
		return nil, authn.ErrInvalidClaims
	}

	claims, ok := jwtToken.Claims.(jwt.MapClaims)
	if !ok {
		return nil, authn.ErrInvalidClaims
	}

	authClaim := authn.AuthClaims(claims)

	return &authClaim, nil
}

// CreateIdentity creates a signed token string from the claims.
func (a *Authenticator) CreateIdentity(authClaims authn.AuthClaims) (string, error) {
	claims, err := formatJwtMapClaims(authClaims)
	if err != nil {
		return "", err
	}
	jwtToken := jwt.NewWithClaims(
		a.options.signingMethod,
		&claims,
	)

	strToken, err := a.generateToken(jwtToken)
	if err != nil {
		return "", err
	}

	return strToken, nil
}

func (a *Authenticator) Close() {}

// parseToken parses the token string and returns the token.
func (a *Authenticator) parseToken(token string) (*jwt.Token, error) {
	if a.options.keyFunc == nil {
		return nil, authn.ErrMissingKeyFunc
	}

	return jwt.Parse(token, a.options.keyFunc)
}

// generateToken generates a signed token string from the token.
func (a *Authenticator) generateToken(jwtToken *jwt.Token) (string, error) {
	if a.options.keyFunc == nil {
		return "", authn.ErrMissingKeyFunc
	}

	key, err := a.options.keyFunc(jwtToken)
	if err != nil {
		return "", authn.ErrGetKeyFailed
	}

	strToken, err := jwtToken.SignedString(key)
	if err != nil {
		return "", authn.ErrSignTokenFailed
	}

	return strToken, nil
}

func formatJwtMapClaims(claims authn.AuthClaims) (jwt.MapClaims, error) {
	return jwt.MapClaims(claims), nil
}
