# 02 · 前端功能所需接口清单（开发前基线）

> 状态：Explore 产出，**后端开发输入**。
> 依据：`storefront-service` 现存代码（Repository 契约 / API 实现 / 页面消费 / Nitro demo 路由 / 服务端 routes），
> 逐条核对得出，不含设想中的功能。
> 端点命名遵循 [01-architecture-design.md](01-architecture-design.md) §4（`/sites/v1/storefront|admin/...`）。
> YOMSP 为 site #1（`site.key=yomsp`；locales `ru,zh,en`，ru 默认；currency RUB）。

图例：**P** = 公开读（匿名、可 CDN、只读已发布）｜**A** = 运营（JWT + 权限点 + 审计）｜
**‖** = 需服务端 join/聚合（前端当前是客户端拼接）

> **范围扩展（2026-11）**：交易 / 身份 / 隐私域的接口（C1–C32）不在本文件，
> 见 [03-commerce-identity-privacy-requirements.md](03-commerce-identity-privacy-requirements.md) §5。
> 本文件仍是**内容与目录域**的唯一基线。

---

## 1. 公开读接口（storefront 面）

### 1.1 站点上下文（新增，当前前端硬编码）

| # | 方法 | 路径 | 参数 | 响应 | 消费方 |
|---|---|---|---|---|---|
| P1 | GET | `/storefront/site` | Host 解析（或 `site` 头） | `{ key, name, locales[], defaultLocale, currency, themeTokens, featureFlags }` | 全局 layout、`usePageSeo`、locale 切换 |

> 当前 `nuxt.config` 写死 `siteName/siteUrl` 与三语列表。后端化后按 Host 返回；
> 前端保留 `runtimeConfig` 兜底（离线 demo 构建仍可跑）。

### 1.2 目录 Catalog

| # | 方法 | 路径 | 参数 | 响应 | 消费方 |
|---|---|---|---|---|---|
| P2 | GET | `/storefront/catalog/categories` | — | `Category[]`（`id, slug, name, summary, image, sortOrder`） | 首页分类网格、configurator、`/catalog` 侧栏 |
| P3 | GET | `/storefront/catalog/categories/{slug}` | — | `Category`（404 → null） | `/catalog/:category` 标题与简介 |
| P4 ‖ | GET | `/storefront/catalog/products` | `category, sort, availability, page, pageSize, q, price, species, volume, power` | `{ items: Product[], total, page, pageSize, facets: CatalogFacet[] }` | `/catalog`、`/catalog/:category`、configurator、首页精选 |
| P5 | GET | `/storefront/catalog/products/{slug}` | — | `Product`（404 → null） | `/products/:slug` |
| P6 ‖ | GET | `/storefront/catalog/products:batch` | `ids[]`（≤100） | `Product[]`（按请求顺序，缺失跳过） | 首页 section 的商品、`/habitats/:slug` 模块商品 |
| P7 ‖ | GET | `/storefront/catalog/products/{id}/related` | `limit=4` | `Product[]`（先 compatible，再同类目兜底） | `/products/:slug` 相关商品 |
| P8 ‖ | GET | `/storefront/catalog/products/{id}/taxa` | `taxonomy=species` | `{ id, slug, name, image? }[]` | `/products/:slug`「适养物种」chips |

- P4 的 facet 语义（价格/容积/功率桶、species 反查、计数作用域）必须与
  `storefront-service/server/utils/catalog-query.ts` 逐条一致（parity 门禁）；
- P6/P7/P8 是**必须新增**的服务端聚合：现实现分别用「拉 200 条再客户端过滤」和
  「拉全量 species 再反查」，后端不能沿用（数据量一涨就崩）。

### 1.3 内容 Content（知识库）

