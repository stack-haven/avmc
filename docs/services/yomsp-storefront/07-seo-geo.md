# 07 · SEO 与 GEO

> 来源：原规范 §7（SEO 技术规范）、§8（GEO 与内容获客）
> 上游：[02 页面规格](02-ia-and-pages.md) · 上游：[08 本地化](08-localization.md)

---

## 1. 目标与限制

目标是让搜索引擎能**发现、抓取、理解并索引**有价值的俄语页面。

**不承诺**特定排名、流量或收录时间。GEO（生成式引擎优化）同样**不能保证** AI 引用——没有标签、插件或固定写法可以保证被 AI 引用。

---

## 2. 技术基础清单

1. 公开页使用 SSR 或适当预渲染；检查"查看网页源代码"时**关键正文与商品数据必须存在于初始 HTML**。
2. 每个可索引页面有独立、准确的 `<title>`、meta description、H1 和 canonical。
3. 语义化 HTML：一个明确主标题，合理 H2/H3；按钮用 `button`，导航用链接。
4. 生成 XML sitemap，只含**已发布、可索引**的 canonical URL；排除 Draft、noindex、购物车、账户、管理页。
5. `robots.txt` **不得**误封 CSS/JS/图片等渲染资源；管理端与私有内容需适当限制——但 `robots.txt` **不是访问控制**。
6. 正确 HTTP 状态码：真实不存在 → 404；永久删除且不替代 → 410；**不能所有错误页都返回 200**。
7. 处理重定向、尾斜杠、大小写、slug 规范化，避免多 URL 重复内容。
8. 图片使用有意义文件名、准确 alt、合适压缩与尺寸。
9. 清晰站内链接：分类 → 商品，指南 → 相关商品/方案，方案 → 组成商品。
10. 检查移动端可用性、加载性能、Core Web Vitals、布局稳定性与交互响应。
11. 公开页**不得**输出私有数据、token 或内部错误堆栈。
12. 上线前检查域名、HTTPS、canonical host、Sitemap URL 与 robots 配置。

## 3. Metadata 规则

统一通过 `useSeoMeta` / `useHead` 封装（`app/composables/useSeo.ts`），**禁止每页重复写不一致的 metadata 逻辑**。

| 页面 | title 构成 |
|---|---|
| 首页 | 品牌 + 核心业务类别 + 清楚价值主张 |
| 分类页 | 分类名称 + 真实商品类别 |
| 商品页 | 商品名称 + 关键规格/型号（有真实数据时） |
| 方案页 | 方案名称 + 适用场景 |
| 指南页 | 具体问题/主题 + 内容价值 |

### 3.1 禁止

- 多个页面共用同一个泛化 title；
- description 堆关键词（应为自然俄语摘要）；
- canonical 指向非最终规范 URL；
- OG/Twitter metadata 使用不可用的图像或文本；
- `noindex` 与 sitemap 配置互相矛盾。

## 4. 结构化数据（JSON-LD）

**仅在真实字段可用时输出**，且必须与页面可见内容一致。

| 类型 | 使用条件 |
|---|---|
| `Product` | 商品页字段齐全 |
| `Offer` | **真实价格与可售状态明确时**才输出 |
| `BreadcrumbList` | 页面确有面包屑时 |
| `Article` / `BlogPosting` | 指南有真实发布日期/更新时间等字段时 |
| `Organization` | 名称、logo、官方 URL 等真实信息确认后 |

字段要求：

- 名称、图片、SKU、品牌、描述必须对应真实页面数据；
- 价格：**不能**使用示例价格或过期价格；货币 `RUB`；
- `availability`：必须与当前可售状态一致；
- `review` / `aggregateRating`：只有真实、可核验且符合平台规则的评论数据才输出，**没有就不输出**；
- `shippingDetails` / `returnPolicy`：只有已确定且能履约的政策才输出；
- 必须用验证工具测试；JSON-LD **不得**成为不可见虚假内容的载体。

> 本阶段：所有商品/价格均为 Mock → **不得输出 `Offer` 与 `review`**。可输出 `BreadcrumbList`（页面确有面包屑）；`Product` 也建议关闭，直到真实数据接入（在 `useSeo` 中以 `isDemo` 守卫）。

## 5. URL 与索引策略

建议形态：

```text
/catalog
/catalog/terrariums
/products/<stable-slug>
/habitats/<stable-slug>
/guides/<stable-slug>
```

要求：

- slug **稳定、可读、唯一**；俄语 slug 的拉丁转写策略**统一**（用一套 transliteration 工具，不各页随意混用）；
- 筛选参数不会无限创建可索引低价值页面（`/catalog/:category?filter=*` 默认 `noindex, follow` + canonical 指向无参 URL）；
- 购物车、账户、管理、内部预览页 `noindex`，并加鉴权（适用时）；
- 仅发布的真实内容进入 sitemap；
- 商品下架按业务决定 404/410、替代重定向或保留停售页，**不能统一粗暴重定向首页**。

