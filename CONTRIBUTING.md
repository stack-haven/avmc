# 贡献指南（Contributing Guide）

欢迎为本项目贡献代码！我们非常欢迎你的贡献，无论是代码提交、文档改进，还是 Bug 报告和新功能建议。请阅读以下指南，以确保协作顺利高效。

---

## 🧱 我们接受的贡献类型

* 修复 Bug
* 新功能开发
* 改进文档
* 性能优化
* 构建与部署改进（CI/CD、Docker 支持等）
* 测试用例补充
* UI/UX 改进

---

## 🚀 快速开始

### 1. Fork 仓库

点击右上角的 Fork 按钮，将项目复制到你的账户下。

### 2. 克隆项目并初始化子模块

```bash
git clone --recurse-submodules https://github.com/your-username/saas-base.git
cd saas-base
```

### 3. 创建新的开发分支

```bash
git checkout -b feature/your-feature-name
```

### 4. 开发与测试

* 后端位于 `backend-service/`
* 前端位于 `frontend-service/`
* 遵循各模块内已有结构和规范

### 5. 提交代码

请确保使用清晰、规范的提交信息：

```bash
git commit -m ":sparkles: feat: 添加灰度策略支持"
```

建议使用 Emoji 提交规范（如 `:bug:`, `:sparkles:`, `:memo:` 等）

### 6. Push 到远程分支并创建 Pull Request

```bash
git push origin feature/your-feature-name
```

然后前往 GitHub 页面提交 Pull Request（PR）。

---

## 🧪 开发规范

### 前端

* 使用 [vue-vben-admin](https://github.com/vbenjs/vue-vben-admin) 的组件风格
* 保持逻辑清晰、注释充分

### 后端

* 使用 [go-kratos](https://github.com/go-kratos/kratos) 框架的目录约定
* 每个服务内保持职责分离，接口注释使用 Swagger 或 protobuf

### 通用

* 遵循统一的命名规范
* 所有提交应通过基本 lint / 格式化检查

---

## 📢 反馈 Bug 或建议功能

欢迎在 [Issue 区](https://github.com/stack-haven/avmc/issues) 提交：

* 描述问题或建议
* 附上重现步骤、截图、日志等信息
* 若为 Bug，请标注当前系统和版本信息

---

## ❤️ 感谢

感谢你的贡献！我们期待与你一起打造更完善的多租户项目开发底座。
