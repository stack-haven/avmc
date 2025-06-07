// 示例代码：如何使用 go-auth 模块
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/go-kratos/kratos/v2"
	klog "github.com/go-kratos/kratos/v2/log"
	"github.com/go-kratos/kratos/v2/middleware"
	"github.com/go-kratos/kratos/v2/transport/http"
	"gopkg.in/yaml.v3"

	goauth "backend-service/pkg/go-auth"
	"backend-service/pkg/go-auth/authn"
	"backend-service/pkg/go-auth/authn/provider/jwt"
	"backend-service/pkg/go-auth/authz/provider/casbin"
	"backend-service/pkg/go-auth/config"
	"backend-service/pkg/go-auth/middleware"
)

func main() {
	// 创建上下文
	ctx := context.Background()

	// 加载配置
	cfg, err := loadConfig("config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 创建日志记录器
	logger := klog.NewStdLogger(os.Stdout)

	// 注册提供者
	goauth.RegisterAuthnProvider(jwt.NewJWTProvider(logger))
	goauth.RegisterAuthzProvider(casbin.NewCasbinProvider(logger))

	// 方式一：使用 Wire 进行依赖注入
	auth, cleanup, err := goauth.InitAuth(ctx, cfg, logger)
	if err != nil {
		log.Fatalf("初始化身份认证服务失败: %v", err)
	}
	defer cleanup()

	// 方式二：手动创建身份认证服务
	// auth, err := createAuthManually(ctx, cfg, logger)
	// if err != nil {
	// 	log.Fatalf("手动创建身份认证服务失败: %v", err)
	// }

	// 创建 HTTP 服务器
	httpSrv := createHTTPServer(auth)

	// 创建 Kratos 应用
	app := kratos.New(
		kratos.Name("go-auth-example"),
		kratos.Version("v1.0.0"),
		kratos.Logger(logger),
		kratos.Server(httpSrv),
	)

	// 启动应用
	if err := app.Run(); err != nil {
		log.Fatalf("应用运行失败: %v", err)
	}
}

// 加载配置
func loadConfig(path string) (*config.Config, error) {
	// 读取配置文件
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("读取配置文件失败: %v", err)
	}

	// 解析配置
	var cfg config.Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("解析配置失败: %v", err)
	}

	return &cfg, nil
}

// 手动创建身份认证服务
func createAuthManually(ctx context.Context, cfg *config.Config, logger klog.Logger) (*goauth.Auth, error) {
	// 创建身份验证器
	jwtCfg, ok := cfg.Authn.Providers["jwt"].(*config.JWTConfig)
	if !ok {
		return nil, fmt.Errorf("无效的 JWT 配置类型")
	}

	authenticator, err := jwt.NewJWTAuthenticator(jwtCfg, klog.NewHelper(logger))
	if err != nil {
		return nil, fmt.Errorf("创建身份验证器失败: %v", err)
	}

	// 创建身份鉴权器
	casbinCfg, ok := cfg.Authz.Providers["casbin"].(*config.CasbinConfig)
	if !ok {
		return nil, fmt.Errorf("无效的 Casbin 配置类型")
	}

	authorizer, err := casbin.NewCasbinAuthorizer(casbinCfg, klog.NewHelper(logger))
	if err != nil {
		return nil, fmt.Errorf("创建身份鉴权器失败: %v", err)
	}

	// 创建身份认证服务
	return goauth.NewAuth(authenticator, authorizer, logger), nil
}

// 创建 HTTP 服务器
func createHTTPServer(auth *goauth.Auth) *http.Server {
	// 创建 HTTP 服务器
	httpSrv := http.NewServer(
		http.Address(":8000"),
		http.Middleware(
			// 身份验证中间件
			middleware.AuthnMiddleware(auth.Authenticator, &middleware.AuthnMiddlewareOptions{
				SkipPaths: []string{"/login", "/public/*"},
			}),
			// 身份鉴权中间件
			middleware.AuthzMiddleware(auth.Authorizer, &middleware.AuthzMiddlewareOptions{
				SkipPaths: []string{"/login", "/public/*"},
			}),
		),
	)

	// 注册路由
	httpSrv.Route("/").POST("/login", handleLogin(auth))
	httpSrv.Route("/").GET("/profile", handleProfile)
	httpSrv.Route("/").GET("/public/info", handlePublicInfo)
	httpSrv.Route("/").POST("/articles", handleCreateArticle)
	httpSrv.Route("/").GET("/articles/{id}", handleGetArticle)

	return httpSrv
}

// 处理登录请求
func handleLogin(auth *goauth.Auth) http.HandlerFunc {
	return func(ctx http.Context) error {
		// 解析请求
		var req struct {
			Username string `json:"username"`
			Password string `json:"password"`
		}

		if err := ctx.Bind(&req); err != nil {
			return err
		}

		// 验证用户名和密码（示例）
		if req.Username == "" || req.Password == "" {
			return ctx.JSON(400, map[string]string{"error": "用户名和密码不能为空"})
		}

		// 创建主体
		subject := &authn.Subject{
			ID:    req.Username,
			Name:  req.Username,
			Roles: getRoles(req.Username),
		}

		// 进行身份验证
		tokenInfo, err := auth.Authenticator.Authenticate(ctx.Request().Context(), subject, &authn.AuthenticateOptions{
			Credentials: map[string]interface{}{
				"username": req.Username,
			},
		})

		if err != nil {
			return ctx.JSON(401, map[string]string{"error": fmt.Sprintf("身份验证失败: %v", err)})
		}

		// 返回令牌信息
		return ctx.JSON(200, tokenInfo)
	}
}

// 处理个人资料请求
func handleProfile(ctx http.Context) error {
	// 从上下文中获取声明信息
	claims, ok := middleware.ClaimsFromContext(ctx.Request().Context(), nil)
	if !ok {
		return ctx.JSON(401, map[string]string{"error": "未授权"})
	}

	// 返回个人资料
	return ctx.JSON(200, map[string]interface{}{
		"id":    claims["sub"],
		"name":  claims["name"],
		"roles": claims["roles"],
	})
}

// 处理公共信息请求
func handlePublicInfo(ctx http.Context) error {
	// 返回公共信息
	return ctx.JSON(200, map[string]string{
		"message": "这是公共信息，无需身份验证",
	})
}

// 处理创建文章请求
func handleCreateArticle(ctx http.Context) error {
	// 从上下文中获取声明信息
	claims, ok := middleware.ClaimsFromContext(ctx.Request().Context(), nil)
	if !ok {
		return ctx.JSON(401, map[string]string{"error": "未授权"})
	}

	// 解析请求
	var req struct {
		Title   string `json:"title"`
		Content string `json:"content"`
	}

	if err := ctx.Bind(&req); err != nil {
		return err
	}

	// 创建文章（示例）
	article := map[string]interface{}{
		"id":      "article-123",
		"title":   req.Title,
		"content": req.Content,
		"author":  claims["sub"],
	}

	// 返回文章信息
	return ctx.JSON(201, article)
}

// 处理获取文章请求
func handleGetArticle(ctx http.Context) error {
	// 获取文章 ID
	id := ctx.Vars().Get("id")

	// 获取文章（示例）
	article := map[string]interface{}{
		"id":      id,
		"title":   "示例文章",
		"content": "这是一篇示例文章的内容",
		"author":  "admin",
	}

	// 返回文章信息
	return ctx.JSON(200, article)
}

// 获取用户角色（示例）
func getRoles(username string) []string {
	switch username {
	case "admin":
		return []string{"admin"}
	case "editor":
		return []string{"editor"}
	default:
		return []string{"user"}
	}
}
