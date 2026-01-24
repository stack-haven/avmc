# AVMC - 应用版本管理中心 (App Version Management Center)

## 项目概述

AVMC 是一套为多项目应用提供全面版本控制、灰度发布、用户反馈、推送通知与用户管理的开源系统平台。通过统一的管理后台和服务接口，帮助企业与开发团队实现稳定、安全、高效的应用更新与运营管理。

### 核心功能
- **多项目集中管理**: 支持多个项目独立配置版本策略，统一监控维护
- **灰度发布机制**: 基于用户ID、设备标签等精细化规则进行灰度发布
- **版本管理**: 支持版本回滚、更新记录跟踪，资源包与整包支持
- **用户反馈**: 问题收集、状态跟踪、统计分析、开发协作闭环
- **推送通知**: 支持系统通知/活动/更新推送，可接入第三方推送平台
- **权限管理**: 多角色支持（管理员、发布人员、测试人员等），支持行为审计

## 系统架构

```
avmc/
├── backend-service       # 后端服务（Go + go-kratos，大仓模式微服务架构）
├── frontend-service      # 前端管理后台（Vue 3 + TypeScript + vue-vben-admin）
├── doc/product           # 产品文档、设计资料等
├── docker-compose.yml    # Docker 部署配置
└── README.md             # 项目说明文档
```

### 技术栈

| 层级 | 技术 |
|------|------|
| **后端** | Go + go-kratos（大仓架构 + 微服务模式） |
| **前端** | Vue 3 + TypeScript + vue-vben-admin |
| **数据库** | MySQL / PostgreSQL |
| **缓存** | Redis |
| **认证** | JWT + Casbin 权限控制 |
| **ORM** | EntGo + GORM |
| **API** | gRPC + HTTP/REST |

## 快速开始

### 环境要求
- **后端**: Go 1.18+
- **前端**: Node.js 16+ 和 pnpm 9.12.0+
- **数据库**: MySQL 5.7+ 或 PostgreSQL 12+

### 克隆项目
```bash
git clone --recurse-submodules https://github.com/stack-haven/avmc.git
cd avmc
```

### 后端服务部署

```bash
cd backend-service

# 安装依赖
go mod tidy

# 生成代码（可选）
make proto      # 生成 protobuf 代码
make all        # 生成所有代码

# 配置数据库
cp configs/config.yaml.example configs/config.yaml
# 编辑 configs/config.yaml 配置数据库连接信息

# 运行服务
go run ./cmd/avmc
# 或者使用 Makefile
make build
./bin/avmc -conf ./configs
```

**后端服务默认端口**: `http://localhost:8000`

### 前端服务部署

```bash
cd frontend-service

# 安装依赖
pnpm install

# 配置 API 地址
# 编辑 .env 文件，配置后端 API 地址

# 运行开发服务器
pnpm dev

# 构建生产版本
pnpm build
```

**前端管理后台默认地址**: `http://localhost:3000`

## 开发指南

### 后端开发

#### 主要命令
```bash
# 初始化开发环境
make init

# 生成 protobuf 代码
make proto

# 构建项目
make build

# 生成所有代码
make all

# 运行测试
go test ./...
```

#### 项目结构
```
backend-service/
├── api/           # API 接口定义（protobuf）
├── app/           # 应用服务实现
├── cmd/           # 命令行入口
├── configs/       # 配置文件
├── internal/      # 内部代码
├── pkg/           # 公共包
├── proto/         # protobuf 定义文件
└── scripts/       # 脚本文件
```

### 前端开发

#### 主要命令
```bash
# 开发模式
pnpm dev              # 全部项目
pnpm dev:antd         # Ant Design 版本
pnpm dev:ele          # Element Plus 版本
pnpm dev:naive        # Naive UI 版本

# 构建
pnpm build            # 全部项目
pnpm build:antd       # Ant Design 版本
pnpm build:ele        # Element Plus 版本
pnpm build:naive      # Naive UI 版本

# 代码检查
pnpm lint
pnpm check:type       # TypeScript 检查
pnpm check:circular   # 循环依赖检查

# 测试
pnpm test:unit        # 单元测试
pnpm test:e2e         # 端到端测试
```

