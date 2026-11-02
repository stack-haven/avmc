# 12 · 后端接口开发计划（v2：已由通用设计吸收）

> **v2 变更（2026-11）**：用户要求后端做成**可复用的通用产品服务**（未来还有多个同类站点），
> 因此 v1 的「YOMSP 专属服务」方案作废，通用架构见
> [`docs/services/site-platform/01-architecture-design.md`](../../site-platform/01-architecture-design.md)。
> 本文保留 YOMSP **站内落地**部分：契约迁移策略、golden parity、切换与退役、YOMSP 专属决策（原 D4/D8 → 通用 D5/D8）。
> 服务落点、proto 目录、表结构、facet 通用化、preset 校验等以通用设计为准。
>
> 状态：**Explore 产出**。本文与通用设计的决策点批复前不写任何 backend-service 代码。
> 输入：`06-api-and-mock.md` §3 建议契约、storefront-service 的 Repository 契约与 Nitro demo API（= 冻结的契约快照）、
> `05-content-ops.md` §6/§7、`feature-requirements-review-knowledge-species.md` §F、`11-open-items.md` L-20/26/27/28。
> 决策分级依据：`.agents/AGENTS.md` §Agent 决策权限分级；§2 全部为 requires-confirmation，需逐条批复。

---

## 1. 目标与非目标（YOMSP 视角）

### 目标（通用服务已定，此处是 YOMSP 站点的接入目标）

1. 公开站 SSR 的**唯一真实数据源**：catalog / journal / species / habitats / homepage / configurator 六组读接口；
2. 运营侧 CRUD：先内容三件套（分类/文章/设置），后 catalog/species/habitats/homepage，替代 `/admin/*` 原型与 git 种子数据；
3. **proto 为契约唯一事实源**；前端零重写切换（只换 `api-client.ts` 的 base，Repository 与页面不动）；
4. 切换有门禁：demo ↔ 后端 **golden parity 测试**全绿才允许切 base。

### 非目标（本计划不含）

- 购物车 / 订单 / 支付 / 账户（commerce 阶段，单独立计划）；
- 站内全文搜索（L-22）、RSS（L-23）、`llms.txt`（L-21）；
- 真实商品/物种照片与内容事实核验（L-20/27/28 属内容线，与接口线并行）。

---

## 2. 必须先确认的决策点（requires-confirmation）

| # | 决策 | 建议默认值 | 确认对象 |
|---|---|---|---|
原 v1 的 D1–D8 已上移/合并为通用设计的 D1–D10（服务落点、租户与站点两级隔离、认证复用、类型策略、
多语言存储、媒体与文件中心、阶段范围、内容合规门禁、preset 校验、commerce 延后）。
YOMSP 侧只剩一个专属项：

| # | 决策 | 建议 | 确认对象 |
|---|---|---|---|
| Y1 | YOMSP 作为 **site #1** 接入：`site.key=yomsp`、locales `[ru,zh,en]`（ru 默认）、currency RUB、preset `storefront-basic@1`；种子数据默认 draft，经 L-20 核验后逐篇 publish | ✅ | 产品负责人 |

---

## 3. 目标架构（产品层约定，见 `0-1` §产品层）

```text
backend-service/
  app/yomsp/service/
    cmd/server/            # kratos bootstrap + wire
    internal/
      service/             # proto 实现（storefront 匿名 / admin 鉴权）
      biz/                 # usecase：查询语义、facet、join、发布状态机
      data/                # ent repository + 缓存 + 文件中心客户端
        ent/schema/        # 产品自有数据模型
      conf/                # conf.proto
  proto/yomsp/
    storefront/v1/         # common catalog content species habitat homepage configurator
    admin/v1/              # content catalog species habitat homepage
    service/v1/            # error_reason
```

- HTTP 路径沿用 evie 约定：`/yomsp/v1/storefront/...`、`/yomsp/v1/admin/...`；
- 产品服务**不自管**租户/用户/认证/会话：JWT 验签、租户注入、操作日志（admin 写）全部复用中台中间件；
- 缓存：一期 in-process TTL + `ETag`；压测不达标再引 redis（避免提前基础设施化）。

### 3.1 Ent schema 清单（一期+二期）