| # | 方法 | 路径 | 参数 | 响应 | 消费方 |
|---|---|---|---|---|---|
| P9 ‖ | GET | `/storefront/content/entries` | `category, tag, species, page, pageSize` | `{ items: ArticleSummary[], total, page, pageSize, categories: ContentCategory[], tags: string[] }` | `/journal`、首页知识库区、`/admin/content` 列表 |
| P10 ‖ | GET | `/storefront/content/entries/{slug}` | — | `{ article: ArticleDetail, relatedArticles[], relatedProducts[], settings }` | `/journal/:slug`、`/admin/content` 详情 |
| P11 | GET | `/storefront/content/settings` | — | `ContentSettings`（12 个字段，见类型） | `/journal/:slug`、`/journal` 分页、admin |

- 可见性：`status=published` 且（站点开启严格模式时）`review_status=verified`；
- `scheduled` + `publish_at` 需服务端按当前时间过滤（demo 已如此实现）。

### 1.4 分类法 Taxonomy（物种）

| # | 方法 | 路径 | 参数 | 响应 | 消费方 |
|---|---|---|---|---|---|
| P12 ‖ | GET | `/storefront/taxonomies/{key}` | `group?` | `{ items: TaxonNodeProfile[], groups: {slug,name}[] }`；`essentials` 内联商品 | `/species`、首页物种带、`/products/:slug` chips、`/journal/:slug` chips |
| P13 ‖ | GET | `/storefront/taxonomies/{key}/{slug}` | — | `TaxonNodeProfile` + `readingPath[]`（ArticleSummary）+ `relatedArticles[]` + `bundles[]` | `/species/:slug` |

- `key=species` 对应现 `SpeciesRepository`；护理参数走属性表，`sourceReferences` 与 `reviewStatus` 必返；
- 现前端在商品页/文章页用「全量 species 列表 + 客户端反查」实现 chips → **后端应提供 P8 / P12 的过滤参数**（`productId`、`entrySlug`）替代。

### 1.5 方案与配置器

| # | 方法 | 路径 | 参数 | 响应 | 消费方 |
|---|---|---|---|---|---|
| P14 | GET | `/storefront/bundles` | — | `HabitatBundle[]`（含 `modules[].productId`、`priceStatus`） | `/habitats`、首页方案区 |
| P15 ‖ | GET | `/storefront/bundles/{slug}` | — | `HabitatBundle` + `modules[].product`（内联商品，替代 `getByIds`） | `/habitats/:slug` |
| P16 | GET | `/storefront/configurator/modules` | — | `ConfiguratorModule[]` | `/configurator` |
| P17 | POST | `/storefront/configurator/validate` | body `{ selection: [{moduleKey, productId, quantity}] }` | `{ ok, issues[], estimateTotal? }` | `/configurator` |

- P17 是**唯一公开 POST**：规则在服务端（兼容矩阵 + 合计价）；缺价不得当 0（沿用现语义）；
- 公开写接口需限流 + 不落库（纯计算）。

### 1.6 页面编排（首页）

| # | 方法 | 路径 | 参数 | 响应 | 消费方 |
|---|---|---|---|---|---|
| P18 | GET | `/storefront/pages/{key}` | `key=home` | `PageSection[]`（published 快照；含 `sectionType/slotKey/sortOrder/config/refs/itemLimit`） | `/` |

- 现前端把「section 引用 id → 实体」在客户端组装（`index.vue` 先取 id 再批量取实体）。
  后端两种可选实现，**建议 B**：
  - A：维持引用 id，前端继续自行批量取（需要 P6/P12 等批量端点）；
  - B：`/pages/home` 直接返回**已 hydrate 的 section 数据**（`products[]`/`species[]`/`articles[]` 内联），
    减少往返且 SSR 更快；前端 `SectionRenderer` 的 props 形状不变。

---

## 2. 运营接口（admin 面）

> 与现有 `/admin/homepage`、`/admin/content` 原型对齐；全部 JWT + 权限点 + 操作审计。
> 列表统一 AIP：`page_size / page_token / filter / order_by` + `listing.Option`。

### 2.1 内容运营（替换 `/admin/content` 的 localStorage）

