# Ark Tech Platform 指南

> 项目配置统一管理在 `.agents/`，Claude Code 和 Codex 共享同一套规则。

## 必读

1. [.agents/AGENTS.md](.agents/AGENTS.md) — 项目概述、技术栈、开发规则
2. [.agents/RULES.md](.agents/RULES.md) — 结构与开发规则
3. [.agents/DESIGN.md](.agents/DESIGN.md) — 产品与 UI 设计规则
4. `docs/architecture/0-0-架构总览-架构总览.md` — 架构全景
5. `docs/architecture/0-1-架构总览-平台分层设计.md` — 四层架构定义
6. `docs/architecture/0-2-架构总览-技术栈与工程基线.md` — 工程基线
7. `docs/architecture/4-3-治理-能力路线图.md` — 能力总控
8. `docs/architecture/4-6-治理-开发功能清单.md` — 当前开发状态与断点
9. `docs/services/README.md`

## 中断后恢复

1. 读 `docs/architecture/4-6-治理-开发功能清单.md` → 查看「当前断点」
2. 读对应模块的设计文档 → 了解上下文
3. 开发 → 更新功能清单状态（`[ ]` → `[~]` → `[x]`）

## 快速参考

| 层级 | 技术 |
|------|------|
| 后端 | Go 1.24 + go-kratos v2 + Ent + Wire |
| 前端 | Vue 3 + Vben Admin + Ant Design Vue |
| API | Protobuf + gRPC + Buf |

**后端 flow:** `proto → api(生成) → service → biz → data → ent/schema`

**前端模式:** `Page + useVbenVxeGrid + useVbenDrawer + useVbenForm`

## 子仓库

`backend-service` 和 `frontend-service` 是独立子仓库。代码先在子仓库提交，再回根仓库更新指针。

## 约束

- 权限控制必须在后端执行，不能只依赖 UI 隐藏
- 生成代码（API、Ent gen、Swagger UI bundle）不手工修改
- 新增可见 UI 文案同时添加中英文 locale key
- 破坏性操作必须确认
- Feature Flag 不替代权限校验
- API 变更必须通过 `buf breaking` 兼容检查
- DB Schema 变更必须走 Atlas 迁移，不手工改表

## 验证

```bash
# 后端
cd backend-service && make check && make contract-check && go test ./...

# 前端
cd frontend-service && pnpm -F @vben/web-antd-admin run typecheck && pnpm -F @vben/web-antd-admin run build
```
