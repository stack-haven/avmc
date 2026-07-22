---
name: avmc-feature-delivery
description: 分析、规划、实现并验证项目开发底座上的项目服务功能，当前默认覆盖应用版本管理中心（AVMC）服务，确保需求与 API 契约、数据模型、前端行为、权限、测试、文档和子仓库交付之间可追踪。处理项目服务功能需求、需求澄清、实施规划、前后端联动改动、验收审查，或任务涉及 backend-service、frontend-service、docs/product 时使用。
---

# 项目服务功能交付

通过需求优先、契约驱动的工作流交付项目服务功能。当前主要项目服务是应用版本管理中心（AVMC）。保证实现符合仓库当前规则，并为每一项验收标准提供验证证据。

## 加载项目上下文

规划实现前，按以下顺序读取事实来源：

1. `.codex/AGENTS.md`
2. `.codex/RULES.md`
3. `.codex/DESIGN.md`
4. `docs/architecture/README.md`
5. `docs/architecture/00-后端底座架构决策.md`
6. `docs/services/README.md`
7. `docs/services/app-version-management/README.md`
8. 活跃服务或应用中最接近的现有实现
9. `docs/product/README.md`
10. `docs/product/modules/README.md`
11. `docs/product` 下与任务相关的当前文档
12. 相关的 `docs/vibe-coding/*/README.md`

以当前代码、`.codex`、`docs/architecture`、`docs/services` 和当前 `docs/product` 文档为事实来源。`docs/archive` 仅用于追溯历史需求意图。

## 选择交付模式

- 用户要求先分析后确认时，完成现状发现、歧义分析、影响矩阵和建议验收标准；停止在文件修改之前，等待用户确认。
- 用户要求实现时，完成从分析到验证的完整工作流。
- 用户要求审查时，将发现映射到需求和验收标准；优先报告缺陷、回归、测试缺口和未解决的需求歧义。

## 交付工作流

### 1. 明确需求

将功能需求重述为可执行内容：

- 用户或角色
- 目标和业务结果
- 范围内行为
- 明确的非目标
- 权限和项目数据边界
- 生命周期状态和状态转换
- 失败、空数据、加载中和破坏性操作行为

识别用户请求、当前产品文档和代码之间的冲突。不得静默处理会影响产品行为的重要歧义。仅当合理假设可能导致实现错误时向用户确认。

### 2. 检查现有能力

提出修改方案前，定位最接近的现有实现模式。

后端任务检查以下链路：

`backend-service/proto -> backend-service/api -> internal/service -> internal/biz -> internal/data -> internal/data/ent/schema`

前端任务检查以下链路：

`router -> views -> data.ts -> modules -> api -> locales`

记录已有能力、可复用内容和缺失内容。避免修改生成文件、备份代码、示例代码或无关的 Vben 应用。

### 3. 建立影响矩阵

使用 `references/delivery-checklist.md` 作为输出模板。将每个区域标记为：

- `required`：本次必须处理
- `not required`：本次无需处理
- `needs confirmation`：需要用户确认

在能够确定时填写准确目标路径。覆盖产品文档、API 契约、后端分层、持久化、权限、前端行为、i18n、测试、代码生成、CI 和子仓库交付。

### 4. 修改前定义验收标准

使用可观察行为编写可验证的验收标准。每项标准必须包含：

- 前置条件
- 执行动作
- 预期结果
- 验证方式

除正常流程外，根据功能需要覆盖权限拒绝、无效输入、状态冲突、破坏性操作确认和项目数据隔离。每项计划修改和测试至少关联一项验收标准。

### 5. 按依赖顺序实现

跨前后端功能默认按以下顺序实施：

1. 契约存在歧义时，澄清或更新当前产品文档。
2. 定义或更新 Protobuf 契约和校验规则。
3. 使用仓库命令生成 API 和 OpenAPI 输出。
4. 实现 Ent schema、repository、usecase、service、服务注册和 Wire 依赖。
5. 在行为附近添加后端测试。
6. 实现有类型约束的前端 API wrapper。
7. 实现路由、页面、schema、drawer/modal、权限和 locales。
8. 为重要行为添加前端单元测试或端到端测试。
9. 已交付行为改变产品定义时，更新当前产品文档。

仅当影响矩阵标记为 `not required` 时跳过对应步骤。

### 6. 根据影响矩阵验证

先运行范围最小且相关的检查，再根据风险扩大检查范围。

后端常用检查：

```bash
go test ./...
buf lint
buf breaking
```

前端常用检查：

```bash
pnpm -F @vben/web-antd-admin run typecheck
pnpm -F @vben/web-antd-admin run build
pnpm run test:unit
```

根据任务验证生成输出、中文和英文文案一致性、权限行为及 UI 行为。无法运行检查时，必须说明原因。

### 7. 审计交付完整性

分别检查以下 Git 状态：

- 根仓库
- `backend-service`
- `frontend-service`

不得修改用户已有的无关改动。只有代码修改已提交到所属子仓库后，才能将根仓库子模块指针更新视为完整交付。

最终报告：

- 已实现行为
- 验收标准完成状态
- 已修改文件或分层
- 验证证据
- 未解决决策或剩余风险

## 强制约束

- `backend-service/app/platform/admin` 当前只承接底座管理后台基础能力，不再默认承接 AVMC 业务模块。
- 当前 `frontend-service/apps/web-antd-admin` 作为底座管理后台前端；AVMC 业务前端落点待确认。
- 后端 API 修改必须从 `backend-service/proto` 开始；不得手工修改生成的 API 或 Ent 文件。
- 优先复用现有 Vben CRUD 模式和公共消息，再考虑新增抽象。
- 新增可见 UI 文案时，同时添加中文和英文 locale。
- 破坏性操作和状态转换必须要求用户确认。
- 项目级数据隔离和权限必须由后端行为保证，不能只依赖 UI 隐藏。
- 必要测试、代码生成或子仓库交付未完成时，不得声称任务已完成。
