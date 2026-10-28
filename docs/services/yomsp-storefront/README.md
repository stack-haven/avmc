# YOMSP Storefront · 俄罗斯爬宠用品独立站

> 状态：`planning`（Gate 0 仓库审查 ✅ / Gate 1 技术基线 ✅ 2026-10-28 / 下一步 Gate 2 设计系统）
> 代码仓库：`storefront-service`（子仓库，`git@github.com:stack-haven/avmc-storefront-service.git`，默认分支 `coding/ai`）
> 原始输入：《YOMSP 俄罗斯爬宠用品独立站构建规范 V1.0》（已归档至 `docs/archive/product-yomsp/`）
> 本文档集是拆分后的**当前事实来源**，归档单文件仅用于追溯。

---

## 1. 这个服务是什么

YOMSP 是面向**俄罗斯市场**的爬宠用品品牌独立站（B2C 公开站点）：品牌展示 + 专业商品目录 + 环境方案 + 标准模块化环境设计器 + 内容获客（SEO/GEO）。

它**不是**管理后台，也**不是** Ark Platform 底座能力。按 `.agents/AGENTS.md` 的定位，它属于**端承载层**之外的新增**公开站点承载（Public Web Storefront）**，与 `frontend-service`（Web 后台）、`mobile-desktop-service`（原生端）平级，消费 `backend-service` 的 API。

## 2. 当前阶段的核心决定（已明确）

| 项 | 决定 |
|---|---|
| 后端接口 | **本阶段不开发**。`backend-service` 不新增 `storefront` 服务，不改 proto |
| 数据来源 | 前端内置 **隔离 Mock Repository**，页面必须显示 Demo 标识 |
| 交付目标 | 确认前端框架结构、环境、公共组件与设计系统基线，完成可运行的前端骨架 + 核心页面 Mock 展示 |
| 后端接入 | 预留 `ApiXxxRepository`，切换只改一处（环境配置 / 依赖注入），不散落 `if (demo)` |

> 未由真实后端提供的价格、库存、销量、评价、认证、物流与售后承诺**一律不得伪装成真实数据**。Mock 数据必须可识别、非生产不可加载。

## 3. 文档导航

| 文档 | 内容 | 对应原规范章节 |
|---|---|---|
| [01 · 产品范围与约束](01-product-scope.md) | 定位、用户、价值主张、第一版含/不含、真实性原则、Agent 最高优先级指令 | §0 §1 |
| [02 · 信息架构与页面规格](02-ia-and-pages.md) | 导航、首页区块顺序、目录/商品/方案/设计器/购物车/指南逐页要求 | §4 |
| [03 · 设计系统与组件体系](03-design-system.md) | 视觉方向、Design Tokens、三层组件清单、Tailwind 约束、图片规范 | §3 |
| [04 · 前端架构与代码落点](04-frontend-architecture.md) | 技术基线、系统边界、渲染策略、目录结构、环境变量、Mock 切换机制、**代码放置建议** | §2 §11 |
| [05 · 首页内容运营架构](05-content-ops.md) | Slot / Section Registry / Schema 校验 / Draft-Preview-Publish | §5 |
| [06 · API 契约与 Mock 规范](06-api-and-mock.md) | 核心数据模型、建议 endpoint 与 Open Items、Repository 层、Mock 隔离规则 | §6 |
| [07 · SEO 与 GEO](07-seo-geo.md) | SSR 要求、metadata、JSON-LD、sitemap/robots、俄语内容可引用性 | §7 §8 |
| [08 · 俄语本地化与合规](08-localization.md) | 俄语/卢布/公制、术语表、法律与政策待确认项 | §9 |
| [09 · 质量、安全与可访问性](09-quality-security-a11y.md) | 安全、性能、可访问性、监控、验收标准（DoD） | §10 §14 §16 |
| [10 · 交付计划与 Gates](10-delivery-plan.md) | Gate 0–7 工作流、P0–P3 优先级、每阶段交付物、Agent 提示词 | §12 §13 附录 A/B |
| [11 · Open Items 与阻塞项](11-open-items.md) | 需业务方补确认的真实信息、Mock 兜底策略、风险登记 | §15 |
| [decisions/](decisions/) | 决策记录（ADR） | — |

## 4. 建议阅读顺序

- **首次了解**：README → 01 → 02
- **开始搭骨架**：04（架构/落点）→ 03（Tokens/组件）→ 06（Mock 契约）
- **开始写页面**：02 → 03 → 07（每页 metadata 同步做）
- **后端接入前**：06 → 11 → 05（运营配置需真实后端时）

## 5. 关键约束速查

- 默认语言**俄语**，货币**卢布（RUB）**，单位**公制**。
- 公开页必须 **SSR 或预渲染**，禁止把站点配成纯 SPA。
- Nuxt **不直连数据库**，价格/库存/可售/兼容性以 Go 后端为权威（本阶段为 Mock，Mock 也只是"演示权威"）。
- 页面禁止自造样式；颜色、间距、圆角、阴影、字号只能引用 Tokens。
- 组件不得直接读写 `localStorage`、不得直接拼 API URL；一律经 composable / repository。
- Mock 数据必须带 Demo 标识，生产构建默认不加载。
- 不做：3D 建模、真实支付、真实订单、虚构评价/销量/认证。

## 6. 变更记录

| 日期 | 变更 |
|---|---|
| 2026-10-28 | 由单文件规范 V1.0 拆分为本目录文档集；登记产品服务；形成 Gate 0 事实清单与代码落点建议（待确认） |
| 2026-10-28 | Gate 1 完成：新建 `storefront-service`，锁定 Node 22.19.0 + Nuxt 4.5.2 + Tailwind v4 等版本组合并完成兼容性验证；lint/typecheck/test/build 与 SSR 冒烟全部通过（记录见 `storefront-service/docs/qa/README.md`） |