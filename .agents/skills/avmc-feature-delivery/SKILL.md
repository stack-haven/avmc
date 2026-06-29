---
name: avmc-feature-delivery
description: |
  按照 AVMC 项目规范交付完整的产品功能。当 Claude 被要求实现新功能、完成需求分析、补充验收标准、或进行跨前后端链路开发时应触发此 skill。

  触发场景：
  - "实现版本管理功能" / "做 Release 管理"
  - "开发用户反馈模块" / "帮我实现灰度发布"
  - "这个功能怎么做？先分析一下"
  - "审查这个功能交付的完整性"
  - 任何涉及新增完整业务模块的需求

  与之匹配的项目规则文件位于本项目根目录 CLAUDE.md 和 docs/product/。
---

# AVMC 功能交付工作流

按需求优先、契约驱动的方式交付 AVMC 功能。保证实现符合仓库当前规则，并为每一项验收标准提供验证证据。

## 1. 加载项目上下文

执行顺序：
1. 读取本仓库 `CLAUDE.md`（项目核心规则）
2. 读取目标服务中最接近的现有实现
3. 读取 `docs/product/README.md` 和相关需求文档
4. 读取 `docs/vibe-coding/backend/README.md` 或 `frontend/README.md`
5. `docs/archive/` 只用于追溯历史需求来源，不作为实现依据

## 2. 明确需求

需求分析阶段，明确以下事项：
- **用户或角色**：谁在用？权限边界在哪？
- **目标和业务结果**：解决什么问题？
- **范围内行为**：具体做什么？不做哪些？
- **生命周期状态**：状态列表和转换图
- **权限和项目数据边界**：项目隔离？角色限制？
- **失败场景**：空数据、加载中、网络异常、权限不足

发现需求文档与代码不一致时，**以当前代码为准**并记录差异。

## 3. 检查现有能力

找出最接近的实现模式作为参考：

### 后端链路
```
backend-service/proto -> api(生成) -> internal/service -> internal/biz -> internal/data -> ent/schema
```

### 前端链路
```
router -> views -> data.ts -> modules -> api -> locales
```

记录已有能力、可复用内容和缺失部分。不改生成文件、备份代码、示例代码。

## 4. 定义验收标准

每项标准用可观察行为描述：
- 前置条件
- 执行动作
- 预期结果
- 验证方式

除正常流程外，覆盖：权限拒绝、无效输入、状态冲突、破坏性操作确认、项目数据隔离。

## 5. 按依赖顺序实现

跨前后端功能的实现顺序：
1. 需求有歧义时先更新产品文档
2. 定义或更新 Protobuf 契约 —— **`backend-service/proto` 是起点**
3. 运行 `make proto` / `buf generate` 生成 API 输出
4. 实现 Ent schema → data/repo → biz/usecase → service → 注册 → Wire
5. 在行为附近添加后端测试
6. 实现有类型的前端 API wrapper
7. 实现路由、页面、schema、drawer/modal、i18n、权限
8. 为重要行为添加前端测试
9. 变更影响产品定义时更新 `docs/product` 文档

### 后端实现要求
- 迭代 1、2 的核心业务默认落在 `backend-service/app/avmc/admin`
- 权限控制必须在后端执行，不能只靠前端隐藏
- 项目级资源查询必须校验项目访问边界
- 认证失败、无权限和资源不存在应返回可区分的错误
- 生成文件（`backend-service/api`、`internal/conf`、`ent/gen`）不手工编辑

### 前端实现要求
- 底座管理后台页面默认放在 `frontend-service/apps/web-antd-admin`；AVMC 业务页面落点需先确认服务边界
- 优先使用 `Page + useVbenVxeGrid + useVbenDrawer + useVbenForm` 模式
- 新增可见 UI 文案同时添加中文和英文 locale key
- 破坏性操作（删除、发布、撤回、回滚）必须二次确认

## 6. 验证

### 后端检查
```bash
cd backend-service
go test ./...
# 契约变更时：
cd proto && buf lint && buf breaking --against '.git'
```

### 前端检查
```bash
cd frontend-service
pnpm -F @vben/web-antd-admin run typecheck
pnpm -F @vben/web-antd-admin run build
```

### 子仓库审计
分别检查根仓库、`backend-service`、`frontend-service` 的 git 状态。

## 7. 交付报告

最终报告必须包含：
- 已实现行为摘要
- 验收标准完成状态（逐项）
- 修改的文件列表（按分层）
- 验证结果（测试输出、lint 结果）
- 未解决的风险和待确认事项

## 约束红线
- ❌ 不手工修改生成代码（api、ent/gen、Swagger UI bundle）
- ❌ 不修改备份目录 `backend-service-pkg-bakup`
- ❌ 不修改非目标 Vben 应用（web-antd、web-ele、web-naive、web-tdesign）
- ✅ 可以翻阅 `.codex/skills/avmc-feature-delivery/references/delivery-checklist.md` 参考交付检查项
