# 快速上手 · Ark Tech Platform

> 🕐 预计时间：15 分钟
> 🎯 目标：在本地启动平台管理后台，创建第一个租户并登录

---

## 前置条件

| 依赖 | 最低版本 | 检查命令 |
|------|:---:|------|
| Go | 1.24+ | `go version` |
| Node.js | 20+ | `node -v` |
| pnpm | 9+ | `pnpm -v` |
| MySQL | 8.0+ | `mysql --version` |
| Redis | 7+ | `redis-cli ping` |
| Buf CLI | latest | `buf --version` |

---

## 第一步：克隆与初始化（2 分钟）

```bash
# 1. 克隆根仓库（含子仓库）
git clone --recurse-submodules <repo-url> ark-tech-platform
cd ark-tech-platform

# 2. 初始化后端依赖
cd backend-service
make init          # 安装 protoc-gen-go、kratos、wire 等工具
go mod tidy        # 下载 Go 依赖
cd ..

# 3. 初始化前端依赖
cd frontend-service
pnpm install       # 安装所有 workspace 依赖
cd ..
```

---

## 第二步：配置数据库与缓存（3 分钟）

### 2.1 创建数据库

```sql
CREATE DATABASE ark_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2.2 配置后端连接

编辑 `backend-service/app/platform/service/configs/config.yaml`：

```yaml
server:
  http:
    addr: 0.0.0.0:8000
    timeout: 30s
  grpc:
    addr: 0.0.0.0:9000
    timeout: 30s

data:
  database:
    driver: mysql
    source: root:yourpassword@tcp(127.0.0.1:3306)/ark_platform?charset=utf8mb4&parseTime=True&loc=Local
  redis:
    addr: 127.0.0.1:6379
    password: ""
    db: 0
```

### 2.3 启动 Redis

```bash
redis-server  # 或使用已有的 Redis 服务
```

---

## 第三步：启动后端（3 分钟）

```bash
cd backend-service

# 生成 Proto → API 代码
make proto

# 编译并启动 platform/admin 服务
go run ./app/platform/service/cmd/server/...
```

✅ 启动成功标志：

```
HTTP server listening on: [::]:8000
gRPC server listening on: [::]:9000
```

> **注意**：首次启动时 Ent 会自动执行 Schema 迁移，创建所有表结构。

---

## 第四步：启动前端（3 分钟）

```bash
cd frontend-service

# 启动管理后台开发服务器
pnpm dev:antd
```

✅ 启动成功标志：

```
VITE vX.X.X  ready in XXXms
➜  Local:   http://localhost:5173/
```

---

## 第五步：初始化平台（3 分钟）

首次启动后，平台数据库为空，需要初始化平台租户和管理员账号。

### 5.1 初始化平台种子数据

```bash
cd backend-service

# 运行初始化脚本（创建平台租户、默认菜单、角色和超级管理员）
go run ./cmd/seed/main.go
```

> 若尚无 seed 命令，可通过 API 手动创建：

```bash
# 创建平台超级管理员（需要临时关闭认证中间件或使用内部 API）
curl -X POST http://localhost:8000/api/v1/init/platform \
  -H "Content-Type: application/json" \
  -d '{
    "platform_name": "Ark Tech Platform",
    "admin_phone": "13800138000",
    "admin_password": "Admin@123456"
  }'
```

### 5.2 登录验证

1. 打开浏览器访问 `http://localhost:5173`
2. 使用初始化时设置的管理员手机号和密码登录
3. 进入工作台首页

---

## 第六步：创建第一个业务租户（1 分钟）

1. 左侧菜单 → **系统管理** → **租户管理**
2. 点击 **新增租户**
3. 填写：
   - 基础信息：企业名称、租户编码
   - 管理员信息：手机号、密码
   - 菜单权限组：选择一个预设权限组
4. 提交后在租户列表看到新租户，状态为 **已激活**

---

## 核心概念速览

| 概念 | 一句话说明 |
|------|----------|
| **平台控制面** | 平台管理员管理的全局配置域（租户生命周期、套餐、审计） |
| **租户数据面** | 租户成员的操作域（用户管理、文件、通知），tenant_id 由系统自动注入 |
| **技术中台** | 所有产品复用的技术底座（认证/审计/任务/文件/通知），不含业务逻辑 |
| **业务中台** | 跨产品运营能力（产品注册/客户运营/计费/渠道），当前设计阶段 |
| **产品服务** | 平台之上的具体业务产品（GEO Engine / AI Agent），通过注册制接入 |
| **四层防御** | 网关(JWT)→应用(tenant_id)→ORM(Ent Privacy)→数据库(外键)，每层独立校验 |

> 完整术语表见 [GLOSSARY.md](./GLOSSARY.md)

---

## 目录导航

| 想做什么 | 去哪里 |
|---------|--------|
| 了解整体架构 | [`docs/architecture/0-0-架构总览-架构总览.md`](architecture/0-0-架构总览-架构总览.md) |
| 开发新功能 | [`docs/architecture/4-6-治理-开发功能清单.md`](architecture/4-6-治理-开发功能清单.md)（先看断点） |
| 接入新产品 | [`docs/architecture/4-1-治理-产品服务模块接入规范.md`](architecture/4-1-治理-产品服务模块接入规范.md) |
| 编写后端代码 | [`docs/vibe-coding/backend/README.md`](vibe-coding/backend/README.md) |
| 编写前端页面 | [`docs/vibe-coding/frontend/README.md`](vibe-coding/frontend/README.md) |
| 运行测试 | [`docs/architecture/4-5-治理-测试策略.md`](architecture/4-5-治理-测试策略.md) |
| 了解安全设计 | [`docs/architecture/3-2-跨领域-安全架构设计.md`](architecture/3-2-跨领域-安全架构设计.md) |

---

## 验证命令

```bash
# 后端
cd backend-service
make check                    # 代码检查
make proto-lint               # Proto 规范检查
buf breaking                  # 契约兼容性检查
go test ./...                 # 单元测试

# 前端
cd frontend-service
pnpm -F @vben/web-antd-admin run typecheck   # 类型检查
pnpm -F @vben/web-antd-admin run build        # 构建验证
```

---

## 常见问题

### Q: 启动报 "Cannot connect to MySQL"

检查 MySQL 是否运行、config.yaml 中数据库连接信息是否正确。

### Q: 登录后接口返回 401

确认已完成平台初始化（seed 数据）。数据库为空时所有请求都会被认证中间件拦截。

### Q: 前端页面空白/报错

检查后端服务是否已启动（`http://localhost:8000`），前端 `.env` 文件中 API 地址是否正确。

### Q: proto 生成报错

确保已安装 Buf CLI：`brew install bufbuild/buf/buf`（macOS）或 `go install github.com/bufbuild/buf/cmd/buf@latest`。

---

> 📚 需要更深入了解？从 [docs/README.md](./README.md) 开始你的文档之旅。
