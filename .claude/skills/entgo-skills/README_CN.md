# Entgo Skills

[entgo.io](https://entgo.io) 的综合知识库 - Go 语言强大的实体框架，用于构建具有大型数据模型的应用程序。

[![GitHub](https://img.shields.io/badge/GitHub-lwx--cloud%2Fentgo--skills-blue)](https://github.com/lwx-cloud/entgo-skills)
[![Entgo](https://img.shields.io/badge/Entgo-v0.12+-green)](https://entgo.io)
[![Go](https://img.shields.io/badge/Go-1.20+-00ADD8)](https://golang.org)

**中文** | [English](README.md)

## 简介

Ent 是一个强大的 Go 语言实体框架，它简化了构建和维护具有大型数据模型的应用程序。它允许使用编程式 Go 代码和通过代码生成实现的静态类型来建模数据库模式为图结构。

## 核心特性

- **类型安全**: 生成的代码提供编译时类型安全
- **图结构**: 将数据建模为相互关联的实体
- **代码生成**: 从模式生成客户端、构建器和查询类型
- **多存储支持**: 支持 MySQL、PostgreSQL、SQLite、Gremlin
- **可扩展**: 支持 Hooks、Privacy、Validation 和自定义扩展

## 安装

### 安装 Ent CLI 工具

```bash
go install entgo.io/ent/cmd/ent@latest
```

### 作为 Claude Code Skill 安装

#### 方式 1: 使用 npx (推荐)

```bash
# 项目级别 (推荐)
npx skills add lwx-cloud/entgo-skills

# 个人级别 (所有项目)
npx skills add lwx-cloud/entgo-skills -g
```

#### 方式 2: 克隆到本地 Skills 目录

```bash
# 克隆到 Claude Code skills 目录
git clone https://github.com/lwx-cloud/entgo-skills.git ~/.claude/skills/entgo-skills
```

#### 方式 3: 在 Claude Code 中使用

添加到你的 Claude Code 配置:

```json
{
  "skills": [
    {
      "name": "entgo-skills",
      "path": "~/.claude/skills/entgo-skills"
    }
  ]
}
```

或直接在 Claude Code 中使用:

```
skill: entgo-skills
```

## 快速开始

```bash
# 创建一个新的 Ent 项目
mkdir myproject && cd myproject
go mod init myproject

# 创建 schema
go run -mod=mod entgo.io/ent/cmd/ent new User

# 生成代码
go generate ./ent
```

```go
// schema/user.go
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("name"),
        field.Int("age"),
    }
}

// 使用
user, err := client.User.Create().
    SetName("Alice").
    SetAge(30).
    Save(ctx)
```

## 目录结构

```
entgo-skills/
├── SKILL.md                    # Skill 主定义文件
├── README.md                   # 英文文档
├── README_CN.md                # 中文文档 (本文件)
├── getting-started/            # 入门指南
│   ├── installation.md         # 安装
│   ├── database-connection.md  # 数据库连接
│   └── first-schema.md         # 第一个 Schema
├── references/                 # 详细参考文档
│   ├── schema-fields.md        # Schema 字段
│   ├── schema-edges.md         # 关系定义
│   ├── schema-indexes.md       # 索引
│   ├── schema-mixins.md        # Mixin
│   ├── crud-create.md          # 创建
│   ├── crud-query.md           # 查询
│   ├── crud-update.md          # 更新
│   ├── crud-delete.md          # 删除
│   ├── hooks.md                # 钩子
│   ├── privacy.md              # 隐私策略
│   ├── transactions.md         # 事务
│   └── ... (共 33 个文件)
├── best-practices/             # 生产环境最佳实践
│   ├── project-structure.md    # 项目结构
│   ├── error-handling.md       # 错误处理
│   ├── soft-delete.md          # 软删除
│   └── testing.md              # 测试
└── troubleshooting/            # 常见问题排查
    ├── common-errors.md        # 常见错误
    ├── migration-issues.md     # 迁移问题
    └── performance.md          # 性能优化
```

## 文档导航

### 入门指南
- [安装](getting-started/installation.md) - 安装 ent 工具和项目设置
- [数据库连接](getting-started/database-connection.md) - 连接 MySQL、PostgreSQL、SQLite
- [第一个 Schema](getting-started/first-schema.md) - 创建你的第一个 Ent schema

### Schema 定义
- [Schema 字段](references/schema-fields.md) - 字段类型、验证、约束
- [Schema 关系](references/schema-edges.md) - 关系定义 (O2O、O2M、M2M)
- [Schema 索引](references/schema-indexes.md) - 单列、复合、唯一索引
- [Schema Mixins](references/schema-mixins.md) - 可复用的字段组
- [Schema 注解](references/schema-annotations.md) - 代码生成提示

### CRUD 操作
- [创建](references/crud-create.md) - Create、CreateBulk、关联创建
- [查询](references/crud-query.md) - Query、Where、条件、排序
- [更新](references/crud-update.md) - UpdateOne、Update、upsert 操作
- [删除](references/crud-delete.md) - DeleteOne、Delete、软删除模式

### 高级查询
- [条件](references/query-predicates.md) - Where 条件、操作符、自定义 SQL
- [预加载](references/query-eager-load.md) - WithX 方法、N+1 问题预防
- [图遍历](references/query-traversal.md) - 关系遍历、图查询
- [聚合](references/query-aggregation.md) - Count、Sum、GroupBy
- [分页](references/query-pagination.md) - Offset/Limit、游标分页

### 业务逻辑
- [Hooks](references/hooks.md) - Schema 钩子、全局钩子、验证
- [Privacy](references/privacy.md) - 策略规则、多租户、RBAC
- [验证](references/validation.md) - 字段验证、变更验证
- [事务](references/transactions.md) - Tx、WithTx、上下文传递

### 数据库与迁移
- [自动迁移](references/migrations-auto.md) - Schema.Create、自动迁移
- [版本化迁移](references/migrations-versioned.md) - Atlas、版本化迁移
- [数据库配置](references/database-config.md) - MySQL、PostgreSQL、SQLite
- [PostgreSQL 特性](references/postgresql-specific.md) - 数组、枚举、JSONB、全文搜索

### 集成与扩展
- [GraphQL (entgql)](references/graphql-entgql.md) - 使用 gqlgen 集成 GraphQL
- [gRPC (entproto)](references/grpc-entproto.md) - gRPC/Protobuf 集成
- [自定义模板](references/custom-templates.md) - 外部模板、扩展

### 高级特性
- [JSON 操作](references/json-operations.md) - JSON 字段操作、条件
- [锁](references/locking.md) - 悲观锁/乐观锁
- [拦截器](references/interceptors.md) - 查询拦截器
- [视图](references/views.md) - SQL 视图、物化视图

### 最佳实践
- [项目结构](best-practices/project-structure.md) - 目录布局、命名规范
- [错误处理](best-practices/error-handling.md) - 错误类型、包装、检查
- [软删除](best-practices/soft-delete.md) - 软删除实现
- [测试](best-practices/testing.md) - 使用 ent 测试、fixtures

### 问题排查
- [常见错误](troubleshooting/common-errors.md) - 未找到、约束错误
- [迁移问题](troubleshooting/migration-issues.md) - 迁移失败、schema 漂移
- [性能](troubleshooting/performance.md) - N+1、查询优化

## 外部资源

- [官方文档](https://entgo.io/docs)
- [GitHub 仓库](https://github.com/ent/ent)
- [Atlas 迁移工具](https://atlasgo.io)
- [示例](https://github.com/ent/ent/tree/master/examples)

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 许可证

MIT 许可证 - 详情参见 [LICENSE](LICENSE) 文件。

---

**[English Documentation](README.md)**
