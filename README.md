# 项目开发底座

> 面向多业务项目服务的 SaaS 多租户开发底座，提供认证授权、项目边界、数据隔离、菜单权限、操作审计、数据字典、租户生命周期等基础治理能力。

---

## 📌 项目简介

当前仓库是一个 **SaaS 多租户项目开发底座**，用于沉淀 Go + go-kratos 后端大仓、Vue Vben Admin 前端 monorepo、以下基础治理能力：

| 能力 | 说明 |
|------|------|
| 🏢 **多租户** | 租户生命周期管理、业务套餐、原子开通事务 |
| 🔐 **认证授权** | JWT 双 Token、多设备会话、Casbin RBAC |
| 📋 **数据字典** | 租户隔离的字典类型与字典项管理 |
| 📝 **操作审计** | Middleware 自动捕获、敏感字段脱敏、16KiB 截断 |
| 🔒 **登录安全** | 登录安全日志、失败锁定、Token 轮换 |
| 👥 **用户管理** | 用户/角色/菜单/部门/岗位 CRUD |
| 📁 **项目管理** | 项目归属与项目级权限边界 |
| 👁 **会话管理** | 在线会话列表、强制下线、多设备支持 |

底座之上可承载多个可扩展的业务项目服务。

---

## 🧱 系统架构总览

```
saas-base/
├── backend-service       # 后端服务（git 子模块 - Go + go-kratos，大仓模式微服务架构）
├── frontend-service      # 前端管理后台（git 子模块 - 基于 vue-vben-admin）
├── docs/architecture      # 当前架构决策、服务边界和冻结清单
├── docs/services          # 项目服务目录和服务资料入口
├── docs/product           # 业务项目服务产品需求和迭代开发主文档
├── docs/vibe-coding       # 代码规范与架构约定
├── docs/archive           # 历史文档归档
├── .gitmodules            # 子模块配置
└── README.md              # 项目说明文档
```

**架构说明**：

*   **前端**：Vue.js 3 + TypeScript，负责用户界面和交互。
*   **后端**：Go + go-kratos，提供 API 接口和业务逻辑。
*   **数据库**：MySQL/PostgreSQL，存储应用数据。
*   **存储**：阿里云 OSS/AWS S3（按需），存储资源文件。
*   **消息队列**：Redis（可选），用于异步任务处理和缓存。

---

## 🌟 核心优势

