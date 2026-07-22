# Ark Tech Platform

> 面向多产品 SaaS 的技术平台与业务承载底座，提供多租户、认证授权、菜单权限、业务套餐、资源配额、操作审计、参数配置、异步任务、文件、通知和产品服务接入能力。

## 项目简介

Ark Tech Platform 用于沉淀 Go + go-kratos 后端大仓、Vue Vben Admin 前端 monorepo，以及可复用的平台基础能力。平台之上可以承载多个 Ark Product Services，例如 GEO Engine、AI Agent Management、App Version Management 等。

| 能力 | 说明 |
|------|------|
| 多租户 | 租户生命周期管理、业务套餐、原子开通事务 |
| 认证授权 | JWT 双 Token、多设备会话、Casbin RBAC |
| 数据治理 | 数据字典、参数配置、数据权限、操作审计 |
| 安全会话 | 登录安全日志、失败锁定、Token 轮换、强制下线 |
| 用户组织 | 用户、角色、菜单、部门、岗位管理 |
| 通用能力 | 异步任务、文件中心、通知中心、对象存储 |
| 产品接入 | 产品服务定义、菜单权限注册、套餐配额注册 |

## 系统架构总览

```text
ark-tech-platform/
├── backend-service       # 后端服务（git 子仓库，Go + go-kratos）
├── frontend-service      # 前端管理后台（git 子仓库，Vue Vben Admin）
├── docs/architecture     # 当前架构决策、服务边界和平台路线图
├── docs/services         # Ark Product Services 目录和服务资料入口
├── docs/product          # 产品需求、字段、验收标准和迭代规划
├── docs/vibe-coding      # 代码规范与工程约定
├── docs/archive          # 历史文档归档
├── .codex                # Codex 代理规则
└── README.md             # 项目说明文档
```

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端 | Go + go-kratos（大仓 + 模块化服务边界） |
| API | Protobuf + gRPC + HTTP annotations + Buf |
| ORM | Ent |
| DI | Wire |
| 授权 | Casbin |
| 前端 | Vue 3 + TypeScript + Vben Admin + Ant Design Vue |
| 构建 | Vite + pnpm workspace + Turbo |
| 状态管理 | Pinia |
| 数据库 | MySQL / PostgreSQL |
| 缓存 | Redis |

## 快速开始

### 克隆项目

```bash
git clone --recurse-submodules https://github.com/stack-haven/avmc.git
```

### 后端服务

1. 安装 Go 环境。
2. 进入 `backend-service`。
3. 按具体服务目录的 Makefile 或 README 启动服务。

当前服务：

| 服务 | 路径 | 状态 | 职责 |
|------|------|------|------|
| Ark Platform Foundation 管理后台 | `app/platform/admin` | 活跃 | 租户、认证、用户、角色、菜单、权限、套餐、配置、审计、会话、任务、文件、通知 |
| AI/chat 服务 | `app/ai/service` | 活跃 | AI 通用能力 |
| 历史版本服务 | `app/version/service` | 冻结 | 保留已存在雏形，待复审 |

### 前端管理后台

```bash
cd frontend-service
pnpm install
pnpm -F @vben/web-antd-admin run dev
```

Node.js 和 pnpm 版本以 `frontend-service` 内的 package 配置为准。

## API 契约流程

```text
proto -> api(生成) -> internal/service -> internal/biz -> internal/data -> ent/schema
```

后端 API 契约以 `backend-service/proto` 为源头，生成代码位于 `backend-service/api`，生成文件不要手工修改。

## 文档导航

- 平台总览：`docs/architecture/00-Ark-Tech-Platform-架构总览.md`
- 架构决策：`docs/architecture/`
- 产品服务定义：`docs/services/`
- 开发规范：`docs/vibe-coding/`
- 产品需求：`docs/product/`
- 历史归档：`docs/archive/`

## 许可证

本项目基于 [MIT License](LICENSE) 开源，欢迎自由使用与修改。
