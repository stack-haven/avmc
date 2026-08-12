---
name: avmc-contract-first-backend
description: 按照契约优先方式分析、实现和审查 Ark Tech Platform 后端功能，保证 Protobuf、生成 API、Kratos service、biz/usecase、data/repository、Ent schema、Wire、权限和测试完整一致。处理 backend-service 的新增接口、接口修改、数据模型变化、后端缺陷修复或后端代码审查时使用。
---

# Ark Tech Platform 契约优先后端开发

以后端 API 契约作为实现起点，确保所有受影响分层同步修改并通过验证。

## 启动前确认

与调用方确认以下信息：

- 目标服务（platform/admin、ai/service 等）
- 需求范围和业务目标
- 目标服务中最接近的现有实现（作为模板参考）

**功能清单确认（必须）：**

开始前必须读取 `docs/architecture/4-7-治理-代码功能清单.md`，在清单中找到或追加本次要修改的功能行。如果清单中的功能描述与实际需求不符，先与用户确认调整清单，再开始开发。开发完成后将对应功能行状态更新为 `[x]` 并填写源码追溯列。

硬约束：
- 不得将 `backend-service-pkg-bakup` 作为活跃实现目标
- 不得手工修改 `backend-service/api`、`internal/conf` 或 `internal/data/ent/gen` 中的生成文件
- `backend-service/app/platform/admin` 只承接平台基础能力；业务模块应先确认服务边界再决定落点

## 契约分析

修改前明确：

- 调用方和业务目标
- 请求、响应和错误行为
- 字段必填性、格式、长度和枚举约束
- 列表接口的 filtering、ordering 和 pagination 行为
- 权限、项目数据边界和数据所有权
- 幂等性、唯一性、状态转换和并发冲突
- 对现有调用方的兼容性影响

优先复用 `proto/common`、分页、枚举和相邻服务已有消息。创建新消息或字段前说明不能复用的原因。

### 列表契约分层

列表契约必须按使用场景拆分，避免“列表即详情”：

- 管理页分页列表 `ListXxx`：只包含列表列、筛选排序、状态展示和行操作判断必需字段。
- 详情接口 `GetXxx`：承载详情页、编辑页或复杂配置页需要的完整字段和关联数据。
- 简单列表 `ListXxxSimple` / `ListXxxSimples`：用于下拉选择、绑定关系、筛选项、树选择等高复用轻量场景。字段保持最小化，通常只包含 `id`、`name/title`、`code/key`、`status`、`sort`、`parent_id` 等实际可见或提交所需字段。
- 对复用率高的基础资源，优先新增 simple 类接口，不得让前端为了选择器或筛选项调用完整分页列表。角色列表需要轻量复用时，可参照现有 `ListUsersSimple` 补齐 `ListRoleSimple` 或与当前 proto 命名一致的简单列表接口。
- 如果完整列表和简单列表复用同一核心查询，data 层也应提供字段裁剪后的查询方法，避免无意义预加载关联或返回详情字段。

## 分层实施顺序

按以下顺序处理受影响区域：

1. 修改 `backend-service/proto` 下的 Protobuf 契约和校验规则。
2. 运行 Buf lint 和 breaking change 检查。
3. 使用仓库 Makefile 或 Buf 配置生成 API/OpenAPI。
4. 修改 Ent schema、mixin 和迁移行为。
5. 在 `internal/biz` 定义 repository interface、业务规则和 usecase。
6. 在 `internal/data` 实现持久化、过滤、分页和事务行为。
7. 在 `internal/service` 实现契约到业务模型的转换。
8. 更新 server 注册、Wire provider 和配置依赖。
9. 添加与变更行为相邻的测试。

没有影响的步骤可以跳过，但必须在最终说明中标记为“不涉及”。

## 权限与数据边界

- 权限控制必须在后端执行，不能只依赖前端隐藏。
- 项目级资源查询、读取、更新和删除都必须验证项目访问边界。
- 列表接口不得因缺少过滤条件而暴露其他项目数据。
- 管理员豁免、角色权限和 Casbin policy 必须沿用当前项目约定。
- 认证失败、无权限和资源不存在应返回可区分且符合相邻接口模式的错误。

## 测试要求

根据改动覆盖：

- 正常流程
- 参数校验失败
- 资源不存在
- 唯一性或状态冲突
- 权限拒绝
- 项目数据隔离
- repository filtering、ordering 和 pagination
- 状态转换或事务失败

优先使用表驱动测试和项目已有测试辅助方法。测试目标应是可观察业务行为，而不是生成代码细节。

## 验证

优先从最接近目标服务的位置运行：

```bash
go test ./...
```

契约变更时运行：

```bash
cd backend-service/proto
buf lint
buf breaking --against '<基准>'
```

使用当前仓库支持的实际基准替换 `<基准>`。无法运行 breaking 检查时说明原因。

验证生成命令没有意外修改无关生成文件，并分别检查根仓库和 `backend-service` 子仓库状态。

## 完成条件

最终报告必须说明：

- 契约和业务行为变化
- 各分层修改情况
- 权限和项目数据边界处理
- 生成命令和测试结果
- 兼容性风险
- 未完成或需要确认的事项
- **功能清单更新**：列出本次在 `docs/architecture/4-7-治理-代码功能清单.md` 中更新的行及其新状态

必要分层、测试、生成或权限验证未完成时，不得声称任务完成。
