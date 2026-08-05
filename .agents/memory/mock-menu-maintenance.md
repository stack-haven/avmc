---
name: mock-menu-maintenance
description: All new features must update the menu-permission mock seed data
metadata:
  type: project
---

## Rule

每新增一个功能模块（新的管理页面或 API），必须同步更新 mock 数据中的菜单层级和权限配置。

**Why:** 菜单 mock 是开发环境和演示环境的唯一菜单数据来源。如果新增功能但不更新 mock，新页面将无法在侧栏菜单中访问，权限校验也无法通过。

**How to apply:**
1. 在 `backend-service/app/platform/admin/cmd/mock/main.go` 的 `seed()` 函数中添加新的 `menuIt()` 调用
2. 将新菜单挂到正确的一级目录下（租户管理/组织架构/权限安全/文件中心/通知中心/系统管理）
3. 更新 `verify()` 中的 menus 数量期望值
4. 重新运行 `make mock` 生成数据

## Current Menu Structure (27 items)

```
📊 仪表盘        → 工作台
🏢 租户管理      → 租户列表、租户套餐配置
👥 组织架构      → 用户管理、部门管理、岗位管理、角色管理、项目管理
🛡️ 权限与安全    → 菜单管理
📁 文件中心      → 文件列表、存储渠道
🔔 通知中心      → 通知模板、通知记录
⚙️ 系统管理      → 字典管理、参数配置、操作审计、登录日志、会话管理、异步任务、Webhook管理
```

Mock file: `cmd/mock/main.go`
Run: `cd backend-service/app/platform/admin && go run -tags mock ./cmd/mock -conf ./configs`
