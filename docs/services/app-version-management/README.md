# 应用版本管理中心服务（历史参考）

英文名：App Version Management Center  
简称：AVMC  
服务类型：历史业务项目服务定义（作为后续新业务服务定义参考模板）
当前状态：historical

## 背景

本文档是底座上第一个业务服务的定义资料，作为后续新增业务项目服务的参考模板。

## 参考价值

新增业务项目服务时，应参考本文件建立独立服务定义，并明确：

- 服务定位
- 后端和前端默认代码落点
- 产品资料入口
- 架构边界和冻结项
- 与底座公共能力的关系

## 代码落点（历史记录）

后端：

- `backend-service/app/platform/admin`：历史上承载过业务管理后台能力，当前升级为底座管理后台基础服务，不再继续承接业务。
- `backend-service/app/ai/service`：底座 AI/chat 通用能力服务。
- `backend-service/app/version/service`：已存在版本发布服务雏形，当前冻结。
- 新业务后端落点：待定义。

前端：

- `frontend-service/apps/web-antd-admin`：当前承载底座管理后台前端；业务前端落点待定义。

## 资料入口

- 产品需求总览：`docs/archive/product-avmc/00-AVMC-产品需求总览.md`
- 迭代开发规划：`docs/archive/product-avmc/00-AVMC-迭代开发规划.md`
- 模块划分与工具分析：`docs/archive/product-avmc/00-AVMC-模块划分与工具分析.md`
- 架构边界：`docs/architecture/00-后端底座架构决策.md`
