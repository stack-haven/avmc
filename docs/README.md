# Ark Tech Platform 文档中心

本文档目录是 Ark Tech Platform 的当前事实来源入口。后续开发和 Codex 代理判断项目结构时，只按 Ark Tech Platform 一套口径读取；原始合并来源已归档到 `docs/archive/architecture-ark-source`。

## 项目定位

**Ark Tech Platform** 是面向多产品 SaaS 的技术平台与业务承载底座，提供多租户、认证授权、数据隔离、菜单权限、业务套餐、资源配额、操作审计、参数配置、异步任务、文件、通知和产品服务接入能力。

GEO Engine、AI Agent Management、App Version Management 等都属于平台之上的 **Ark Product Services**，不代表平台本身。

## 快速入口

| 场景 | 入口 |
|------|------|
| 🆕 首次上手 | [`docs/GETTING_STARTED.md`](GETTING_STARTED.md) — 15 分钟本地启动 |
| 📖 术语查询 | [`docs/GLOSSARY.md`](GLOSSARY.md) — 统一业务与技术语言 |
| 🏗 架构全景 | [`docs/architecture/0-0-架构总览-架构总览.md`](architecture/0-0-架构总览-架构总览.md) |

## 读取顺序

处理架构、文档、后端或前端实现任务时，优先读取：

1. `.agents/AGENTS.md`
2. `.agents/RULES.md`
3. `.agents/DESIGN.md`
4. `.agents/REVIEW.md`
5. `docs/architecture/README.md`
6. `docs/architecture/0-0-架构总览-架构总览.md`
7. `docs/architecture/0-3-架构总览-后端底座架构决策.md`
8. `docs/services/README.md`
9. `docs/architecture/4-6-治理-开发功能清单.md`
10. `docs/architecture/4-7-治理-代码功能清单.md`
11. `CLAUDE.md`
12. `docs/vibe-coding/base/README.md`
13. `docs/vibe-coding/backend/README.md` 或 `docs/vibe-coding/frontend/README.md`

`docs/archive` 只作为历史资料查询，不作为当前实现依据。

## 目录说明

```text
docs/
├── GETTING_STARTED.md        # 🆕 15 分钟快速上手
├── GLOSSARY.md               # 🆕 术语表（业务与技术语言统一）
├── architecture/             # 当前架构决策、服务边界、冻结清单和平台路线图
├── services/                 # Ark Product Services 定义、资料入口和服务归类
├── product/                  # 业务产品需求文档入口
├── vibe-coding/              # 当前开发规范和工程约定
└── archive/                  # 历史文档归档，不作为默认实现依据
```

## 当前事实来源

- 平台总览：`docs/architecture/0-0-架构总览-架构总览.md`
- 架构索引：`docs/architecture/README.md`
- 后端服务边界：`docs/architecture/0-3-架构总览-后端底座架构决策.md`
- Ark 整合决策：`docs/architecture/4-4-治理-整合决策记录.md`
- 规划与当前断点：`docs/architecture/4-6-治理-开发功能清单.md`
- 代码实现与验证状态：`docs/architecture/4-7-治理-代码功能清单.md`
- 产品服务目录：`docs/services/README.md`
- 后端实现规则：`CLAUDE.md` 与 `docs/vibe-coding/backend/README.md`
- 前端实现规则：`CLAUDE.md` 与 `docs/vibe-coding/frontend/README.md`
- 历史来源：`docs/archive/`
