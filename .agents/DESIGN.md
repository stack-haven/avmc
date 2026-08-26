# Ark Tech Platform 产品与 UI 设计规则

本文件总结 coding agent 在创建或更新 Ark Tech Platform 管理后台、Ark Business Platform 能力和 Ark Product Services 页面时应遵循的产品与界面规则。

## 平台模块

Ark Tech Platform 管理后台优先覆盖以下平台基础模块：

- 租户管理：租户资料、状态、生命周期、开通、停用、到期。
- 用户与组织：用户、角色、部门、岗位、菜单、权限。
- 业务套餐：套餐、套餐版本、菜单权限边界、功能开关、资源配额。
- 安全与会话：登录日志、多设备会话、强制下线、Token 轮换。
- 数据治理：数据字典、参数配置、操作审计、数据权限。
- 通用能力：异步任务、文件中心、通知中心、Webhook、对象存储。
- 产品服务接入：产品注册、菜单注册、权限注册、配额注册、开通表单。

Ark Business Platform 后续覆盖：

- Product Registry
- Customer Operations
- Subscription & Billing
- Channel & Commission

Ark Product Services 当前包括：

- GEO Engine
- AI Agent Management
- App Version Management（historical）

## 界面气质

管理后台应保持工具型风格。页面应安静、紧凑，适合高频重复操作：

- 优先使用表格、筛选、tabs、drawers、详情面板、状态标签和紧凑指标区域。
- 管理后台页面不要做 landing page、hero、营销式或纯装饰布局。
- 页面标题保持实用、简短。
- 保持足够数据密度，但不要拥挤。
- 优先使用可预期的 CRUD 流程，不追求新奇交互。

## 标准管理页模式

使用 `frontend-service/apps/web-antd-admin` 中现有的 Vben Ant Design 实现风格：

```text
list.vue      # 页面壳、表格、工具栏、行操作
data.ts       # table columns、filter schema、form schema
modules/      # drawer/modal/detail components
api/          # request wrappers
locales/      # zh-CN 和 en-US labels
```

推荐页面结构：

```text
<Page auto-content-height>
  <FormDrawer />
  <Grid>
    toolbar actions
  </Grid>
</Page>
```

## 交互规则

- 列表页应包含最常用的搜索维度和状态筛选。
- 中等复杂度记录的创建/编辑表单优先使用 drawer。
- 删除等破坏性操作必须确认。
- 发布、撤回、回滚、停用、强制下线等高风险操作必须二次确认。
- 状态切换在提交到服务端前应确认用户意图。
- 创建、更新、删除后刷新表格，并显示消息反馈。
- 空数据、加载中、错误状态优先使用现有 Vben/table 行为。

## 导航与权限

- 新增管理后台路由放在 `src/router/routes/modules`。
- 菜单标题使用 i18n key，不要硬编码可见字符串。
- 图标使用与现有 route 一致的 Iconify/lucide 风格。
- 后端支持时，租户、角色、产品服务权限应体现在表格操作和 route/menu metadata 中。
- 不要在 UI 中暴露后端契约无法执行的操作。

## 视觉与文案规则

- 中文是主要业务语言；新增可见 UI 文案时提供英文 locale entry。
- 操作文案保持简短，例如 create、edit、delete、publish、rollback、preview、configure permissions。
- 状态标签应稳定且易扫描，例如 draft、enabled、disabled、active、suspended、published、withdrawn。
- 上传控件应展示可接受文件类型，并把文件操作与普通文本字段明显区分。
- 指标展示使用紧凑卡片或表格汇总区域，不使用 oversized hero treatments。

## 设计 QA

完成前端 UI 工作前检查：

- 文案不会溢出表格操作、按钮、tabs 或 drawer 标题。
- 创建、编辑、删除、状态切换流程可用。
- 空数据和加载中行为正常。
- 中文和英文 locale key 能正常解析。
- 路由出现在预期菜单区域。

---

## 产品服务模块设计模式

> 本章节适用于 **Ark Product Services**（Geo Engine、AI Agent Management、evie 等）
> 服务于「使用平台底座、面向终端业务场景」的产品服务模块。
> 沉淀自 evie 词库中心交互优化（2026-08-25）。

### 工作台 + 上下文模式（信息架构）

每个产品服务的根页面应是 **「决策中心」**，不是「子页面的导航大厅」：

