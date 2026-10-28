# ADR-0001 · 公开站点前端代码落点

- 状态：**proposed**（待确认）
- 日期：2026-10-28
- 决策者：待定（用户/架构负责人）
- 关联：[04 前端架构与代码落点](../04-frontend-architecture.md#4-代码落点建议--待确认)

---

## 背景

YOMSP 独立站是面向俄罗斯市场的**公开 SSR 站点**（Nuxt + Vue 3 + TS + Tailwind）。当前平台已有三个承载子仓库：

- `backend-service`（Go/Kratos）
- `frontend-service`（Vben Admin 5.7.0 pnpm + Turbo monorepo，定位 **Web 管理后台**）
- `mobile-desktop-service`（Flutter / RN / uni-app）

仓库内**不存在**任何 Nuxt 应用、Tailwind 配置或 storefront 契约（证据见 [04 §1](../04-frontend-architecture.md#1-gate-0--仓库审查事实2026-10-28)）。

## 候选方案

### A. 新建子仓库 `storefront-service`（推荐）

- 位置：`/avmc/storefront-service`，与 `frontend-service` 平级
- 独立 `package.json` / `pnpm-lock.yaml` / CI / 部署

### B. 加入 `frontend-service/apps/web-storefront`

- 复用 Vben 的 pnpm workspace 与 turbo

### C. 完全独立的外部仓库

- 不纳入 `avmc` 仓库体系

## 评估

| 维度 | A | B | C |
|---|---|---|---|
| 部署形态匹配（SSR/Node vs 静态 SPA） | ✅ | ❌ 流水线互相牵制 | ✅ |
| 工具链冲突（`only-allow pnpm`、turbo、oxlint、lefthook、`check:dep`） | ✅ 无冲突 | ❌ 全部覆盖新应用 | ✅ 无冲突 |
| 依赖版本自由度（Vue/Vite 被 Vben 锁定） | ✅ 独立 | ❌ 受制 | ✅ |
| 平台契约同步 / 统一治理 | ✅ | ✅ | ❌ |
| 仓库边界语义（frontend-service = Web 后台） | ✅ 清晰 | ❌ 破坏既有定位 | ✅ |
| 运维成本（多一个仓库） | ⚠️ 略高 | ✅ 低 | ✅ 低 |

## 决策

采用 **方案 A**：新建子仓库 `storefront-service`，Nuxt 单应用（不引入 Turbo monorepo），与 `frontend-service`、`backend-service`、`mobile-desktop-service` 平级。

## 理由（关键 3 条）

1. SSR 站点需要 Node 运行时与独立部署流水线，与 Vben 静态产物托管模型不同；
2. `frontend-service` 的 workspace 门禁（`preinstall: only-allow pnpm`、turbo pipeline、`vsh check-*`、oxlint/oxfmt/stylelint、lefthook）会强制覆盖新应用，且 Vue/Vite 版本被 Vben 决定；
3. `.agents/AGENTS.md` / `.agents/RULES.md` 已明确 `frontend-service` 是「Web 后台（PC 浏览器）」，公开站点应显式登记为新的承载形态，而非偷塞进后台仓库。

## 影响

### 需要同步的文件

```
.gitmodules                    # 新增 storefront-service
.agents/AGENTS.md              # 仓库结构 + 端承载表
.agents/RULES.md               # 仓库结构与提交规则
CLAUDE.md                      # 子仓库列表
docs/README.md                 # 目录说明
docs/services/README.md        # 承载层登记（已登记）
```

### 不变的部分

- `frontend-service` 仍是管理后台默认开发目标（`apps/web-antd-admin`）；
- 业务 API 契约未来仍定义在 `backend-service/proto`；
- 本阶段后端不开发，站点使用 Mock Repository。

## 后果

- **正面**：边界清晰、依赖解耦、可独立迭代与部署；
- **负面**：多一个仓库维护成本；跨仓库改动需按 `.agents/skills/avmc-submodule-sync` 顺序提交（子仓库先提交 → 根仓库更新指针）。

## 待确认

| # | 事项 |
|---|---|
| 1 | 是否批准新建子仓库（D1） |
| 2 | 远程仓库地址与命名（建议 `avmc-storefront-service`，D6） |
| 3 | 是否与 `frontend-service` 共用 pnpm `catalog`（不共用，保持独立） |

> 未获批准前**不**创建仓库、**不**修改 `.gitmodules` 与平台结构文档。