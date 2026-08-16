# Ark Product Services 目录

本目录用于定义 Ark Tech Platform 承载的产品服务。产品服务负责具体业务；Ark Tech Platform 负责多租户、认证授权、套餐、配额、审计、配置、任务、文件、通知和服务接入能力。

## 当前产品服务

| 服务 | 状态 | 定位 | 资料入口 |
| --- | --- | --- | --- |
| GEO Engine | planning | GEO 内容工程、知识库、AI 生成、后处理、发布、效果追踪 | `docs/services/geo-content-engine/README.md` |
| AI Agent Management | planning | 企业智能体、语音接入、身份映射、工具调用、知识问答、任务编排 | `docs/services/ai-agent-management/` |
| App Version Management | historical | 历史应用版本管理服务，作为后续产品服务定义参考 | `docs/services/app-version-management/README.md` |

## 使用规则

- 新增产品服务前，先在本目录增加服务定义，再补产品需求和代码落点。
- 服务定义用于说明“这个业务是什么”；架构决策仍放在 `docs/architecture`。
- 每个产品服务必须声明依赖的 Ark Platform Foundation 能力，以及是否依赖 Ark Business Platform 能力。
- 产品需求可以放在 `docs/product` 或服务目录内，但必须在服务定义中声明资料入口。
- `backend-service/app/platform/service` 是基础管理后台服务，不作为产品业务默认落点。
- `docs/archive` 中的产品资料只作历史参考，不作为当前实现依据。
