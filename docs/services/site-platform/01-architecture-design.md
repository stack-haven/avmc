# Site Platform · 架构设计（v1 提案）

> 状态：Explore 产出。§8 决策点批复前不写代码。
> 约束来源：`0-1`（产品层约束）、`4-1`（接入规范：proto 模式/类型流/listing/buf.validate/检查清单）、
> `.agents/RULES.md`（API 与 DB 硬规则）、`0-3`（后端底座 ADR）。

---

## 1. 设计目标与反目标

### 目标

1. **一个服务承载 N 个站点**：新增一个站点的边际成本 = 建站点 + 选 preset + 录数据，**零代码**；
2. 契约唯一：proto 为事实源，YOMSP 前端切换只换 base URL（Repository/页面不动）；
3. 通用化落在**数据模型与校验**，不落在「万能表」：实体仍是真实表，只有**属性**与**关系**是通用机制；
4. 演化可行：preset 版本化、block schema 版本化、proto 加法演进、发布版本可回滚。

### 反目标（明确不做）

- 不做通用 CMS 全家桶（工作流引擎、插件市场、可视化页面搭建器、媒体库管理套件）；
- 不做 EAV 万能实体表（`entity(type, attrs jsonb)` 那种），见 §3.1 护栏；
- ~~不做交易（订单/支付/库存/优惠），只留 seam~~ → 交易/身份/隐私已进入需求梳理（见 `03`），
  本期范围 = 账户 + 购物车/结账/订单 + 履约跟踪 + 隐私合规；库存中心/促销引擎仍不做；
- 不做 AI 生成（GEO Engine 的职责）；
- 不做多语言翻译工作流（只做多语言**存储与校验**）。

---

## 2. 通用化策略：把「爬宠专属词汇」从模型里拿掉

当前前端已冻结的四个功能域，抽取成四组通用概念：

| YOMSP 现状（具体词） | 通用模型 | 换站点时怎么变 |
|---|---|---|
| 分类：terrarium/substrate/… | `Category`（树） | 数据 |
| 商品 specs「Объём/Мощность」参与 facet | `AttributeDefinition` + 类型化值 | 数据（属性定义） |
| 物种（守宫/陆龟）、类群、护理参数、必备槽位 | `TaxonomyDefinition` + `TaxonNode` + 类型化属性 + 有序关系 | 数据（如「犬种」「水草」「车型」） |
| 内容分类/文章/设置、块模型 | `ContentCategory` / `ContentEntry` / `ContentSettings` + 版本化 block JSON | 数据 |
| 首页 Slot/SectionType、`config.tone` | `Page` / `PageSection` / `SectionTypeSchema`（preset 提供） | preset |
| 成品方案 bundles | `Bundle` + `BundleModule` | 数据 |
| 照片「示例/待核验」 | `MediaAsset.verification_status` + 授权字段 | 流程数据 |

**关键判断**：通用化的边界在「结构」，不在「语义」。后端不知道「守宫」「UVB」是什么，
它只知道「某 taxonomy 定义下，某节点按 order 关联了 N 个商品，每个带 role 与理由文本」。

---

## 3. 领域模型

### 3.1 全局护栏（防过度抽象）

1. **属性值用类型化列**，不用 `jsonb` 大杂烩：
   `AttributeValue { attribute_id, owner_type, owner_id, num_value, text_value, enum_value, bool_value }`，
   每个属性只填一列（DB CHECK 约束），可按数值建索引 → facet 与过滤是 SQL 而非内存扫描。
2. **实体保留真实表**：商品就是 `product`，不是 `entity`；内容就是 `content_entry`。
3. **两级通用**：属性系统（product / taxon 共用）+ 有序关系系统（taxon→product、taxon→entry、entry→entry）。
   除此之外不引入第三种通用机制。
4. **站点（site）是产品内的一等实体**，所有业务表带 `tenant_id + site_id` 双键，缓存与 CDN 也按双键。

### 3.2 站点与语言

