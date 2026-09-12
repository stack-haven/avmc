---
name: dev-conventions
description: AVMC 开发规则和约束（根仓库与子仓库的当前事实来源）
metadata:
  node_type: memory
  type: reference
  originSessionId: dcd0b72e-6b01-4816-8dc2-7219a28fe7f5
  last_reviewed: 2026-09-12
---

# 开发规则

> 事实来源：`.agents/AGENTS.md`、`.agents/RULES.md`、`.agents/REVIEW.md` 与 `docs/architecture/0-4-架构总览-工程治理总纲.md`。本文件只是精炼速查，规则以原文为准。

## 后端 API 契约流程
`proto -> api(生成) -> internal/service -> internal/biz -> internal/data -> ent/schema`

- Protobuf 是 API 事实来源，`backend-service/api` 下的文件不可手工编辑
- 业务编排在 `internal/biz`，repo interface 也在 biz，实现在 `internal/data`
- Ent schema 在 `internal/data/ent/schema`
- Wire provider set 随依赖变化同步更新
- 权限控制必须后端执行，项目级数据必须校验访问边界
- 错误统一用 kratos errors（`errors.BadRequest` / `Forbidden` / `NotFound` / `Conflict`）

## 前端 CRUD 模式
```
Page + useVbenVxeGrid + useVbenDrawer + useVbenForm
```
页面文件结构：`list.vue`、`data.ts`、`modules/`、`api/`、`locales/`，单组件不超过 300 行。

## 活跃服务（当前）
- 后端基础底座：`backend-service/app/platform/service`（Tech Foundation）
- 后端 AI：`backend-service/app/ai/service`
- 后端产品服务：`backend-service/app/evie/service`（active）
- 后端历史：`backend-service/app/version/service`（frozen）
- 前端管理后台：`frontend-service/apps/web-antd-admin`
- 不随意创建新的 Kratos service（参见 ADR-006 与 0-4 §二原则二）

## 文档层级
`.agents/` 是 Claude Code / Codex 共享的项目配置事实来源（与 `.codex/`、`CLAUDE.md` 软链接到同一目录）。`docs/architecture/` 是治理文档事实来源。`docs/product/`、`docs/services/` 为产品需求与服务定义。`docs/archive/` 仅历史参考，不作为实现依据。
