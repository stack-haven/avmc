# AVMC 文档中心

本文档目录按“现行主文档”和“历史归档”分层，方便 Codex 和人工开发者快速判断应读取哪份文档。

## 读取顺序

处理产品或迭代开发任务时，优先读取：

1. `.codex/AGENTS.md`
2. `.codex/RULES.md`
3. `.codex/DESIGN.md`
4. `docs/product/README.md`
5. `docs/product/00-AVMC-产品需求总览.md`
6. `docs/product/00-AVMC-迭代开发规划.md`
7. `docs/product/00-AVMC-模块划分与工具分析.md`
8. `docs/vibe-coding/base/README.md`
9. `docs/vibe-coding/backend/README.md` 或 `docs/vibe-coding/frontend/README.md`

`docs/archive` 只作为历史资料查询，不作为当前实现依据。

## 目录说明

```text
docs/
├── product/                  # 当前产品需求和迭代开发主文档
├── vibe-coding/              # 当前开发规范和工程约定
└── archive/                  # 历史文档归档，不作为默认实现依据
```

## 当前事实来源

- 产品范围和验收标准：`docs/product/00-AVMC-产品需求总览.md`
- 后续迭代路线：`docs/product/00-AVMC-迭代开发规划.md`
- 模块边界和工具链：`docs/product/00-AVMC-模块划分与工具分析.md`
- 后端实现规则：`.codex/RULES.md` 与 `docs/vibe-coding/backend/README.md`
- 前端实现规则：`.codex/DESIGN.md` 与 `docs/vibe-coding/frontend/README.md`

旧文档中如出现 `Spring Boot`、`Django`、`React/Vue`、`doc/product`、`doc/vibe-coding` 等描述，仅代表历史规划，不作为当前项目开发依据。
