# 项目开发底座文档中心

本文档目录按"架构决策、项目服务、开发规范、历史归档"分层，方便开发者和 AI 代理快速判断应读取哪份文档。

当前仓库的顶层定位是 **SaaS 多租户项目开发底座**。底座提供认证授权、项目边界、数据隔离、菜单权限、操作审计、数据字典、租户生命周期等基础治理能力。业务项目服务可复用底座基础能力，但服务定义和资料需独立管理。

## 读取顺序

处理底座治理或迭代开发任务时，优先读取：

1. `CLAUDE.md`
2. `docs/architecture/README.md`
3. `docs/architecture/00-后端底座架构决策.md`
4. `docs/services/README.md`
5. `docs/vibe-coding/base/README.md`
6. `docs/vibe-coding/backend/README.md` 或 `docs/vibe-coding/frontend/README.md`

`docs/archive` 只作为历史资料查询，不作为当前实现依据。

## 目录说明

```text
docs/
├── architecture/             # 当前架构决策、服务边界和冻结清单
├── services/                 # 项目服务定义、资料入口和服务归类
├── product/                  # 业务项目服务产品需求（当前为空，待新增）
├── vibe-coding/              # 当前开发规范和工程约定
└── archive/                  # 历史文档归档，不作为默认实现依据
```

## 当前事实来源

- 架构决策和冻结清单：`docs/architecture/README.md`
- 项目服务目录：`docs/services/README.md`
- 业务服务定义参考：`docs/services/app-version-management/README.md`（历史参考）
- 后端实现规则：`CLAUDE.md` 与 `docs/vibe-coding/backend/README.md`
- 前端实现规则：`CLAUDE.md` 与 `docs/vibe-coding/frontend/README.md`
- 历史产品资料：`docs/archive/product-avmc/`（归档参考）
