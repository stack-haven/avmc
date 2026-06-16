# 项目开发底座文档中心

本文档目录按“架构决策、项目服务、产品需求、开发规范、历史归档”分层，方便 Codex 和人工开发者快速判断应读取哪份文档。

当前仓库的顶层定位是“项目开发底座”。应用版本管理中心（AVMC）是底座上的一个项目服务，相关产品资料目前集中在 `docs/product`，服务定义和资料入口集中在 `docs/services/app-version-management`。

## 读取顺序

处理产品或迭代开发任务时，优先读取：

1. `.codex/AGENTS.md`
2. `.codex/RULES.md`
3. `.codex/DESIGN.md`
4. `docs/architecture/README.md`
5. `docs/architecture/00-AVMC-后端底座架构决策.md`
6. `docs/services/README.md`
7. `docs/services/app-version-management/README.md`
8. `docs/product/README.md`
9. `docs/product/modules/README.md`
10. `docs/product/00-AVMC-产品需求总览.md`
11. `docs/product/00-AVMC-迭代开发规划.md`
12. `docs/product/00-AVMC-模块划分与工具分析.md`
13. `docs/vibe-coding/base/README.md`
14. `docs/vibe-coding/backend/README.md` 或 `docs/vibe-coding/frontend/README.md`

`docs/archive` 只作为历史资料查询，不作为当前实现依据。

## 目录说明

```text
docs/
├── architecture/             # 当前架构决策、服务边界和冻结清单
├── services/                 # 项目服务定义、资料入口和服务归类
├── product/                  # 当前项目服务产品需求和迭代开发主文档
├── vibe-coding/              # 当前开发规范和工程约定
└── archive/                  # 历史文档归档，不作为默认实现依据
```

## 当前事实来源

- 架构决策和冻结清单：`docs/architecture/README.md`
- 项目服务目录：`docs/services/README.md`
- 应用版本管理中心服务定义：`docs/services/app-version-management/README.md`
- 当前 AVMC 服务产品范围和验收标准：`docs/product/00-AVMC-产品需求总览.md`
- 当前 AVMC 服务后续迭代路线：`docs/product/00-AVMC-迭代开发规划.md`
- 当前 AVMC 服务模块边界和工具链：`docs/product/00-AVMC-模块划分与工具分析.md`
- 模块归类和开发状态：`docs/product/modules/README.md`
- 后端实现规则：`.codex/RULES.md` 与 `docs/vibe-coding/backend/README.md`
- 前端实现规则：`.codex/DESIGN.md` 与 `docs/vibe-coding/frontend/README.md`

旧文档中如出现 `Spring Boot`、`Django`、`React/Vue`、`doc/product`、`doc/vibe-coding` 等描述，仅代表历史规划，不作为当前项目开发依据。
