# Evie ASR 产品服务

日期：2026-09-12
状态：active

> Evie 是 Ark Tech Platform 承载的**产品服务**，负责具体业务（语音识别、词库中心、文本增强）；Ark Tech Platform 负责多租户、认证、套餐、配额、审计、文件、通知、任务和服务接入等横向能力。

## 定位

企业级语音智能引擎：

- ASR 语音识别
- 词库中心（dictionary / word / relation）
- 文本增强引擎（8 层确定性 + 推断流水线）
- ASR + 增强统一执行入口

## 服务边界

- 后端：`backend-service/app/evie/service`（gRPC + HTTP 合一模式，服务前缀 `/evie/v1`）
- 轻量独立工具：`backend-service/app/evie/tool`（离线词库规范化、独立小服务）
- 前端模块：`frontend-service/apps/web-antd-admin/src/views/evie`（在管理后台内启用）

## 依赖的 Ark Platform Foundation 能力

- 认证授权：`pkg/auth`（JWT/Casbin/会话）
- 多租户隔离：通过 `platform/service` gRPC 委托鉴权与审计
- 菜单/按钮注册：`backend-service/app/platform/service/cmd/mock` 下 evie 模块的 seed 文件
- 异步任务、对象存储、参数配置：复用技术中台

## 依赖的 Ark Business Platform 能力

- 当前未依赖业务中台（订阅计费、客户运营）。如未来引入，须先在 `docs/services/evie-platform/` 增加业务接入设计文档。

## 资料入口

- 开发说明：`docs/services/evie-platform/development/`
  - 0-架构总览、1-ASR语音识别服务、4-多租户数据隔离设计、6-数据模型设计、7-开发路线图
  - 8-词库中心与文本增强引擎开发计划、9-词库中心交互优化-P0接口设计、10-流程图、11-evie-tool独立轻量工具开发计划、12-evie-tool 文本增强 M6 设计模式方案、13-evie-tool 外部 API 接入 pkg 设计、14-evie-tool 错误码文档
- 词库中心交互优化方案：`docs/services/evie-platform/词库中心交互优化方案.md`
- 产品能力评估：`docs/services/evie-platform/产品能力评估.md`
- 企业级 ASR 语音智能引擎开发说明：`docs/services/evie-platform/企业级 ASR 语音智能引擎——词库中心与文本增强引擎开发说明.md`
- 系统说明书：`docs/services/evie-platform/企业语音智能引擎系统说明书.md`

## 状态与变更追溯

- 当前代码落点：`backend-service/app/evie/{service,tool}`、`proto/evie/{service,tool}/v1`
- 平台侧关联：`docs/architecture/4-6-治理-开发功能清单.md` 与 `docs/architecture/4-7-治理-代码功能清单.md`
- 概念重命名历史（字典中心 → 词库中心、纠错 → 文本增强、热词删除）见 4-6 变更记录 2026-08-25

## 接入检查

新功能进入 Evie 时，仍按 `4-1-治理-产品服务模块接入规范.md` 的后端/前端清单执行；菜单/按钮同步到 `backend-service/app/platform/service/cmd/mock` 对应 evie seed 文件。
