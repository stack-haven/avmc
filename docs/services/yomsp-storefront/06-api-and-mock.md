# 06 · API 契约与 Mock 规范

> 来源：原规范 §6（业务数据模型与 API 契约）
> **本阶段（当前决定）：后端接口不开发，全部以隔离 Mock 呈现。** 本文档定义契约形状与 Mock 边界，真实 endpoint 列为 Open Items。
> 上游：[04 架构](04-frontend-architecture.md) · 下游：[11 Open Items](11-open-items.md)

---

## 1. 核心实体（前端契约形状）

> 以下为**前端契约建议**，不代表后端已存在这些实体。后端开发时须先审查现有 Go 服务/SaaS 数据模型，已有相近实体应映射复用，**不得为前端重复造域模型**。

```ts
type Currency = 'RUB'

interface Money {
  amountMinor: number       // 最小货币单位（戈比），精度约定由后端定
  currency: Currency
}

interface ProductImage {
  url: string
  alt: string
  width?: number
  height?: number
  role?: 'primary' | 'gallery' | 'detail' | 'diagram'
}

type Availability = 'in_stock' | 'out_of_stock' | 'preorder' | 'unknown' | 'inquiry'

interface ProductVariant {
  id: string
  sku: string
  title: string
  attributes: Record<string, string | number | boolean>
  price?: Money
  availability: Availability
  stockQuantity?: number    // 仅当业务允许公开时才返回/展示
}

interface Product {
  id: string
  slug: string
  name: string
  summary?: string
  description?: string
  categoryIds: string[]
  images: ProductImage[]
  sku?: string
  specs: Record<string, string | number | boolean>
  material?: string
  dimensions?: { lengthMm?: number; widthMm?: number; heightMm?: number }
  variants?: ProductVariant[]
  price?: Money
  availability: Availability
  compatibleProductIds?: string[]
  configurableModule?: boolean
  status: 'draft' | 'published' | 'discontinued'
  updatedAt?: string
}

interface Category {
  id: string
  slug: string
  name: string
  description?: string
  image?: ProductImage
  parentId?: string
}

interface HabitatModule {
  productId: string
  variantId?: string
  quantity: number
  role?: string
  compatibilityStatus: 'verified' | 'requires_review' | 'incompatible' | 'unknown'
  note?: string
}

interface HabitatBundle {
  id: string
  slug: string
  name: string
  summary: string
  description?: string
  targetSpecies?: string[]
  suitabilityNotes?: string
  images: ProductImage[]
  modules: HabitatModule[]
  totalPrice?: Money
  priceStatus: 'exact' | 'estimate' | 'inquiry' | 'unavailable'
  status: 'draft' | 'published' | 'archived'
  updatedAt?: string
}

interface GuideArticle {
  id: string
  slug: string
  title: string
  summary: string
  body: unknown
  coverImage?: ProductImage
  publishedAt?: string
  updatedAt?: string
  authorName?: string
  reviewerName?: string
  sourceReferences?: { title: string; url: string; accessedAt?: string }[]
  relatedProductIds?: string[]
  relatedHabitatIds?: string[]
  status: 'draft' | 'published'
}

interface HomepageSection {
  id: string
  pageKey: 'home'
  slotKey: HomeSlotKey
  sectionType: SectionType
  title?: string
  enabled: boolean
  sortOrder: number
  selectionMode: 'manual' | 'rule_based' | 'collection'
  productIds?: string[]
  categoryIds?: string[]
  habitatIds?: string[]
  guideIds?: string[]
  itemLimit?: number
  startAt?: string
  endAt?: string
  fallbackPolicy: 'hide' | 'show_empty_state' | 'fill_from_rule'
  status: 'draft' | 'published' | 'archived'
  version: number
  config: Record<string, unknown>
}
```

## 2. API 客户端原则（未来接后端时的硬规则）

- 所有 API 调用集中在 `services/` 层；
- 统一 base URL、超时、错误映射、trace/request ID 透传（后端支持时）；
- SSR 与客户端请求使用**一致的数据契约**，避免水合不一致；
- 运行时校验关键响应；schema 不匹配时返回**可观察错误**，不静默强转；
- 区分 404 / 410 / 500 / 超时 / 空列表；
- 列表 API 支持分页、筛选、排序与稳定响应结构；
- **未确认存在的端点不得凭空当成可调用**——先定义接口 + Mock Repository，并在 `docs/api/open-items.md` 记录待确认 endpoint。

## 3. 建议 API 资源（Open Items，未实现）

```text
GET  /api/v1/storefront/homepage
GET  /api/v1/storefront/categories
GET  /api/v1/storefront/categories/{slug}
GET  /api/v1/storefront/products
GET  /api/v1/storefront/products/{slug}
GET  /api/v1/storefront/habitats
GET  /api/v1/storefront/habitats/{slug}
GET  /api/v1/storefront/guides
GET  /api/v1/storefront/guides/{slug}
GET  /api/v1/storefront/configurator/modules
POST /api/v1/storefront/configurator/validate
```

> ⚠️ 以上**仅是建议契约**。`backend-service/proto` 当前只有 `ai / common / evie / packages / platform / version`，**没有 storefront**。不得假设这些 endpoint 已存在。若未来后端已有命名规则，应遵循既有规范并更新本文档。

| # | Open Item | 状态 |
|---|---|---|
| OI-API-1 | storefront 服务是否落在 `backend-service/app/<x>/service` | 未决 |
| OI-API-2 | 使用 Protobuf + HTTP annotations 还是 OpenAPI 直出 | 未决 |
| OI-API-3 | 商品/价格/库存/兼容性是否可复用现有平台实体 | 未决 |
| OI-API-4 | 认证方式（游客可读 vs 需要 token） | 未决 |
| OI-API-5 | 分页/筛选/排序参数规范 | 未决 |
| OI-API-6 | 首页运营配置的 Draft/Preview/Publish 是否入平台审计 | 未决 |

