package jwt

import (
	"backend-service/pkg/auth/authn"
	"encoding/json"
	"math"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	ClaimFieldIssuer         = "iss" // 代表 JWT 的签发者。它是一个字符串或者 URL，用于标识是哪个实体（如服务器、服务提供商等）签发了这个 JWT。
	ClaimFieldSubject        = "sub" // 代表 JWT 的主题。通常是一个唯一标识符，用于标识 JWT 所涉及的主体，这个主体通常是用户，但也可以是其他实体，如设备等。
	ClaimFieldAudience       = "aud" // 代表 JWT 的受众。它指定了 JWT 的接收方，是一个或多个字符串或者 URL。
	ClaimFieldExpirationTime = "exp" // 代表 JWT 的过期时间。它是一个数字，表示从 1970 年 1 月 1 日 00:00:00 UTC 开始到过期时间的秒数。
	ClaimFieldNotBefore      = "nbf" // 代表 JWT 的生效时间。和exp类似，它是一个数字，表示从 1970 年 1 月 1 日 00:00:00 UTC 开始到生效时间的秒数。
	ClaimFieldIssuedAt       = "iat" // 代表 JWT 的签发时间。也是一个数字，表示从 1970 年 1 月 1 日 00:00:00 UTC 开始到签发时间的秒数。
	ClaimFieldJwtID          = "jti" // 代表 JWT 的唯一标识符。是一个字符串，用于唯一标识一个 JWT。

	ClaimFieldScope = "scope" // 代表 JWT 的权限范围。它是一个字符串或者字符串数组，用于标识 JWT 的权限范围。在一个 API 访问场景中，scope的值可能是["read:users", "write:posts"]。这意味着拥有此 JWT 的用户被授权读取用户信息和写入文章相关内容。通过这种方式，scope清晰地界定了用户凭借该令牌可以进行的操作范围。
)

var _ jwt.Claims = (*Claims)(nil)

type Claims map[string]interface{}

func (c *Claims) GetJwtID() (string, error) {
	return c.parseString(ClaimFieldJwtID)
}

// GetExpirationTime implements the Claims interface.
func (c *Claims) GetExpirationTime() (*jwt.NumericDate, error) {
	return c.parseNumericDate(ClaimFieldExpirationTime)
}

// GetNotBefore implements the Claims interface.
func (c *Claims) GetNotBefore() (*jwt.NumericDate, error) {
	return c.parseNumericDate(ClaimFieldNotBefore)
}

// GetIssuedAt implements the Claims interface.
func (c *Claims) GetIssuedAt() (*jwt.NumericDate, error) {
	return c.parseNumericDate(ClaimFieldIssuedAt)
}

// GetAudience implements the Claims interface.
func (c *Claims) GetAudience() (jwt.ClaimStrings, error) {
	return c.parseClaimsString(ClaimFieldAudience)
}

// GetIssuer implements the Claims interface.
func (c *Claims) GetIssuer() (string, error) {
	return c.parseString(ClaimFieldIssuer)
}

// GetSubject implements the Claims interface.
func (c *Claims) GetSubject() (string, error) {
	return c.parseString(ClaimFieldSubject)
}

func (c *Claims) parseString(key string) (string, error) {
	var (
		ok  bool
		raw interface{}
		iss string
	)
	raw, ok = (*c)[key]
	if !ok {
		return "", nil
	}

	iss, ok = raw.(string)
	if !ok {
		return "", authn.ErrorInvalidType
	}

	return iss, nil
}

func (c *Claims) parseStrings(key string) ([]string, error) {
	var cs []string
	switch v := (*c)[key].(type) {
	case string:
		cs = append(cs, v)

	case []string:
		cs = v

	case []interface{}:
		for _, a := range v {
			vs, ok := a.(string)
			if !ok {
				return nil, authn.ErrorInvalidType
			}
			cs = append(cs, vs)
		}
	}

	return cs, nil
}

// parseNumericDate tries to parse a key in the map claims type as a number
// date. This will succeed, if the underlying type is either a [float64] or a
// [json.Number]. Otherwise, nil will be returned.
func (c *Claims) parseNumericDate(key string) (*jwt.NumericDate, error) {
	v, ok := (*c)[key]
	if !ok {
		return nil, nil
	}

	switch exp := v.(type) {
	case float64:
		if exp == 0 {
			return nil, nil
		}

		return newNumericDateFromSeconds(exp), nil
	case json.Number:
		v, _ := exp.Float64()

		return newNumericDateFromSeconds(v), nil
	}

	return nil, authn.ErrorInvalidType
}

// parseClaimsString tries to parse a key in the map claims type as a
// [ClaimsStrings] type, which can either be a string or an array of string.
func (c *Claims) parseClaimsString(key string) (jwt.ClaimStrings, error) {
	var cs []string
	switch v := (*c)[key].(type) {
	case string:
		cs = append(cs, v)
	case []string:
		cs = v
	case []interface{}:
		for _, a := range v {
			vs, ok := a.(string)
			if !ok {
				return nil, authn.ErrorInvalidType
			}
			cs = append(cs, vs)
		}
	}

	return cs, nil
}

func newNumericDateFromSeconds(f float64) *jwt.NumericDate {
	round, frac := math.Modf(f)
	return jwt.NewNumericDate(time.Unix(int64(round), int64(frac*1e9)))
}
