package jwt

import (
	"context"

	jwt "github.com/golang-jwt/jwt/v5"
)

type ParseContextToken func(context.Context) (string, error)

type TokenContextKey map[string]interface{}

type Options struct {
	signingMethod         jwt.SigningMethod
	keyFunc               jwt.Keyfunc
	parseContextTokenFunc ParseContextToken
	tokenContextKey       TokenContextKey
}

type Option func(d *Options)

// WithSigningMethod set signing method
func WithSigningMethod(alg string) Option {
	return func(o *Options) {
		o.signingMethod = jwt.GetSigningMethod(alg)
	}
}

// WithKey set key
func WithKey(key []byte) Option {
	return func(o *Options) {
		o.keyFunc = func(token *jwt.Token) (interface{}, error) {
			return key, nil
		}
	}
}

func WithParseContext(p ParseContextToken) Option {
	return func(a *Options) {
		a.parseContextTokenFunc = p
	}
}

func WithtokenContextKey(k map[string]interface{}) Option {
	return func(a *Options) {
		a.tokenContextKey = k
	}
}