```text
Site(id, tenant_id, key, name L, status, default_locale, locales[], currency, timezone,
     preset_key, preset_version, theme_tokens jsonb, feature_flags jsonb)
SiteDomain(site_id, host, is_primary, locale_override)      // Host 解析站点与语言
SiteMember(site_id, subject_type, subject_id, role_key)      // 运营可访问性（见 D6）
```

- `L` = `jsonb {locale: text}`，locale 集合由站点声明（YOMSP: ru/zh/en），**不写死三语**；
- 校验：`required_locales` 内的语言缺失即写入失败（后端守卫，不靠前端）；
- 站点解析：`Host` → `SiteDomain`；无匹配返回 404（不做「默认站点」兜底，避免串站）。

### 3.3 目录（Catalog）

```text
Category(id, site_id, parent_id, slug, name L, summary L, image, sort_order, status)
AttributeDefinition(id, site_id, scope[product|taxon], key, label L, value_type[text|number|enum|bool],
                    unit, facetable, bucket_strategy[auto|fixed|list], buckets jsonb, min/max, sort)
Product(id, site_id, name L, summary L, description L, brand, sku,
        price_minor bigint, currency, compare_at_minor, availability enum, status, updated_at)
ProductCategory(product_id, category_id, sort_order)
ProductAttributeValue → AttributeValue(owner_type=product)
ProductSpec(product_id, sort_order, key L, value L)          // 展示用规格（与 facet 属性分离）
ProductVariant(id, product_id, sku, attributes jsonb, price_minor, availability)
ProductMedia(product_id / bundle_id / entry_id / taxon_id, media_id, role, sort_order)
```

> **为什么 spec 与 attribute 分开**：现状前端把「Объём」既当展示规格又当筛选依据。
> 通用化后：展示写 `ProductSpec`（自由文本、三语），筛选写 `AttributeDefinition + AttributeValue`（类型化、可索引）。
> 两者可同源录入，但**语义不同**——否则换站点时展示字段会污染 facet。

商品列表查询通用化（替代前端硬编码桶）：

1. 取当前类目作用域内 `facetable=true` 的属性定义；
2. 按定义的 `bucket_strategy` 生成桶（auto=等宽/分位，fixed=显式边界，list=枚举值）；
3. `GROUP BY` 类型化值列 → 计数；作用域 = 类目 + 搜索（不随自身选择抖动，保持现有语义）。

### 3.4 分类法（Taxonomy）——物种、犬种、水草、车型都能装

```text
TaxonomyDefinition(id, site_id, key, label L, slot_vocabulary jsonb, level_vocabulary jsonb)
TaxonGroup(definition_id, slug, name L, sort_order)
TaxonNode(definition_id, group_id, slug, name L, latin_name, summary L, image,
          level[beginner|intermediate|advanced], status, review_status)
TaxonAttributeValue → AttributeValue(owner_type=taxon)     // 护理参数 = 属性（区间/布尔/枚举）
TaxonProductLink(taxon_id, product_id, slot_key, sort_order, reason L)   // 有序必备清单
TaxonEntryLink(taxon_id, entry_id, kind[reading_path|related], sort_order)
TaxonBundleLink(taxon_id, bundle_id)
```

- `slot_vocabulary` 让「箱体→加热→UVB→垫材→躲避→水」成为**站点数据**而不是代码常量；
- 护理参数（温度区间、湿度区间、UVB）用 `AttributeValue` 的 num/bool 列表达，
  `source_refs jsonb` 与 `review_status` 挂在节点上 → 直接承载 L-20/L-28 的合规门禁；
- 关系表全部带 `sort_order`：**顺序是数据**（必备清单顺序、阅读路径顺序都不能按 id/时间排）。

### 3.5 内容

```text
ContentType(id, site_id, key[article|page], block_schema_version, presentation[task|knowledge])
ContentCategory(id, site_id, parent_id, slug, name L, description L, presentation, sort_order)
ContentEntry(id, site_id, type_id, category_id, slug, title L, excerpt L,
             body jsonb /* RawContentBlock[] */, faq jsonb, source_refs jsonb,
             author_name, reviewer_name, review_status, published_at,
             featured, status, search_blob jsonb)
ContentEntryRelation(entry_id, target_type[product|bundle|taxon|entry], target_id, kind)
ContentSettings(site_id /* 单行 */, jsonb)
```

