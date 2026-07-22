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