| # | 方法 | 路径 | 说明 |
|---|---|---|---|
| A1 | GET | `/admin/content/entries` | 列表（含 draft），支持 `filter`（状态/分类/语言缺失） |
| A2 | GET | `/admin/content/entries/{id}` | 详情（含三语 body blocks、faq、refs） |
| A3 | POST | `/admin/content/entries` | 新建（默认 draft） |
| A4 | PUT | `/admin/content/entries/{id}` | 更新 |
| A5 | DELETE | `/admin/content/entries/{id}` | 软删除 |
| A6 | POST | `/admin/content/entries/{id}:publish` | 发布（需 `review_status=verified`） |
| A7 | POST | `/admin/content/entries/{id}:unpublish` | 下线 |
| A8 | POST | `/admin/content/entries/{id}:review` | 标记核验（`verified/rejected` + reviewer） |
| A9 | GET/POST/PUT/DELETE | `/admin/content/categories[/{id}]` | 分类 CRUD（含 `presentation: task|knowledge`） |
| A10 | GET/PUT | `/admin/content/settings` | 内容基础配置（单例） |
| A11 ‖ | GET | `/admin/content/blocks/schema` | 返回 block JSON Schema（版本化），前端 block 编辑器据此渲染 |

### 2.2 页面编排运营（替换 `/admin/homepage` 的 localStorage）

| # | 方法 | 路径 | 说明 |
|---|---|---|---|
| A12 | GET | `/admin/pages/{key}` | 草稿 section 列表 |
| A13 | PUT | `/admin/pages/{key}/sections` | 整页保存草稿（排序、开关、config） |
| A14 | POST | `/admin/pages/{key}:publish` | 发布 → 生成 `PublishVersion` 并切换指针 |
| A15 | POST | `/admin/pages/{key}:reset` | 回滚到上一发布版本 |
| A16 | GET | `/admin/publish/versions` | 发布历史（含操作人、备注） |
| A17 | POST | `/admin/publish/versions/{id}:rollback` | 指定版本回滚 |
| A18 | POST | `/admin/preview-token` | 签发预览 token（前端预览草稿用） |

### 2.3 目录 / 分类法 / 方案 / 站点运营（二期）

| # | 方法 | 路径 | 说明 |
|---|---|---|---|
| A19 | CRUD | `/admin/catalog/products[/{id}]` | 含 variants、specs、attribute values、媒体绑定 |
| A20 | CRUD | `/admin/catalog/categories[/{id}]` | 分类树 + 排序 |
| A21 | CRUD | `/admin/catalog/attributes[/{id}]` | 属性定义（facetable/bucket 策略/单位） |
| A22 ‖ | POST | `/admin/taxonomies/{key}/nodes/{id}:reorder-essentials` | 必备清单排序（顺序即数据） |
| A23 | CRUD | `/admin/taxonomies/{key}/nodes[/{id}]` | 节点、属性值、阅读路径、关联方案 |
| A24 | CRUD | `/admin/bundles[/{id}]` | 方案与模块（含兼容状态、价格状态） |
| A25 | CRUD | `/admin/sites/{id}/sections-schema` | preset 的 SectionTypeSchema 管理（新增 sectionType 的入口） |
| A26 ‖ | POST | `/admin/media` + `POST /admin/media/{id}:verify` | 上传（平台文件中心）+ 核验状态（对应 L-24/L-27） |
| A27 | GET | `/admin/site` | 站点配置（语言、货币、主题令牌、feature flags） |

---

## 3. 非 API 但依赖后端数据

| # | 项 | 现状 | 接后端后 |
|---|---|---|---|
| N1 | `sitemap.xml` | Nitro 路由，demo 构建内联数据 | 改调公开读接口列举 URL（文章/物种/商品/分类），或由后端生成 |
| N2 | `robots.txt` | Nitro 路由，demo Disallow | 按环境生成（生产 Allow + sitemap 指针） |
| N3 | `/image-credits` | 本地静态表 `app/data/image-credits.ts` | 改读 `MediaAsset`（`credit_author/license/source_url`） |
| N4 | JSON-LD（Article/FAQ/Product/Breadcrumb） | 前端组装 | 字段由 P5/P10/P13 提供，前端不改 |

