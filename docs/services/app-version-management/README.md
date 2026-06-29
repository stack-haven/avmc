# 应用版本管理中心服务

英文名：App Version Management Center  
简称：AVMC  
服务类型：项目开发底座上的业务项目服务  
当前状态：boundary pending

## 服务定位

应用版本管理中心是项目开发底座当前内置的第一个业务服务。它不是顶层项目本身，而是运行在底座能力之上的项目服务。

该服务面向多项目应用版本运营，覆盖版本资料、Release 发布、灰度策略、下载页配置、用户反馈、协议管理、推送通知、项目权限和后续 AI 辅助运营。

## 代码落点

后端：

- `backend-service/app/platform/admin`：历史上承载过 AVMC 管理后台能力，当前升级为项目开发底座管理后台基础服务，不再继续承接 AVMC 新业务。
- `backend-service/app/ai/service`：底座 AI/chat 通用能力服务，AVMC 如需接入 AI 能力需定义业务边界。
- `backend-service/app/version/service`：已存在版本发布服务雏形，当前冻结，迭代 3 前只做服务边界复审。
- AVMC 新业务后端落点：待定义。版本管理、Release、灰度、下载页、反馈、协议、推送不再默认进入 `app/platform/admin`。

前端：

- `frontend-service/apps/web-antd-admin`：当前承载底座管理后台前端；AVMC 业务前端落点待定义。

## 资料入口

- 产品需求总览：`docs/product/00-AVMC-产品需求总览.md`
- 迭代开发规划：`docs/product/00-AVMC-迭代开发规划.md`
- 模块划分与工具分析：`docs/product/00-AVMC-模块划分与工具分析.md`
- 模块归类：`docs/product/modules/README.md`
- 架构边界：`docs/architecture/00-AVMC-后端底座架构决策.md`

## 当前边界

- AVMC 服务可以复用项目开发底座的认证、权限、项目边界、前后端工程规范和生成链路。
- 版本管理和 Release 管理后台能力不再进入 `backend-service/app/platform/admin`。
- 客户端版本检查 API 的独立服务边界在迭代 3 前复审。
- 不把 AVMC 服务等同于整个仓库或整个项目开发底座。

## 后续服务扩展规则

新增业务项目服务时，应参考本文件建立独立服务定义，并明确：

- 服务定位。
- 后端和前端默认代码落点。
- 产品资料入口。
- 架构边界和冻结项。
- 与底座公共能力的关系。