| 实体 | 关键字段 / 边 | 备注 |
|---|---|---|
| Category | slug 唯一、name/summary L、sortOrder | |
| Product | slug、name/summary/description L、sku、material L、dimensions、price(int64 minor+currency)、availability enum、status、updatedAt | specs = JSONB `[{key:L,value:L}]` |
| ProductVariant | sku、title L、attributes JSONB、price、availability | edge → Product |
| TaxonGroup | slug、name L | |
| Species | slug、commonName/scientificName、groupSlug edge、careLevel enum、adultSize/lifespan/diet/activity L、temp/humidity 区间、uvbRequired、summary L、image 可空、status | |
| SpeciesEssential | edge → Species/Product、slot enum、order int、reason L | 有序必备清单 |
| ContentCategory | slug、name/description L、presentation enum、sortOrder | |
| Article | slug、title/excerpt L、body JSONB（RawContentBlock[]）、faq JSONB、refs JSONB、speciesSlugs、relatedProductIds、relatedArticleSlugs、featured、status、publishedAt | blocks 原样存 span 模型，不在后端做 HTML |
| ContentSettings | 单例行（listPageSize、开关组、disclaimerKey…） | §F 契约 |
| HabitatBundle | slug、name/summary/description L、targetSpecies L[]、notes L、priceStatus enum、totalPrice | modules = edge(HabitatModule) |
| HabitatModule | edge → Product、quantity、role L、compatibilityStatus enum、note L | |
| HomepageSection | slotKey、sectionType、title L、enabled、sortOrder、selectionMode、ids JSONB、itemLimit、config JSONB（含 tone）、status、version | 校验见 05 §7 |

混入 mixin：`LJSONB`（D5）、`Money`、`Audit`（created/updated by+at、published_at、version）、`Tenant`（D2）。

### 3.2 查询语义移植（parity 的重点）

`server/utils/catalog-query.ts` 的语义整体移植到 biz，**不允许两边漂移**：

- 分页上限 48、缺省 12；排序四值（relevance/price_asc/price_desc/newest，缺价永远最后）；
- 搜索 = 当前语言 name/summary/specs 值子串；
- facet 桶定义（price 4 桶 / volume 3 桶 / power 3 桶）为后端常量，计数作用域 = 分类 + 搜索；
- species facet = essentials 反查；非法参数回落默认而非报错。

桶定义与语义写入 `docs/services/yomsp-storefront/13-catalog-query-semantics.md`（P1 产出），前端 demo 与后端共同引用该文档做 parity。

---

## 4. 契约迁移策略（前端零重写）

1. **冻结**：脚本导出 demo API 16 路由 × 3 语言 = golden JSON，落 `storefront-service/tests/contract/golden/`（含 facets/joins/settings）；
2. **镜像**：proto 字段与 golden 一一对应（camelCase json_name、同枚举字符串、同分页结构 `{items,total,page,pageSize,facets}`、同 null 语义：缺资源 null、缺价缺省）；
3. **parity**：`tests/contract/parity.spec.ts` 逐字段 diff 后端响应 vs golden（白名单忽略 `updatedAt` 等易变字段）；进 CI；
4. **切换**：`NUXT_PUBLIC_API_BASE` / `runtimeConfig.apiBaseUrl` 换 base；`__DEMO_API__` 机制保留（离线 demo 构建继续可用）；
5. **退役**：生产稳定一个迭代后，按 L-26 清单退役 `/admin/*` 原型对 localStorage 的依赖；demo 种子数据仅存于 demo 构建。

`buf breaking` 自 P0 起进 CI（`make contract-check`），禁止 `--force`。

---

## 5. 阶段与清单

> 每阶段入口：§2 相关 D 已批复 + `4-6` 标 `[~]`；出口：`make check && make contract-check && go test ./...` 过覆盖率门禁 + 前端对应 E2E 换 base 后全绿 + 文档同步（06/10/11、4-6/4-7 `[x]`）。

### P0 骨架与基础设施（2–3 人日）

- [ ] 按 evie 模板建通用服务骨架（目录/命名以 `site-platform/01` §8 D1/D2 批复为准）
- [ ] proto 骨架 + `error_reason.proto` + 接入 buf gen（含 TS gen）
- [ ] 产品登记：`0-1` 产品表 + 产品注册中心 seed（菜单/权限空壳）
- [ ] Atlas 迁移初始化 + Tenant/Site/L/Money/Audit mixin
- [ ] CI 覆盖 yomsp：import-boundary / coverage / contract-check / http-convention
- [ ] `4-6`/`4-7` 新增「YOMSP Storefront」章节 `[~]`
- 验收：服务可启动；`make check` 绿；空迁移可回放。

### P1 Catalog 读接口（3–4 人日）

