package auth

import (
	"context"
	"net/http"
)

type contextKey string

const claimsKey = contextKey("auth.claims")

func GetClaims(ctx context.Context) (*AuthClaims, bool) {
	val, ok := ctx.Value(claimsKey).(*AuthClaims)
	return val, ok
}

func AuthMiddleware(provider Authenticator) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := r.Header.Get("Authorization")
			if token == "" {
				http.Error(w, "missing token", http.StatusUnauthorized)
				return
			}

			claims, err := provider.Authenticate(r.Context(), &AuthRequest{
				Token:       token,
				Headers:     map[string]string{},
				QueryParams: map[string]string{},
				Meta:        map[string]string{},
				RawContext:  r.Context(),
			})
			if err != nil {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), claimsKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
