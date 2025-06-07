package jwt

import (
	"context"
	"errors"
	"time"

	"authsystem/auth"

	"github.com/golang-jwt/jwt/v5"
)

type JWTProvider struct {
	NameID   string
	Secret   []byte
	Issuer   string
	Duration time.Duration
}

func (j *JWTProvider) Name() string {
	return j.NameID
}

func (j *JWTProvider) Authenticate(ctx context.Context, req *auth.AuthRequest) (*auth.AuthClaims, error) {
	tokenStr := req.Token
	token, err := jwt.ParseWithClaims(tokenStr, &jwt.RegisteredClaims{}, func(token *jwt.Token) (interface{}, error) {
		return j.Secret, nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid token")
	}

	claims := token.Claims.(*jwt.RegisteredClaims)
	return &auth.AuthClaims{
		Subject:   claims.Subject,
		Issuer:    claims.Issuer,
		Audience:  claims.Audience,
		ExpiresAt: claims.ExpiresAt.Time.Unix(),
	}, nil
}

func (j *JWTProvider) IssueToken(ctx context.Context, req *auth.IssueRequest) (string, error) {
	claims := req.Claims
	jwtClaims := jwt.RegisteredClaims{
		Subject:   claims.Subject,
		Issuer:    j.Issuer,
		Audience:  claims.Audience,
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(j.Duration)),
		IssuedAt:  jwt.NewNumericDate(time.Now()),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwtClaims)
	return token.SignedString(j.Secret)
}
