# Vibe Coding 基础规范

> 统一的代码风格和开发规范，提升代码质量和团队协作效率

## 📋 文档概述

Vibe Coding 是一套为项目开发底座定制的代码风格和开发规范体系，旨在：

- **统一代码风格**：确保团队成员编写的代码风格一致，提高代码可读性
- **规范开发流程**：定义清晰的开发流程和最佳实践，减少错误和重复工作
- **提升代码质量**：通过规范约束，减少常见错误，提高代码稳定性和可维护性
- **促进团队协作**：统一的规范使得团队成员之间的协作更加顺畅

## 🎯 适用范围

本规范适用于项目开发底座及其项目服务的所有代码：

- **后端服务**：Go + go-kratos 微服务
- **前端服务**：Vue 3 + TypeScript + Vben Admin
- **配置文件**：YAML、JSON、Dockerfile 等
- **文档**：Markdown 格式的技术文档

## 🎨 代码风格指南

### 1. 缩进与换行

- **缩进**：使用 2 个空格进行缩进（前端和后端保持一致）
- **换行**：每行代码长度建议不超过 100 个字符
- **空行**：
  - 函数之间使用 1 个空行
  - 逻辑块之间使用 1 个空行
  - 文件末尾保留 1 个空行

### 2. 命名规范

#### 2.1 变量命名

- **前端**：使用驼峰命名法（camelCase）
  ```typescript
  // ✅ 推荐
  const userName = 'John';
  const userAge = 25;
  
  // ❌ 不推荐
  const username = 'John';
  const user_age = 25;
  ```

- **后端**：使用驼峰命名法（camelCase）
  ```go
  // ✅ 推荐
  userName := "John"
  userAge := 25
  
  // ❌ 不推荐
  username := "John"
  user_age := 25
  ```

#### 2.2 常量命名

- **前端**：使用大驼峰命名法（PascalCase）
  ```typescript
  // ✅ 推荐
  const MaxRetries = 3;
  const ApiUrl = 'https://api.example.com';
  
  // ❌ 不推荐
  const MAX_RETRIES = 3;
  const apiUrl = 'https://api.example.com';
  ```

- **后端**：使用全大写 + 下划线命名法（SNAKE_CASE）
  ```go
  // ✅ 推荐
  const MaxRetries = 3
  const ApiURL = "https://api.example.com"
  
  // ❌ 不推荐
  const maxRetries = 3
  const apiUrl = "https://api.example.com"
  ```

#### 2.3 函数命名

- **前端**：使用驼峰命名法（camelCase），动词 + 名词
  ```typescript
  // ✅ 推荐
  function getUserInfo(id: number): User {
    // ...
  }
  
  function validateForm(data: FormData): boolean {
    // ...
  }
  ```

- **后端**：使用驼峰命名法（camelCase），动词 + 名词
  ```go
  // ✅ 推荐
  func getUserInfo(id int) (*User, error) {
    // ...
  }
  
  func validateForm(data *FormData) bool {
    // ...
  }
  ```

#### 2.4 类和接口命名

- **前端**：使用大驼峰命名法（PascalCase）
  ```typescript
  // ✅ 推荐
  class UserService {
    // ...
  }
  
  interface UserRepository {
    // ...
  }
  ```

- **后端**：使用大驼峰命名法（PascalCase）
  ```go
  // ✅ 推荐
  type UserService struct {
    // ...
  }
  
  type UserRepository interface {
    // ...
  }
  ```

#### 2.5 文件命名

- **前端**：使用 kebab-case（短横线分隔）
  ```
  // ✅ 推荐
  user-service.ts
  login-form.vue
  api-client.ts
  
  // ❌ 不推荐
  UserService.ts
  loginForm.vue
  apiClient.ts
  ```

- **后端**：使用 snake_case（下划线分隔）
  ```
  // ✅ 推荐
  user_service.go
  login_handler.go
  api_client.go
  
  // ❌ 不推荐
  UserService.go
  loginHandler.go
  apiClient.go
  ```

## 📁 目录结构规范

## 当前实现基线

以下目录以当前仓库真实结构为准。旧产品文档中的 `doc/product`、`doc/vibe-coding`、泛化技术栈描述仅作为历史资料，不作为实现依据。

- 产品与设计资料位于 `docs/product`。
- Vibe Coding 规范位于 `docs/vibe-coding`。
- 后端底座管理后台基础能力优先落在 `backend-service/app/platform/admin`；AI/chat 通用能力落在 `backend-service/app/ai/service`；AVMC 业务服务落点待定义；`backend-service/app/version/service` 当前冻结，仅保留为迭代 3 复审候选。
- 前端底座管理后台当前优先落在 `frontend-service/apps/admin-antd-avmc`，后续是否改名另行确认。
- `backend-service-pkg-bakup` 是备份/参考目录，不作为默认开发目标。


### 1. 后端服务目录结构