- [ ] proto：ListCategories / GetCategoryBySlug / ListProducts(q+facets) / GetProductBySlug / RelatedProducts
- [ ] ent：Category / Product / ProductVariant / AttributeDefinition / AttributeValue / ProductSpec
- [ ] biz：通用 facet（由属性定义驱动；YOMSP 桶经 seed 复现）+ parity 单测
- [ ] service：HTTP 映射、缓存头、公开限流
- [ ] seed：`server/data/catalog.ts`（8 分类 / 35 商品）三语导入脚本
- 验收：catalog golden parity 全绿；storefront `catalog-filters.spec.ts` 换 base 全绿。

### P2 Content 读接口（2–3 人日）

- [ ] proto：ListJournal / GetArticle / GetContentSettings
- [ ] ent：ContentCategory / Article / ContentSettings
- [ ] biz：join（relatedArticles/relatedProducts/settings）、blocks 原样透传
- [ ] seed：24 篇文章 + 3 分类 + settings（状态按 D8）
- 验收：journal parity 全绿；JSON-LD 所需字段齐；`content-species.spec.ts` journal 部分换 base 绿。

### P3 Species / Habitat / Homepage / Configurator 读接口（3–4 人日）

- [ ] proto：ListSpecies / GetSpecies（join essentials/readingPath/relatedArticles）、ListHabitats / GetHabitat、GetHomepageSections(published)、Configurator modules + Validate
- [ ] biz：configurator 校验规则移植（兼容矩阵语义）
- [ ] seed：19 物种 / 5 类群 / 9 方案 / 9 homepage sections
- 验收：species/habitats/homepage/configurator parity 全绿；`species-expansion.spec.ts` 换 base 全绿。

### P4 内容运营 CRUD（4–5 人日，二期起点可并行）

- [ ] proto admin：ContentCategory / Article / ContentSettings CRUD + draft→publish + 版本号
- [ ] 权限点注册（YOMSP 运营菜单）+ 操作日志接入
- [ ] `/admin/content` 原型接真实 API（执行 L-26 清单）
- [ ] 发布门禁：L-20 核验状态字段（reviewed_by/at）进入 Article
- 验收：admin 原型 E2E（真实 API 版）绿；越权用例 403；buf breaking 零漂移。

### P5 其余运营 CRUD（4–6 人日）

- [ ] admin catalog（含 variants/specs）、species（essentials 排序编辑）、habitats、homepage sections
- [ ] homepage config 校验：05 §7 的规则以 **protovalidate 为源**，前端 Zod 退役或改为生成
- 验收：运营全流程 E2E；schema 非法配置被拦截且可观察（05 §7 验收要点）。

### P6 切换与退役（2 人日）

- [ ] 生产 base 切换；parity 报告归档进发布记录
- [ ] demo 构建保留策略文档化；L-25 301 清单落点（edge/nginx）确认
- [ ] 文档收口：06 §3「建议」改「已实现」；`10-delivery-plan.md` Gate 5 状态更新；11 增补后端 open items
- 验收：生产 SSR 全路由 200；check:demo 仍绿（demo 构建独立）。

**合计约 20–27 人日**（不含 commerce 三期）。

---

## 6. 风险与对策

| 风险 | 对策 |
|---|---|
| facet/搜索语义双源漂移 | §3.2 语义文档 + golden parity 进 CI |
| L 字段检索/排序性能 | JSONB 生成列 + ru 函数索引；列表只取所需语言投影 |
| Money 精度 | int64 minor 统一 + protovalidate `>0`；禁止 float |
| homepage config 校验双维护 | P5 起 protovalidate 为源 |
| 物种/护理内容合规 | 发布状态机 + reviewed 字段（D8/L-20），接口层只暴露 published |
| 文件中心依赖未就绪 | P4 前验证 `file.proto` 能力；不就绪则 admin 图片暂存静态目录并登记 open item |

## 7. Open Items 映射与新增

> 通用设计侧新增：L-32（站点解析策略 Host vs header）、L-33（站点级权限粒度）、
> L-34（站点 #2 候选与 onboarding 演练时间）、L-35（commerce seam 与平台配额计量口径）。


- L-20 → D8 / P4 发布门禁；L-26 → P4；L-27/L-28 内容线并行不阻塞接口；
- 新增 L-30：golden 快照维护责任与更新流程（demo 契约变更必须同步 golden + proto）；
- 新增 L-31：YOMSP 运营菜单/权限点清单（P4 输入，需产品确认命名与粒度）。