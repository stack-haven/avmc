# AVMC 产品与 UI 设计规则

本文件总结 Codex 在创建或更新 AVMC 页面和相关文档时应遵循的产品与界面规则。

## 产品模块

AVMC 管理后台覆盖以下核心模块：

- 项目管理：项目列表、创建/编辑、状态、负责人、项目访问权限。
- 版本管理：版本列表、整包/资源包类型、发布说明、上传、强制更新、静默更新、回滚。
- Release 管理：草稿、待发布、已发布、已撤回、灰度/全量发布、发布时间窗口、更新统计。
- 下载页配置：模板、应用信息、下载链接、媒体/推广内容、预览、发布状态。
- 灰度发布：用户/设备/地区/活跃度策略、灰度比例、监控、成功/失败/取消指标。
- 用户反馈：Bug 报告、建议、评分/评论、状态、详情、附件/截图、回复或处理记录。
- 协议管理：隐私协议、服务条款、免责声明、历史版本、多语言内容、生效状态。
- 用户与权限管理：用户、角色、部门、菜单、权限标识、项目级访问权限。
- 推送通知：内容、受众、计划时间、渠道、投递统计。

## 界面气质

AVMC 是运营管理后台。页面应安静、紧凑，适合高频重复操作：

- 优先使用表格、筛选、tabs、drawers、详情面板、状态标签和紧凑指标区域。
- 管理后台页面不要做 landing page、hero、营销式或纯装饰布局。
- 页面标题保持实用、简短。
- 保持足够数据密度，但不要拥挤；表格操作和筛选项应稳定对齐。
- 优先使用可预期的 CRUD 流程，不追求新奇交互。

## 标准管理页模式

使用 `frontend-service/apps/admin-antd-avmc` 中现有的 Vben Ant Design 实现风格：

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

优先使用：

- `useVbenVxeGrid` 处理列表页、搜索表单、工具栏配置、分页。
- `useVbenDrawer` 处理创建/编辑/详情表单，除非相邻页面已有 modal 模式。
- `useVbenForm` 和 schema arrays 处理表单。
- `CellOperation`、`CellSwitch`、`CellTag` 等已有表格渲染器。
- 需要时使用 `ant-design-vue` 的 `Button`、`message`、`Modal`、`Spin`、upload components。

## CRUD 交互规则

- 列表页应包含模块最常用的搜索维度和状态筛选。
- 中等复杂度记录的创建/编辑表单优先使用 drawer。
- 删除等破坏性操作必须确认。
- 状态切换在提交到服务端前应确认用户意图。
- 创建/更新/删除后刷新表格，并显示消息反馈。
- 空数据、加载中、错误状态优先使用现有 Vben/table 行为，不做一次性自定义 UI。

## 字段与业务语言

产品文档中的字段名可作为业务词汇参考，但实现时要映射到真实 API 契约。常见术语：

- `project_id`、`project_name`、`project_status`、`project_owner`
- `version_code`、`version_name`、`version_release_notes`
- `version_is_force_update`、`version_is_silent_update`
- `version_download_url`、`version_file_size`、`version_md5`、`version_sha256`
- `release_name`、`release_version`、`release_type`、`release_status`
- `gray_release_strategy`

旧产品文档和当前代码冲突时，记录差异，并按当前代码实现。

## 导航与权限

- 新增管理后台路由放在 `src/router/routes/modules`。
- 菜单标题使用 i18n key，不要硬编码可见字符串。
- 图标使用与现有 route 一致的 Iconify/lucide 风格。
- 后端支持时，项目级权限和角色限制应体现在表格操作和 route/menu metadata 中。
- 不要在 UI 中暴露后端契约无法执行的操作。

## 视觉与文案规则

- 中文是主要业务语言；新增可见 UI 文案时提供英文 locale entry。
- 操作文案保持简短，例如 create、edit、delete、publish、rollback、preview、configure permissions。
- 状态标签应稳定且易扫描，例如 draft、gray、published、withdrawn、enabled、disabled、maintenance。
- 上传控件应展示可接受文件类型，并把安装包/媒体操作与普通文本字段明显区分。
- 指标展示使用紧凑卡片或表格汇总区域，不使用 oversized hero treatments。

## 设计 QA

完成前端 UI 工作前检查：

- 文案不会溢出表格操作、按钮、tabs 或 drawer 标题。
- 创建/编辑/删除/状态切换流程可用。
- 空数据和加载中行为正常。
- 中文和英文 locale key 能正常解析。
- 路由出现在预期菜单区域。
