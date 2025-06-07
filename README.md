# 应用版本管理中心（App Version Management Center, AVMC）

> 多项目、智能化、可扩展的版本发布与灰度管理平台。

---

## 📌 项目简介

**AVMC（App Version Management Center）** 是一套为多项目应用提供全面版本控制、灰度发布、用户反馈、推送通知与用户管理的开源系统平台。通过统一的管理后台和服务接口，它帮助企业与开发团队实现稳定、安全、高效的应用更新与运营管理。

平台支持多个项目的独立管理及跨项目统一监控，并计划未来升级为 **SAMP（Smart Application Management Platform）**，引入 AI 大模型，提供自动推送、智能版本控制和故障预测等功能。

**核心优势**：

*   **降低维护成本**：统一管理多个应用的版本，减少重复工作。
*   **提升更新效率**：自动化灰度发布流程，快速验证新版本。
*   **优化用户体验**：及时收集用户反馈，持续改进应用质量。
*   **保障系统稳定**：完善的版本回滚机制，应对突发问题。

---

## 🧱 系统架构总览

```

avmc/
├── backend-service       # 后端服务（git 子模块 - Go + go-kratos，大仓模式微服务架构）
├── frontend-service      # 前端管理后台（git 子模块 - 基于 vue-vben-admin）
├── doc/product           # 产品文档、设计资料等
├── .gitmodules           # 子模块配置
└── README.md             # 项目说明文档

````

**架构说明**：

*   **前端**：Vue.js 3 + TypeScript，负责用户界面和交互。
*   **后端**：Go + go-kratos，提供 API 接口和业务逻辑。
*   **数据库**：MySQL/PostgreSQL，存储应用数据。
*   **存储**：阿里云 OSS/AWS S3，存储应用安装包和资源文件。
*   **消息队列**：Redis/Kafka，用于异步任务处理和消息通知。

---

## 🌟 为什么选择 AVMC？

- ✅ **多项目集中管理**：支持多个项目独立配置版本策略，统一监控维护。
- ✅ **灰度更新机制完善**：支持用户ID、设备标签等精细化规则灰度发布。
- ✅ **前后端开源框架成熟可靠**：
    - 后端基于 [go-kratos](https://github.com/go-kratos/kratos)，采用大仓模式构建模块化微服务架构。
    - 前端采用 [vue-vben-admin](https://github.com/vbenjs/vue-vben-admin)，Star 数超过 20k，界面美观、组件丰富。
- ✅ **AI 智能化扩展路线清晰**：计划集成 AI 大模型能力，实现智能推送、版本预测、反馈归类等。
- ✅ **企业级易部署**：可通过源码、自建、Docker 等多种方式部署。

---

## 🛠️ 核心功能模块

1. **版本管理**
    - 多项目独立版本控制、资源包与整包支持
    - 支持版本回滚、更新记录跟踪

2. **灰度发布**
    - 基于用户、设备、版本、地区等规则精准控制发布节奏

3. **用户反馈**
    - 问题收集、状态跟踪、统计分析、开发协作闭环

4. **基础信息管理**
    - 管理隐私协议、服务条款等内容，支持多语言版本

5. **推送通知**
    - 支持系统通知/活动/更新推送，可接入第三方推送平台

6. **用户管理与权限**
    - 多角色支持（管理员、发布人员、测试人员等），支持行为审计

---

## ⚙️ 技术栈

| 层级 | 技术 |
|------|------|
| **后端** | Go + [go-kratos](https://github.com/go-kratos/kratos)（大仓架构 + 微服务模式） |
| **前端** | Vue 3 + TypeScript + [vue-vben-admin](https://github.com/vbenjs/vue-vben-admin) |
| **数据库** | MySQL / PostgreSQL |
| **缓存与任务队列** | Redis（可选） |
| **未来扩展** | 集成 AI 大模型，支持智能策略和故障诊断预测 |

---

## 🚀 快速开始

### ✅ 克隆项目（含子模块）

```bash
git clone --recurse-submodules https://github.com/stack-haven/avmc.git
````

### 🔧 后端服务部署

1.  **安装 Go 环境**：确保已安装 Go 1.18+。
2.  **进入后端目录**：`cd avmc/backend-service`
3.  **下载依赖**：`go mod tidy`
4.  **配置数据库**：修改 `configs/config.yaml` 文件，配置 MySQL/PostgreSQL 连接信息。
5.  **运行服务**：`go run ./cmd/avmc`  # 或 `make run`

### 🖥️ 前端服务部署

1.  **安装 Node.js 环境**：确保已安装 Node.js 16+。
2.  **进入前端目录**：`cd ../frontend-service`
3.  **安装依赖**：`pnpm install`  # 或 `npm install`
4.  **配置 API 地址**：修改 `.env` 文件，配置后端 API 地址。
5.  **运行服务**：`pnpm dev`      # 或 `npm run dev`

### 🌐 访问系统

* 后端服务默认端口：`http://localhost:8000`
* 前端管理后台：`http://localhost:3000`

---

## 📸 系统界面预览

> 示例图请参考 `doc/product` 目录，或访问项目 Wiki（未来补充预览图链接）。

**版本管理**

![版本管理](https://via.placeholder.com/800x400)

**灰度发布**

![灰度发布](https://via.placeholder.com/800x400)

**用户反馈**

![用户反馈](https://via.placeholder.com/800x400)

---

## 📦 Docker 支持（即将提供）

计划提供 Docker 和 `docker-compose.yaml` 快速部署方案，敬请关注。

---

## 🤝 参与贡献

欢迎贡献代码、报告问题、提交功能建议！

*   请查阅我们的 [CONTRIBUTING.md](CONTRIBUTING.md) 了解贡献流程。
*   [行为准则](CODE_OF_CONDUCT.md)
*   如有任何问题，可通过 [Issues](https://github.com/stack-haven/avmc/issues) 与我们联系。

---

## 💬 社区与支持

我们计划开设：

*   GitHub Discussions
*   微信交流群 / QQ技术交流群

如果你感兴趣，欢迎 [创建 issue](https://github.com/stack-haven/avmc/issues/new) 反馈你的需求！

---

## 📝 许可证

本项目基于 [MIT License](LICENSE) 开源，欢迎自由使用与修改。