## 4. Repository 适配层

必须定义（本阶段只实现 Mock）：

| Repository | 责任 | Mock 实现 |
|---|---|---|
| `ProductRepository` | 列表/详情/筛选/推荐 | `MockProductRepository` |
| `CategoryRepository` | 分类树/详情 | `MockCategoryRepository` |
| `HabitatRepository` | 方案列表/详情 | `MockHabitatRepository` |
| `GuideRepository` | 指南列表/详情 | `MockGuideRepository` |
| `HomepageRepository` | 首页 Section 配置 + Draft/Preview/Publish（localStorage） | `MockHomepageRepository` |
| `ConfiguratorRepository` | 标准模块 + 兼容性校验 | `MockConfiguratorRepository` |

- 开发阶段实现 `MockXxxRepository`；接后端后实现 `ApiXxxRepository`。
- 页面只依赖接口，不依赖具体实现。
- 切换通过环境配置或依赖注入（`app/plugins/repositories.ts`），**不能散落在页面里的 `if (demo)` 判断**。

### 4.1 方法签名建议（Mock 与 Api 必须一致）

```ts
interface ProductRepository {
  list(params: ProductListParams): Promise<Page<Product>>
  getBySlug(slug: string): Promise<Product | null>
  getByIds(ids: string[]): Promise<Product[]>
  getRelated(productId: string, limit?: number): Promise<Product[]>
}

interface ProductListParams {
  categorySlug?: string
  sort?: 'relevance' | 'price_asc' | 'price_desc' | 'newest'
  filters?: Record<string, string | string[]>
  page?: number
  pageSize?: number
}

interface Page<T> {
  items: T[]
  total: number
  page: number
  pageSize: number
}
```

> 返回 `null` 而不是抛 404 异常：让页面能明确渲染"商品不存在"并返回 HTTP 404（见 [07 §2](07-seo-geo.md#2-技术基础清单)）。

## 5. Mock 数据要求

### 5.1 放置与隔离

- Mock 数据放在 `app/services/mock/fixtures/`；
- **不生成**虚假的评价、评分、销量、促销倒计时或库存紧张提示；
- 图片若为占位图**必须明确标识**（文件名 + alt 含"示例"），不得用占位图冒充真实商品图。

### 5.2 Demo 标识（双重保险）

1. **数据层**：每个 Mock 实体带 `isDemo: true` 标记；`app/components/layout/DemoBanner.vue` 在 `NUXT_PUBLIC_DEMO_MODE=true` 时全站可见（已实现）。
2. **展示层**：价格旁展示 `≈` 或"示例价格"提示；商品卡/方案卡显示 Demo 徽标；`/cart` 页面固定提示"演示功能，不会创建真实订单或发起支付"。

### 5.3 生产隔离

- 生产 build 默认**不允许**意外加载 Mock；
- Mock 模块通过动态 import + `import.meta.dev` 守卫隔离，避免进入主 bundle；
- CI 增加构建产物检查：生产产物中不得包含 `fixtures` / `mock-repository` 标识；
- `.env.example` 中 `NUXT_PUBLIC_DEMO_MODE=false` 为生产默认值。

### 5.4 Mock 数据内容原则（避免真实性违规）

| 可以做 | 不可以做 |
|---|---|
| 用 `Пример товара 1`（示例商品 1）命名 | 用看起来像真实品牌的商品名 + 真实感价格 |
| 价格标注"示例"或留空显示"价格待确认" | 展示可能被误认为真实的卢布价格 |
| 使用中性占位图并标注 | 使用真实爬宠照片冒充自有商品 |
| 标注"示意图"的方案图 | 把未验证组合说成"适合某物种" |

## 6. Mock 数据规模建议（足够驱动 UI，但不制造幻觉）

| 实体 | 数量 | 说明 |
|---|---|---|
| Category | 6–8 | 覆盖饲养箱、底材、躲避、攀爬、照明、加热、水盆、配件 |
| Product | 24–36 | 每分类 3–5 个；含 1–2 个 `availability: 'inquiry'`、1 个 `out_of_stock`、1 个多变体 |
| HabitatBundle | 4–6 | 含 1 个 `priceStatus: 'inquiry'`、1 个 `requires_review` 模块 |
| GuideArticle | 6–8 | 覆盖新手/尺寸/通风/材质/组合/维护主题（内容标注"示例内容"） |
| HomepageSection | 8 | 与 8 个 Slot 一一对应，含 1 个 `disabled` 用于验证兜底 |

## 7. 本阶段不做（明确边界）

- 不新增 `backend-service` 代码、proto、Ent schema、迁移；
- 不写真实的 `ApiXxxRepository` 网络实现（只留骨架与类型）；
- 不实现购物车下单、支付、账户、订单；
- 不实现真实搜索（搜索入口先隐藏）；
- 不实现富文本编辑器（指南内容用结构化 Markdown/MDC + 人工校对）。

## 8. 验收要点

- [ ] 页面中无 `fetch(` 直接调用、无硬编码 URL
- [ ] 页面与组件中 grep 不到 `localStorage`
- [ ] `contracts.ts` 中每个 Repository 都有 Mock 实现通过类型检查
- [ ] 生产 build 产物无 Mock 痕迹（CI 断言）
- [ ] Demo 标识在首页、商品页、方案页、购物车均可见
- [ ] 空列表 / 404 / 超时 三种状态可手动触发验证