- block 模型沿用前端已冻结的 **InlineSpan 结构化模型**（零 HTML/XSS 面），后端只存储与透传，不渲染；
- `block_schema_version` 允许 block 类型演进（渲染器支持 N 与 N-1）；
- `review_status` + `reviewer_name` 把「示例 → 已核验」变成数据状态，公开读只返回 `published && review_status=verified`（站点可配）。

### 3.6 展示编排与发布

```text
Page(id, site_id, key[home|catalog|taxonomy_index], route_pattern, title L, status)
PageSection(id, page_id, slot_key, section_type, title L, intro L, enabled, sort_order,
            selection_mode[manual|rule|collection], item_limit, refs jsonb,
            config jsonb, status, version)
SectionTypeSchema(id, preset_key, preset_version, section_type, config_schema jsonb)  // JSON Schema
SitePreset(key, version, label, section_types[], attribute_templates jsonb, taxonomy_templates jsonb)
PublishVersion(id, site_id, channel[production|preview], version_no, created_by, created_at,
               note, snapshot jsonb)
```

- 后端**不硬编码** `hero_banner`/`species_strip` 等类型，只按 preset 里的 `config_schema` 校验 `config`；
  → 前端新增 sectionType = 出 preset 新版本，后端无需改代码（这是本设计最重要的一条复用点）；
- 公开读走 `PublishVersion` 指针：编辑写 draft 行，发布生成快照并切换指针，**天然支持回滚**；
- 预览：admin 签发的短期 `preview_token` 读 preview 版本，公开 CDN 不缓存带 token 的响应。

### 3.7 媒体与合规

```text
MediaAsset(id, site_id, file_id /* 平台文件中心 */, kind[image|video], width, height,
           alt L, caption L, credit_author, license, source_url,
           verification_status[pending|verified|rejected], verified_by, verified_at,
           contact_sheet_ref)
```

直接编码 YOMSP 照片门禁（L-24/L-27）：公开读只返回 `verified`；`pending` 用于占位渲染决策，
不在前端硬编码「哪些物种没有照片」。这条对其他站点同样成立（法律与真实性问题通吃）。

---

## 4. API 分层

### 4.1 两个面，一套 proto 目录（`4-1` 合一模式）

```text
proto/sites/storefront/v1/    # 公开读：无鉴权、可 CDN、只读 published
proto/sites/admin/v1/         # 运营：JWT + 权限点 + 审计，读写 draft
proto/sites/service/v1/error_reason.proto
```

- 路径：`/sites/v1/storefront/...`、`/sites/v1/admin/...`（`4-1` 服务前缀规则）；
- 公开读的列表契约**保留现有前端形状**（`items/total/page/page_size/facets`），
  因为它是已冻结的 CDN 可缓存契约；admin 侧严格用 AIP（`page_size/page_token/filter/order_by` + `listing.Option`）。
  ⚠️ 这是对 `4-1` 的一处**有意偏离**，需架构师确认（D5）。

公开读（通用，与站点无关的命名）：

| 端点 | 对应现有前端能力 |
|---|---|
| `GET /site`（Host 解析） | 站点信息/语言/主题 |
| `GET /navigation` | 导航（现为硬编码路由，后端化后可按站点配） |
| `GET /pages/{key}` | 首页 sections |
| `GET /catalog/categories` `/catalog/products` `/catalog/products/{slug}` | 目录、搜索、facet、排序、分页 |
| `GET /content/entries` `/content/entries/{slug}` `/content/settings` | 知识库列表/详情/设置 |
| `GET /taxonomies/{key}` `/taxonomies/{key}/{slug}` | 物种列表/档案（含 join） |
| `GET /bundles` `/bundles/{slug}` | 成品方案 |
| `GET /configurator/modules` · `POST /configurator/validate` | 配置器 |