#### 项目结构
```
frontend-service/
├── apps/            # 应用项目
│   ├── web-antd/    # Ant Design 版本
│   ├── web-ele/     # Element Plus 版本
│   ├── web-naive/   # Naive UI 版本
│   └── admin-antd-avmc/ # AVMC 管理后台
├── packages/        # 共享包
│   ├── @core/       # 核心功能
│   ├── constants/   # 常量定义
│   ├── effects/     # 副作用处理
│   ├── icons/       # 图标
│   ├── locales/     # 国际化
│   ├── stores/      # 状态管理
│   ├── styles/      # 样式
│   ├── types/       # TypeScript 类型
│   └── utils/       # 工具函数
├── docs/            # 文档
├── playground/      # 测试环境
└── scripts/         # 脚本文件
```

## Docker 部署

项目支持 Docker 部署，使用 docker-compose 可以快速启动整个系统：

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 停止服务
docker-compose down
```

## 开发规范

### 代码风格
- **后端**: 遵循 Go 官方代码规范，使用 gofmt 格式化
- **前端**: 使用 ESLint + Prettier 进行代码格式化和检查
- **提交规范**: 遵循 Conventional Commits 规范

### 分支管理
- `main`: 主分支，稳定版本
- `develop`: 开发分支，集成测试
- `feature/*`: 功能分支
- `hotfix/*`: 热修复分支

### 测试要求
- **后端**: 核心功能需要单元测试覆盖
- **前端**: 关键组件和工具函数需要测试
- **API**: 接口测试确保稳定性

## 配置文件

### 后端配置 (backend-service/configs/config.yaml)
```yaml
server:
  http:
    addr: 0.0.0.0:8000
  grpc:
    addr: 0.0.0.0:9000

data:
  database:
    driver: mysql
    source: user:password@tcp(localhost:3306)/avmc?charset=utf8mb4&parseTime=True&loc=Local
  redis:
    addr: localhost:6379
    password: ""
    db: 0
```

### 前端配置 (frontend-service/.env)
```env
VITE_GLOB_API_URL=http://localhost:8000
VITE_GLOB_UPLOAD_URL=http://localhost:8000/upload
```

## 数据库设计

系统使用 MySQL/PostgreSQL 作为主要数据库，核心表包括：
- **projects**: 项目信息表
- **versions**: 版本信息表
- **users**: 用户信息表
- **roles**: 角色权限表
- **feedbacks**: 用户反馈表
- **notifications**: 推送通知表

## API 文档

后端服务提供以下 API 接口：
- **REST API**: `http://localhost:8000`
- **gRPC API**: `localhost:9000`
- **Swagger 文档**: `http://localhost:8000/swagger/`

## 监控与日志

- **日志**: 使用结构化日志，支持日志级别控制
- **监控**: 集成 Prometheus 指标收集
- **链路追踪**: 支持 OpenTelemetry

## 安全特性

- **认证**: JWT Token 认证机制
- **授权**: 基于 RBAC 的权限控制
- **数据加密**: 敏感数据加密存储
- **API 安全**: 防 SQL 注入、XSS 等攻击

## 扩展功能

未来计划升级为 **SAMP（Smart Application Management Platform）**，引入 AI 大模型能力：
- 智能版本预测
- 自动推送策略
- 故障预测与诊断
- 用户行为分析

## 支持与贡献

- **文档**: 查看 `doc/product/` 目录获取详细产品文档
- **贡献**: 遵循 CONTRIBUTING.md 指南
- **问题反馈**: 通过 GitHub Issues 提交问题和建议
- **社区**: 计划建立技术交流群

## 许可证

本项目基于 MIT License 开源，详见 LICENSE 文件。