```
backend-service/
├── api/                 # 生成的 API 代码
├── app/                 # 应用服务
│   ├── avmc/admin/      # 底座管理后台基础服务，当前路径待复审
│   │   ├── cmd/         # 命令行入口
│   │   ├── configs/     # 配置文件
│   │   ├── internal/    # 内部实现
│   │   │   ├── biz/      # 业务逻辑
│   │   │   ├── data/     # 数据访问
│   │   │   ├── server/   # 服务器配置
│   │   │   └── service/  # 服务实现
│   │   └── proto/        # Protobuf 定义
│   ├── ai/service/      # 底座 AI/chat 通用能力
│   └── version/service/ # 版本发布服务雏形，当前冻结
├── pkg/                 # 公共包
│   ├── auth/            # 认证授权
│   ├── bootstrap/       # 启动配置
│   ├── utils/           # 工具函数
│   └── viewer/          # 视图工具
└── proto/               # Protobuf 定义文件
```

### 2. 前端服务目录结构

```
frontend-service/
├── apps/                # 应用
│   ├── admin-antd-avmc/ # AVMC 项目服务管理后台
│   │   ├── public/      # 静态资源
│   │   ├── src/         # 源代码
│   │   │   ├── adapter/ # 适配器
│   │   │   ├── api/     # API 调用
│   │   │   ├── layouts/ # 布局组件
│   │   │   ├── locales/ # 国际化
│   │   │   ├── router/  # 路由配置
│   │   │   ├── store/   # 状态管理
│   │   │   ├── views/   # 页面组件
│   │   │   └── app.vue  # 根组件
│   │   └── .env         # 环境配置
│   ├── backend-mock/    # 后端接口模拟
│   ├── web-antd/        # Vben Ant Design 示例/参考应用
│   ├── web-ele/         # Vben Element Plus 示例/参考应用
│   ├── web-naive/       # Vben Naive UI 示例/参考应用
│   └── web-tdesign/     # Vben TDesign 示例/参考应用
├── packages/            # Vben 共享包，公共能力才放入
└── docs/                # 前端框架文档
```

### 3. 目录命名规则

- **使用小写字母**：所有目录名使用小写字母
- **使用短横线分隔**：多个单词使用短横线分隔（kebab-case）
- **避免使用下划线**：目录名不使用下划线
- **语义化命名**：目录名应清晰表达其功能

## 📝 注释规范

### 1. 函数注释

- **前端**：使用 JSDoc 风格注释
  ```typescript
  /**
   * 获取用户信息
   * @param id 用户ID
   * @returns 用户信息对象
   * @throws 当用户不存在时抛出错误
   */
  function getUserInfo(id: number): User {
    // ...
  }
  ```

- **后端**：使用 Go 风格注释
  ```go
  // getUserInfo 获取用户信息
  // id: 用户ID
  // return: 用户信息对象和错误信息
  func getUserInfo(id int) (*User, error) {
    // ...
  }
  ```

### 2. 代码注释

- **复杂逻辑**：对复杂的业务逻辑添加注释说明
- **关键算法**：对核心算法添加注释，说明算法原理
- **特殊处理**：对特殊情况的处理添加注释说明
- **TODO 标记**：使用 `// TODO:` 标记待完成的任务
- **FIXME 标记**：使用 `// FIXME:` 标记需要修复的问题

### 3. 文件头部注释

- **前端**：
  ```typescript
  /**
   * 用户服务
   * 处理用户相关的业务逻辑
   */
  ```

- **后端**：
  ```go
  // user_service.go
  // 用户服务
  // 处理用户相关的业务逻辑
  ```

## 🔧 错误处理规范

### 1. 前端错误处理

- **使用 try-catch**：对可能出错的操作使用 try-catch
- **统一错误处理**：使用全局错误处理函数
- **友好的错误提示**：向用户展示友好的错误信息
- **错误日志**：记录详细的错误日志，便于排查

```typescript
// ✅ 推荐
try {
  const userInfo = await getUserInfo(id);
  return userInfo;
} catch (error) {
  console.error('获取用户信息失败:', error);
  throw new Error('获取用户信息失败，请稍后重试');
}
```

### 2. 后端错误处理

- **返回错误信息**：函数应返回错误信息
- **错误包装**：使用 `errors.Wrap` 包装错误，保留错误链
- **统一错误响应**：API 接口返回统一的错误格式
- **错误日志**：记录详细的错误日志

```go
// ✅ 推荐
func getUserInfo(id int) (*User, error) {
  user, err := repo.FindByID(id)
  if err != nil {
    return nil, errors.Wrap(err, "查找用户失败")
  }
  return user, nil
}
```

## 🧪 测试规范

### 1. 测试覆盖率

- **核心功能**：核心业务逻辑的测试覆盖率应达到 80% 以上
- **关键路径**：关键业务流程的测试覆盖率应达到 90% 以上
- **边界情况**：应测试各种边界情况和异常情况