admin 侧：每个资源 CRUD + `:publish` / `:unpublish` / `:reorder` / `:verify`（媒体核验）+ 发布版本列表与回滚。

### 4.2 类型流与分层（`4-1` 强制）

- `service`（薄适配，提取 tenant_id/site_id）→ `biz`（编排/校验/权限）→ `data`（ent 与 proto 互转）；
- 三层签名全部用 proto 消息类型；转换函数只在 `data`；`biz` 不 import `ent/gen`；
- 站点作用域：`site_id` 从路径 + `SiteMember` 校验得出，**不接受客户端传 tenant_id**；
- 列表统一 `listing.Option`；筛选在 service 层合并进 filter 字符串。

### 4.3 缓存与失效

- 公开读响应带 `ETag = hash(publish_version + locale + site)`、`Cache-Control: s-maxage`；
- 发布动作触发按站点前缀的 CDN purge（通过平台 webhook/通知）；
- 服务内 in-process TTL 缓存（站点配置、preset schema）——不提前引入 redis。

---

## 5. 与 YOMSP 前端的映射（换 base 即可切）

| 前端 Repository | 后端资源 |
|---|---|
| `ProductRepository.list`（含 q/sort/facet） | `/catalog/products` |
| `CategoryRepository` | `/catalog/categories` |
| `ContentRepository`（Journal） | `/content/entries` |
| `SpeciesRepository` | `/taxonomies/species` |
| `HabitatRepository` | `/bundles` |
| `HomepageRepository` | `/pages/home` |
| `ConfiguratorRepository` | `/configurator/*` |
| `/admin/content` 原型（localStorage） | `/sites/v1/admin/content/*` |

切换门禁：golden parity（demo 响应快照 ↔ 后端响应逐字段 diff）进 CI，见 `yomsp-storefront/12` §4。

---

## 6. 演化规则（可复用可持续）

| 维度 | 规则 |
|---|---|
| API | v1 内只做加法；`buf breaking` 进 CI，禁止 `--force`；字段废弃先保留一个大版本 |
| 新 sectionType | 出 preset 新版本 + 前端组件；后端零改动 |
| 新 taxonomy（犬种/水草） | 建 definition + 属性模板 + 内容；后端零改动 |
| 新站点 | 建 site + 选 preset + 录数据；后端零改动 |
| 新属性/新 facet 维度 | 建 `AttributeDefinition`；后端零改动 |
| block 新类型 | `block_schema_version` +1，渲染器兼容 N/N-1 |
| 交易能力（后续） | 新表 + 独立 service 面（`/sites/v1/commerce/*`），不动现有读接口 |
| 对外集成（搜索/邮件/AI） | `OutboxEvent` 表 + 消费者；写入侧不阻塞 |

### 6.1 通用性的验收方式（最重要的指标）

**站点 #2 上线**（不同细分领域，如爬宠以外的宠物用品）：

- 允许的改动：新建 site、选 preset、录数据、主题令牌与文案；
- 不允许的改动：后端代码、proto、前端组件（除主题/文案/路由标签）；
- 若需要改代码 → 说明抽象失败，登记设计债并回填到 §3。

---

## 7. 阶段计划（约 6–8 周，1 人 + 评审）