- ✅ **多租户底座**：成熟的多租户隔离、原子开通、生命周期管理
- ✅ **权限体系完善**：平台菜单池 → 业务套餐 → 角色二次分配，类似 AWS IAM Permission Boundary
- ✅ **安全合规**：全链路操作审计 + 登录安全日志 + 敏感字段脱敏
- ✅ **项目服务可扩展**：底座优先沉淀通用能力，业务服务可复用底座认证、权限、项目边界
- ✅ **前后端开源框架成熟可靠**：
    - 后端基于 [go-kratos](https://github.com/go-kratos/kratos)，采用大仓模式构建模块化微服务架构。
    - 前端采用 [vue-vben-admin](https://github.com/vbenjs/vue-vben-admin)，Star 数超过 20k，界面美观、组件丰富。
- ✅ **企业级易部署**：可通过源码、Docker 等多种方式部署。

---

## ⚙️ 技术栈

| 层级 | 技术 |
|------|------|
| **后端** | Go + [go-kratos](https://github.com/go-kratos/kratos)（大仓架构 + 微服务模式） |
| **API** | Protobuf + gRPC + HTTP (Google HTTP annotations) + Buf |
| **ORM** | [Ent](https://github.com/ent/ent) v0.14.5（带 Privacy 层实现行级数据隔离） |
| **DI** | [Wire](https://github.com/google/wire) v0.7.0 |
| **授权** | [Casbin](https://github.com/casbin/casbin)（RBAC + ABAC） |
| **前端** | Vue 3 + TypeScript + [vue-vben-admin](https://github.com/vbenjs/vue-vben-admin) |
| **构建** | Vite + pnpm workspace + Turbo |
| **状态管理** | Pinia |
| **数据库** | MySQL / PostgreSQL |
| **缓存** | Redis（可选） |

---

## 🚀 快速开始

### ✅ 克隆项目（含子模块）

```bash
git clone --recurse-submodules https://github.com/stack-haven/avmc.git
```

### 🔧 后端服务部署

1.  **安装 Go 环境**：确保已安装 Go 1.24+。
2.  **进入后端目录**：`cd saas-base/backend-service`
3.  **下载依赖**：`go mod download`
4.  **选择服务并配置**：
    - 底座管理后台基础服务：`app/platform/admin/configs/config.yaml`
    - AI/chat 通用能力：`app/ai/service/configs/config.yaml`
    - `app/version/service` 是历史版本发布服务雏形，当前冻结。
5.  **运行服务**：进入对应服务目录后优先使用该服务 `Makefile`/README 中的命令。

### 🖥️ 前端服务部署

1.  **安装 Node.js 与 pnpm**：Node.js `^22.18.0 || ^24.0.0`，pnpm `>=11.0.0`。
2.  **进入前端目录**：`cd ../frontend-service`
3.  **安装依赖**：`pnpm install`
4.  **配置 API 地址**：修改 `apps/web-antd-admin/.env*`，配置后端 API 地址。
5.  **运行管理后台**：`pnpm -F @vben/web-antd-admin run dev`

### ✅ 底座静态验收

完成依赖安装后，在根目录执行：

```bash
./scripts/verify-foundation.sh
```

该命令统一验证 Proto 契约、Buf lint 无新增债务基线、平台后端测试、差异格式、管理后台类型检查和生产构建。
数据库迁移、Mock 初始化及 HTTP 权限场景需要在 MySQL、Redis 启动后单独执行。

MySQL、Redis 和前端依赖均可用时，在根目录执行真实链路验收：

```bash
./scripts/verify-foundation-live.sh
```

该命令会执行平台管理后台迁移、连续两次 Mock 初始化并比较校验输出，再关闭 Nitro Mock 启动真实后端和管理后台，验证租户、业务套餐、角色、用户、参数和异步任务页面。

### 🌐 访问系统

* 后端服务默认端口：`http://localhost:8000`
* 前端管理后台：`http://localhost:3000`

---

## 🏗️ 底座服务架构

### 后端服务

| 服务 | 路径 | 状态 | 职责 |
|------|------|------|------|
| 🟢 底座管理后台 | `app/platform/admin` | **活跃** | 认证、用户、角色、菜单、权限、租户管理、字典、审计、会话 |
| 🟢 AI/chat 服务 | `app/ai/service` | **活跃** | AI 通用能力 |
| 🔴 历史版本服务 | `app/version/service` | **冻结** | 保留已存在雏形，待复审 |

### API 契约流程

```
proto -> api(生成) -> internal/service -> internal/biz -> internal/data -> ent/schema
```

### Kratos 目录结构（每个服务）

```
cmd/server/       # 可执行入口、Wire 启动
configs/          # 服务配置
internal/conf/    # 生成的配置结构
internal/server/  # HTTP/gRPC server 注册
internal/service/ # RPC 方法实现
internal/biz/     # usecase 和 repository interface
internal/data/    # repository、Data 容器、Ent client
```

### 多租户数据隔离

```
认证层    → JWT claims 注入 tenant_id
中间件层  → Ent viewer 从上下文提取 tenant_id
数据层    → Ent Privacy Policy 自动追加 tenant_id 过滤
平台操作  → NewSystemContext() 跳过租户过滤
```

---

## 📚 文档导航

- **架构决策**：`docs/architecture/` — 服务边界、多租户套餐、治理能力、认证安全、生命周期
- **项目服务定义**：`docs/services/` — 业务项目服务资料入口
- **开发规范**：`docs/vibe-coding/` — 基础/前端/后端 Vibe Coding 规范
- **产品文档**：`docs/product/` — 业务项目服务产品需求和迭代规划
- **历史归档**：`docs/archive/` — 旧文档不作为当前实现依据

---

## 📝 许可证

本项目基于 [MIT License](LICENSE) 开源，欢迎自由使用与修改。