### 2. 测试文件命名

- **前端**：使用 `.test.ts` 或 `.spec.ts` 后缀
  ```
  user-service.test.ts
  login-form.spec.ts
  ```

- **后端**：使用 `_test.go` 后缀
  ```
  user_service_test.go
  login_handler_test.go
  ```

### 3. 测试方法命名

- **前端**：使用 `test` 前缀
  ```typescript
  testUserServiceGetInfo() {
    // ...
  }
  ```

- **后端**：使用 `Test` 前缀
  ```go
  func TestUserServiceGetInfo(t *testing.T) {
    // ...
  }
  ```

## 📦 版本控制规范

### 1. 分支管理

- **main**：主分支，用于发布稳定版本
- **develop**：开发分支，集成所有功能开发
- **feature/**：功能分支，用于开发新功能
- **bugfix/**：修复分支，用于修复 bug
- **release/**：发布分支，用于版本发布准备

### 2. 提交信息规范

使用语义化提交信息格式：

```
<type>(<scope>): <description>

<body>

<footer>
```

**Type 类型**：
- `feat`：新功能
- `fix`：修复 bug
- `docs`：文档更新
- `style`：代码风格调整
- `refactor`：代码重构
- `test`：测试相关
- `chore`：构建过程或辅助工具的变动

**示例**：
```
feat(auth): 添加微信登录功能

- 集成微信 OAuth2 认证
- 添加微信登录按钮
- 实现微信用户信息获取

Closes #123
```

### 3. 版本号规范

使用语义化版本号：`MAJOR.MINOR.PATCH`

- **MAJOR**：不兼容的 API 变更
- **MINOR**：向后兼容的功能性新增
- **PATCH**：向后兼容的 bug 修复

### 4. 子仓库提交规则

`backend-service` 和 `frontend-service` 是独立子仓库。后续开发涉及后端或后台代码变更时，需要分别维护子仓库提交，再回到根仓库更新子仓库指针。

- 后端代码变更在 `backend-service` 内提交。
- 前端后台代码变更在 `frontend-service` 内提交。
- 根仓库只提交文档变更、子仓库指针更新和根级配置变更。
- 不要只在根仓库提交而忽略子仓库内部提交。
- 查看状态时需要分别执行：
  - 根仓库：`git status`
  - 后端子仓库：`cd backend-service && git status`
  - 前端子仓库：`cd frontend-service && git status`

推荐提交顺序：

1. 在 `backend-service` 或 `frontend-service` 内完成代码提交。
2. 回到根仓库确认对应子仓库指针变化。
3. 在根仓库提交子仓库指针更新和相关文档。

## 🚀 开发流程规范

### 1. 代码提交流程

1. **本地开发**：在 feature 或 bugfix 分支上进行开发
2. **代码检查**：运行 lint 和类型检查
3. **测试**：运行测试用例，确保测试通过
4. **提交代码**：使用规范的提交信息格式
5. **创建 PR**：创建 Pull Request 到 develop 分支
6. **代码评审**：团队成员进行代码评审
7. **合并**：通过评审后合并到 develop 分支

### 2. 代码审查要点

- **代码风格**：是否符合 Vibe Coding 规范
- **功能实现**：是否正确实现了需求
- **代码质量**：是否存在潜在问题，是否可以优化
- **测试覆盖**：是否有足够的测试覆盖
- **文档完善**：是否有完善的文档和注释

## 📄 配置文件规范

### 1. 配置文件格式

- **后端**：使用 YAML 格式（config.yaml）
- **前端**：使用 .env 文件和 TypeScript 配置
- **Docker**：使用 Dockerfile 和 docker-compose.yml

### 2. 环境变量管理

- **开发环境**：.env.development
- **测试环境**：.env.test
- **生产环境**：.env.production

### 3. 敏感信息处理

- **避免硬编码**：敏感信息不应硬编码在代码中
- **使用环境变量**：敏感信息应通过环境变量注入
- **使用配置中心**：生产环境建议使用配置中心管理

## 🎯 最佳实践

1. **单一职责**：每个函数和模块应只负责一个功能
2. **接口分离**：使用接口定义明确的契约
3. **依赖注入**：使用依赖注入提高代码可测试性
4. **错误处理**：正确处理和传递错误信息
5. **日志记录**：合理记录日志，便于排查问题
6. **性能优化**：关注代码性能，避免不必要的计算
7. **安全意识**：注意代码安全性，避免常见安全问题

## 📚 参考资料

- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [Vue Style Guide](https://vuejs.org/style-guide/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

## 🤝 贡献指南

欢迎对 Vibe Coding 规范提出改进建议：

1. 创建 Issue 描述问题或建议
2. 提交 PR 包含具体的改进内容
3. 参与讨论，完善规范内容

---

**Vibe Coding 规范** | 持续更新中 🚀
