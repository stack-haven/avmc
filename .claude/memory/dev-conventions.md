---
name: dev-conventions
description: AVMC 开发规则和约束
metadata: 
  node_type: memory
  type: reference
  originSessionId: dcd0b72e-6b01-4816-8dc2-7219a28fe7f5
---

# 开发规则

## 后端 API 契约流程
`proto -> api(生成) -> internal/service -> internal/biz -> internal/data -> ent/schema`

- Protobuf 是 API 事实来源，`backend-service/api` 下的文件不可手工编辑
- 业务编排在 `internal/biz`，repo interface 也在 biz，实现在 `internal/data`
- Ent schema 在 `internal/data/ent/schema`
- Wire provider set 随依赖变化同步更新
- 权限控制必须后端执行，项目级数据必须校验访问边界

## 前端 CRUD 模式
```
Page + useVbenVxeGrid + useVbenDrawer + useVbenForm
```
页面文件结构: `list.vue`, `data.ts`, `modules/`, `api/`, `locales/`

## 活跃服务
- 后端: `backend-service/app/avmc/admin`（迭代 1、2 默认目标）
- 前端: `frontend-service/apps/admin-antd-avmc`
- 不随意创建新的 Kratos service

## 文档层级
`.codex/` 是 Codex 旧配置（Claude Code 不读取）。`CLAUDE.md` 才是当前事实来源。`docs/product/` 为当前需求文档，`docs/archive/` 仅历史参考。