## 6. 俄语内容策略（SEO 视角）

- 默认语言俄语；
- 商品标题与描述使用自然、准确的俄语，避免机器翻译式关键词重复；
- 单位优先公制；内部统一存储单位并明确转换规则；
- 价格以卢布展示，但**只能使用后端真实价格**；
- 术语表统一（物种名、类目、材料、结构、通风、尺寸、适配），见 [08 §3](08-localization.md#3-术语表用词口径)；
- 未来若增加英语/其他语言，使用明确 locale 路由 + `hreflang`；**未真正维护多语言内容前不输出无效 hreflang**。

## 7. GEO：内容可引用性

- 清楚说明品牌/站点提供什么产品、面向谁、产品事实是什么；
- 商品规格用**结构化字段**呈现，关键参数不藏在图片或 PDF 里；
- 文章开头先直接回答，再解释原因、适用条件、步骤和例外；
- 明确区分**事实 / 建议 / 经验 / 待确认事项**；
- 物种饲养建议注明适用物种、生命周期/环境条件差异及可靠参考来源；
- 尺寸、材料、通风、温湿度、照明、底材等内容用表格 + 清晰小标题；
- 内容准确、可核验、可持续维护，标注真实更新时间；
- **不制造**虚假作者资历、专家审稿、品牌历史或客户案例；
- **不批量生产**低质量、同义改写、关键词堆砌的自动生成文章；
- 页面提供对用户有帮助的独立信息，而不只是复制产品目录。

### 7.1 推荐内容主题（需专业核实后发布）

按真实商品范围规划：如何按物种和体型评估饲养空间 · 选饲养箱要检查的尺寸/通风/开口/材质 · 模块如何组合及哪些需人工确认 · 装饰/躲避/攀爬/底材的用途与限制 · 安装清洁维护 · 常见选购错误清单 · 标准商品与组合方案的差异 · 设计器使用教程。

> 这些是**选题**，不是已核实的饲养结论。发布前必须由可靠资料或有资质/经验的审核者核验。**不得**为关键词流量提供可能危害动物健康的笼统建议。

### 7.2 GEO 内容模板

1. 问题与直接答案；2. 适用对象与不适用范围；3. 关键参数/选择标准；4. 分步骤检查；5. 常见错误；6. 需专业判断的例外；7. 参考资料与更新时间；8. 相关商品或方案（仅真实可用时）。

## 8. GEO 监测指标

不使用无法验证的"AI 可见度评分"作为唯一 KPI。可监测：

- 公开页可抓取率、索引状态；
- 自然搜索展示、点击、CTR、落地页转化；
- 指南 → 商品/方案的点击率；
- 商品页有效访问与加购意向；
- 来自 AI/推荐来源的引荐流量（若分析工具能可靠识别）；
- 内容事实完整度、引用来源覆盖率、更新时间；
- 生成式 AI 抽样查询的品牌/页面引用情况（人工抽样记录，不作稳定排名保证）。

## 9. SEO 自动化测试（CI 必做）

- [ ] 所有公开页有非空 title / description / canonical
- [ ] 每页只有一个主要 H1
- [ ] 商品详情初始 HTML 包含名称、价格（有数据时）、SKU/规格（有数据时）
- [ ] Draft、cart、account、admin 不在 sitemap 中
- [ ] 404 路由返回正确状态码
- [ ] JSON-LD 可解析
- [ ] 生产环境不输出 Demo 商品
- [ ] sitemap 中所有 URL 为 canonical 且返回 200
- [ ] 无 canonical 指向 localhost 或测试域名

## 10. 落地位置

| 能力 | 位置 |
|---|---|
| metadata 封装 | `app/composables/useSeo.ts` |
| JSON-LD 生成 | `shared/utils/structured-data.ts` + `useSeo` 调用 |
| sitemap | `server/routes/sitemap.xml.ts`（仅 published 数据源） |
| robots | `server/routes/robots.txt.ts`（按环境分支） |
| 索引策略 | `nuxt.config.ts` `routeRules` + 页面 `useSeoMeta({ robots })` |

## 11. 参考来源（实施时以官方当前文档为准）

Nuxt 官方文档（rendering modes、routeRules、data fetching、SEO metadata、deployment）；Vue 官方文档（Composition API、SSR）；Google Search Central（JavaScript SEO、Product structured data、sitemap）；Yandex Webmaster（商品结构化数据、Sitemap、验证工具）。

> 不得凭记忆臆造搜索引擎规则；结构化数据只帮助机器理解页面，不保证排名、富结果或 AI 引用。