| 阶段 | 内容 | 出口门禁 |
|---|---|---|
| P0 骨架与登记 | `app/sites/service` 骨架（对齐 evie 结构）、proto 骨架、Atlas、mixin（Tenant/Site/L/Money/Audit）、CI 接入、产品登记与菜单 seed 空壳 | `make check`/`contract-check` 绿；双租户双站点隔离测试 |
| P1 站点与媒体 | Site/SiteDomain/SiteMember/Locale 校验/MediaAsset（含核验状态）+ 平台文件中心对接 | Host 解析 + 语言缺省用例；越权 403 |
| P2 目录通用化 | Category/Product/Variant/Attribute/Spec + 动态 facet + 搜索 + 分页排序 | facet 桶由定义驱动（YOMSP 桶经 seed 复现，parity 绿） |
| P3 内容 | ContentType/Category/Entry/Settings + block 存储 + review_status | journal parity；review 门禁生效（未核验不可公开） |
| P4 分类法 | TaxonomyDefinition/Group/Node/属性/有序关系 | species parity（essentials 顺序、readingPath 顺序） |
| P5 编排与发布 | Page/Section/SectionTypeSchema/Preset/PublishVersion/回滚/预览 token | 发布/回滚/预览 E2E；非法 config 被 schema 拦截 |
| P6 运营后台 | admin CRUD + 权限点 + 审计 + `/admin/content` 接真 API | 越权矩阵；审计记录可查 |
| P7 切换与站点 #2 | YOMSP 换 base + parity 报告 + 站点 #2 onboarding 演练 | 站点 #2 零代码上线（或据实登记失败点） |

---

## 8. 决策点（requires-confirmation）

| # | 决策 | 建议 | 确认对象 |
|---|---|---|---|
| D1 | 产品化落点：新建 `app/sites/service`；proto `proto/sites/{storefront,admin}/v1`；登记 `docs/services/README.md` + `0-1` 产品表 | ✅ | 架构师 |
| D2 | 命名：产品名 **Site Platform** / 服务短名 **`sites`**（备选 `sitekit`、`storefront`） | ✅ `sites` | 产品负责人 |
| D3 | 站点是产品内实体（tenant → site 两级隔离），而非「一个站点一个租户」 | ✅ | 架构师 + 产品 |
| D4 | 通用化深度：实体用真实表、仅属性与关系通用（拒绝 EAV 万能表） | ✅ | 架构师 |
| D5 | 公开读保留前端冻结的列表形状（**偏离** `4-1` 的 AIP 列表规范），admin 侧严格 AIP | ✅ 偏离，需书面认可 | 架构师 |
| D6 | 站点级访问控制：`SiteMember` + 平台权限组（站点菜单/权限点按站点实例化） | ✅ | 架构师 + 安全 |
| D7 | 发布模型：draft 行 + `PublishVersion` 快照 + 指针切换（不做逐条审批流） | ✅ | 产品 |
| D8 | 内容合规门禁：`review_status` 决定公开可见性（默认 `verified` 才公开，可按站点放宽） | ✅ | 产品 + 法务 |
| D9 | preset 校验为唯一校验源：`config_schema`(JSON Schema) 落库，protovalidate 做字段级校验 | ✅ | 架构师 |
| D10 | ~~首期不做 commerce，仅留 Outbox/Idempotency seam~~ → 已升级为在范围，需求与决策点见 `03` §9（Q1–Q12） | 需重新确认 | 产品 + 架构师 |

---

## 9. 预留 seam（后续阶段，不实现）

- **交易**：已进入本期范围，模型见 `03` §6（Customer/Address/Order/OrderItem/OrderEvent/Shipment/ConsentRecord/OutboxEvent）；
- **库存**：`InventoryItem` 表 + 发布时校验；
- **会员/多语言 URL 策略**：站点级配置项；
- **搜索**：先 PG trigram/GIN；超阈值再上 ES，通过 Outbox 同步（写入侧不变）；
- **AI 内容管线**：GEO Engine 通过 admin API 写入 draft + `review_status=pending`。

---

## 10. 风险与对策

| 风险 | 对策 |
|---|---|
| 过度抽象（属性系统吃掉一切） | §3.1 四条护栏 + 站点 #2 验收 |
| preset 与前端组件漂移 | preset 版本 + 前端按版本渲染 + E2E 契约测试 |
| 双源校验（后端 JSON Schema vs 前端 Zod） | D9：后端为唯一源，前端 Zod 逐步退役 |
| 多租户+多站点隔离错误 | 双键强制 + ent privacy + 隔离 E2E（两租户交叉读写） |
| 公开读性能 | 类型化属性列索引 + 物化 `search_blob` + ETag/CDN |
| 与 GEO 职责冲突 | README §定位：生产 vs 承载，边界写入两产品文档 |