- 顶部：「我的资源」（按租户过滤的列表）
- 中部：「全局事件 / 待处理」（跨资源聚合）
- 侧边：「健康度 / 指标」（基于业务日志聚合）
- 底部：「快速入口」（模板、导入、试用）

子资源（被父资源拥有的资源）应通过 **tabs 嵌在父资源详情页**内，而不是独立路由：

```text
# 推荐
/dictionaries                                       # 工作台
/dictionaries/:id           # 词库详情
/dictionaries/:id/entries   # 词条（默认 tab）
/dictionaries/:id/relations # 关系（在词库上下文里）

# 不推荐
/dictionaries
/dictionaries-entries
/dictionaries-relations  # 强迫用户先选 entry 才能看关系
```

例外：**跨父资源的共享资源**（如分类、全）才使用独立路由。

### 表单分组与智能默认值

复杂表单应分 **「基础」+「高级」** 两组，高级字段默认折叠：

- 基础字段：高频使用，立等可用
- 高级字段：偶尔使用，不占首屏空间
- 字段自动填充：拼音从 standardText 推算、不让用户重复劳动
- 字段示例占位符：「例：您好」「您好！」「您好。」

### 多租户 scope 视觉化

服务涉及多租户时，应统一 scope 颜色规范：

| Scope | 颜色语义 | 用途 |
|-------|---------|------|
| PLATFORM | 紫色 | 全平台共享 |
| SYSTEM | 蓝色 | 系统级 |
| TENANT | 绿色 | 租户私有 |

跨租户资源操作时，前端根据 `tenant_id` 显示「来自其他租户」徽章，提醒用户边界。

### 设计语言：服务品牌 vs 平台默认

每个产品服务应有自己的品牌色（避免所有页面都是平台蓝）：

- 主色：从业务语义出发（语音 →波形 →蓝色家族，但不是 antd 默认蓝）
- 业务色：按业务域划分子色（如 evie voice/vocabulary/enhance 三色）
- 字体：选有性格的（Plus Jakarta Sans、Inter、JetBrains Mono 等）
- 圆角：12-16px（比 antd 默认 6px 更大，更现代）

### 术语与文案规范

- 文案用用户视角（「删除」而不是「Delete」），按钮词当动词
- 错误信息友好（「无法删除：仍有 5 条词条关联」而不是「Conflict409」）
- 多租户 scope 文案统一：PLATFORM = 平台共享、SYSTEM = 系统级、TENANT = 租户私有
- 建立服务专属 `glossary.md`，中英文对照，ui 全部走 i18n

### 空状态与引导

空状态不是「暂无数据」，而是 **「行动邀请」**：

- 服务品牌插画（手绘风）
- CTA 引导（「还没有词库，从模板开始 →」）
- 操作示例数据（一键试用）

### 后端联动考虑

产品服务优化往往需要后端联动（接口调整）：

- **P0 接口先行**：UI 必需依赖的后端接口先实现
- **信息架构调整** → 后端需加聚合查询接口（如 `GetStats`、`ListByParent`）
- **多租户边界** → 后端必须按 scope 应用可见性，前端不传 tenant_id
- **自然语言化展示** → 后端需在响应中 JOIN 父资源字段（避免前端 N+1）

联动规划模板见 [词库中心交互优化-P0 接口设计](docs/services/evie-platform/development/9-词库中心交互优化-P0接口设计.md)。

---

## evie 设计 Token 参考（产品服务模块示范）

> 完整 Token 定义见 evie 服务层代码（后续在 `packages/effects/styles/` 下落地）：

```ts
export const evieTokens = {
  color: {
    primary: '#1F4FCC',              // evie 深靛蓝
    vocabulary: '#7B5BE8',           // 词库相关
    enhance: '#16A085',              // 文本增强相关
    scopePlatform: '#6F42C1',        // 紫色
    scopeSystem: '#0D6EFD',          // 蓝色
    scopeTenant: '#198754',          // 绿色
  },
  typography: {
    display: '"Plus Jakarta Sans", "PingFang SC", sans-serif',
    body: '"Inter", "PingFang SC", sans-serif',
    mono: '"JetBrains Mono", monospace',
  },
  radius: {
    card: '12px',
    button: '8px',
    input: '8px',
  },
};
```

后续产品服务（Geo Engine、AI Agent Management）应参考本 Token 规范，定制自己的品牌色与字体，避免与 evie 混淆。
