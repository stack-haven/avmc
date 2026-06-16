# 项目开发底座架构文档

本目录只放当前生效的项目开发底座架构决策、服务边界、冻结清单和拆分条件。项目服务定义放在 `docs/services`；产品需求、字段、验收标准放在 `docs/product`；代码规范放在 `docs/vibe-coding`。

## 当前文档

- `00-AVMC-后端底座架构决策.md`：项目开发底座当前后端大仓策略、底座管理后台基础服务、AVMC 服务边界、冻结清单和执行守门规则。

## 使用规则

- 新增业务模块前，先读取本目录，确认默认落点和禁止事项。
- 架构决策只能在本目录更新，不要散写到产品需求或旧归档文档中。
- `docs/archive` 中的历史架构描述只作参考，和本目录冲突时以本目录为准。
- 只有出现独立部署、独立扩缩容、独立公共 API、独立数据生命周期或清晰业务域边界时，才允许提出新 Kratos service。

## 当前冻结结论

- `backend-service/app/platform/admin` 当前升级为项目开发底座管理后台基础服务，目标是脱离具体业务。
- `backend-service/app/ai/service` 是项目开发底座 AI/chat 能力服务。
- `backend-service/app/version/service` 保留为已存在雏形，当前冻结，不作为迭代 1/2 的新增业务落点。
- AVMC 版本管理、Release、灰度、下载页、反馈、协议、推送不再继续进入 `backend-service/app/platform/admin`。
- AVMC 业务服务需要独立服务边界；`version/service` 是否升级为正式服务仍需复审。