---

## 4. 前后端方法映射（切换可验证）

| 前端调用 | 端点数 |
|---|---|
| `product.list` | P4 |
| `product.getBySlug` | P5 |
| `product.getByIds` | P6（替代客户端过滤） |
| `product.getRelated` | P7 |
| `category.list` / `getBySlug` | P2 / P3 |
| `journal.list` / `getBySlug` / `getSettings` | P9 / P10 / P11 |
| `species.list` / `getBySlug` | P12 / P13 |
| `habitat.list` / `getBySlug` | P14 / P15 |
| `configurator.listModules` / `validate` | P16 / P17 |
| `homepage.getPublished` | P18 |
| `homepage.getDraft/saveDraft/publishDraft/reset` | A12–A15（原型改真接口） |
| `/admin/content` 直连 `$fetch`（3 处） | A1–A10 |
| 商品页「适养物种」反查 | P8（新增） |
| 站点名/语言/货币（硬编码） | P1（新增） |

**已知缺口（必须由后端解决，否则切不了）**：P6、P7、P8、P1、A12–A18。
其余为已有契约的平移。

---

## 5. 每端点验收标准（parity 门禁输入）

| 项 | 要求 |
|---|---|
| 字段 | 与 `shared/types/*` 逐字段一致（camelCase；`json_name` 对齐） |
| 语言 | `?locale=` 协商，缺省站点默认语言；缺该语言值时的回退规则需固定（建议 fallback 到默认语言并标记） |
| 空/缺失 | 资源不存在 → 404（前端转 null）；缺价 → 省略字段（**不得 0**）；空列表 → 200 + `items: []` |
| 分页 | 公开读沿用 `page/pageSize`（上限 48/100 按端点固定）；admin 用 AIP `page_size/page_token` |
| 排序 | `sort=relevance|price_asc|price_desc|newest`；缺价永远最后 |
| facet | 桶由 `AttributeDefinition` 驱动；计数作用域 = 类目 + 搜索；空选项不下发 |
| 可见性 | 只返回 published（+ verified，若站点开启严格模式） |
| 缓存 | 公开 GET 带 `ETag`（hash(publishVersion+locale+site)）+ `Cache-Control: s-maxage`；发布时按站点 purge |
| 错误 | kratos errors + UPPER_SNAKE_CASE；不得把内部错误原文透出 |

---

## 6. 待确认（影响接口形状，开发前需定）

| # | 问题 | 建议 |
|---|---|---|
| Q1 | P18 首页是否直接 hydrate 内联实体（方案 B），还是保留引用 id + 批量端点 | **B**（少往返、SSR 更快；props 形状不变） |
| Q2 | `P12` 是否支持 `productId`/`entrySlug` 过滤（替代客户端反查 chips） | 是，用同一端点加过滤参数，避免多开端点 |
| Q3 | 预览草稿的鉴权：短期 token（A18）还是复用 admin JWT | token（公开站不需要登录态） |
| Q4 | `sort=relevance` 的定义（无搜索词时的默认序） | 显式 `sort_order` 字段（运营可控），不依赖 DB 物理顺序 |
| Q5 | 语言回退策略：缺失该语言字段时是否回退默认语言 | 回退 + 响应带 `localeFallback: true`（可观测） |
| Q6 | `quantity` 上限、`pageSize` 上限等硬限制是否按站点可配 | 一期常量，二期进 preset |

---

## 7. 数量小结

- 公开读：**18** 个端点（含 1 个纯计算 POST），其中 **9 个需要服务端 join**；
- 运营：**27** 组端点（内容 11 / 编排 7 / 目录与分类法 9）；
- 非 API 依赖：4 项；
- **必须新增（前端现在靠客户端硬拼）**：P1、P6、P7、P8、A12–A18。