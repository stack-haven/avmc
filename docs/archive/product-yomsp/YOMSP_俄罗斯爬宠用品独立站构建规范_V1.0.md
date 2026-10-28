# YOMSP 俄罗斯爬宠用品独立站：产品、设计、工程、SEO/GEO 与交付规范 V1.0

> **文档用途**：本文件是 Coding Agent 的项目主规范（Source of Truth）。执行时应先审查现有仓库和已有 SaaS/API 能力，再按阶段实现、测试和交付。不要跳过仓库审查，不要一次性生成全部页面，不要擅自改变技术栈或业务边界。
>
> **品牌说明**：YOMSP 暂作为业务及独立站宣传使用的品牌名称。业务未成熟阶段不要求立即申请商标，但上线前应进行基础品牌名称、域名、社媒账号和明显商标冲突检查。本项目不能把“暂不申请商标”理解为“不需要冲突检查”。
>
> **真实性原则**：凡未由用户或真实后端提供的数据，一律不得伪装成真实业务数据。包括商品价格、库存、配送承诺、销量、评价、用户数量、认证、合作关系、客户案例、公司地址、退换货条款等。样例数据必须清楚标记为 Demo / 示例数据，并与生产数据隔离。

---

## 0. 给 Coding Agent 的最高优先级指令

1. **先检查，后编码**：先读取仓库目录、README、package.json、锁文件、Nuxt/Vue 配置、Tailwind 配置、测试、CI/CD、环境变量样例、API 契约和现有组件。输出审查报告和实施计划后再改代码。
2. **技术基线**：独立站前端使用 **Nuxt + Vue 3 + TypeScript + Tailwind CSS**；业务后端使用现有 **Go API / SaaS 基础服务**；管理中台使用现有 **Vben Admin**。不得未经批准替换为 React/Next.js、不得新建重复业务后端或绕过现有 SaaS 基础设施。
3. **SSR 是 SEO 的默认要求**：面向公开搜索的页面必须服务端渲染（SSR）或在适当情况下预渲染。禁止将整个站点配置为 `ssr: false` 的纯 SPA。
4. **先建立系统边界**：Nuxt 不直接访问数据库。商品、SKU、价格、库存、可售状态、兼容规则、订单、权限、审计等权威业务逻辑由 Go 后端负责。
5. **按阶段提交**：每个阶段完成后运行 lint、typecheck、测试和 build；报告真实执行结果，不得声称未运行的检查已通过。
6. **组件化和一致性**：页面必须使用统一设计 Tokens、基础组件、业务组件和 Section Registry；禁止每个页面自行创造一套样式、颜色、间距和卡片结构。
7. **动态内容必须可运营**：首页内容采用“固定页面模板 + 固定 Slot + 可配置 Section 实例 + 结构化内容引用 + 真实业务数据 + Draft/Preview/Publish”模式，不做任意代码型拖拽装修器。
8. **渐进式实现**：第一版以标准商品、人工选品、标准模块组合、2D/平面预览为边界；不做任意三维建模，不承诺未经验证的兼容性，不接入真实支付，除非另有明确需求和服务端方案。
9. **未知信息不猜测**：如果仓库、API、物流、支付、商品或合规资料缺失，列出阻塞项与假设；可以用明确标识的 Mock 完成界面开发，但不得把 Mock 当作真实能力。
10. **保持文档同步**：每阶段更新 `README`、`.env.example`、API 契约、数据模型、测试说明和已知限制。所有关键决策写入 `docs/decisions/`。

### 每阶段必须交付

- 改动文件清单与关键实现说明；
- 已运行命令及实际结果（lint/typecheck/test/build）；
- 截图或页面验证说明（如具备浏览器工具）；
- 未完成事项、阻塞项、风险与下一阶段计划；
- 真实数据与 Mock 数据的边界说明。

---

## 1. 项目背景与商业目标

### 1.1 业务定位

YOMSP 是面向俄罗斯市场的爬宠用品品牌/独立站项目，聚焦爬宠饲养环境与相关产品，面向新手饲养者和有经验的爬宠爱好者。站点需要兼顾品牌展示、专业产品说明、标准产品销售、模块化环境组合与专业内容获客。

项目早期以供应商现有标准商品和人工选品为主。不要假设已拥有自有工厂、独立生产线、任意尺寸定制能力或完整俄罗斯本地履约体系。朋友现有平台销售和仓储能力可以作为后续调研线索，但在得到书面确认之前，不得在站点上承诺相关库存、仓储、发货时效或履约能力。

### 1.2 主要用户

- **新手用户**：不知道该为特定爬宠选择什么尺寸、结构、底材、躲避、攀爬、照明或环境配件；需要循序渐进的指导。
- **资深爱好者**：更关注尺寸、材料、通风、结构、兼容性、SKU、参数和可扩展性；希望快速检索和比较。
- **组合方案用户**：想基于标准模块搭配环境，查看结构/布局和清单；复杂需求由人工确认。
- **内容搜索用户**：从俄语搜索引擎或生成式 AI 的回答进入专业指南、商品详情或环境方案。

### 1.3 价值主张

- 专业且可核验的产品参数；
- 帮助用户理解选择逻辑的环境指南；
- 标准模块化组合，而非虚假承诺的无限定制；
- 清楚区分可直接购买商品、组合建议与需要人工确认的特殊需求；
- 俄语优先、卢布价格、公制单位、清晰的购买与配送信息（配送政策只有在真实确认后才展示）。

### 1.4 第一版商业边界

**第一版包含**
- 品牌首页、商品目录、分类、商品详情；
- 环境方案列表与详情；
- 标准模块环境设计器（2D/平面布局或示意图）；
- 前端演示购物车；
- 指南/文章内容；
- 首页内容运营原型；
- SEO 技术基础；
- 适配移动端和桌面端。

**第一版不包含，除非另行批准**
- 真实支付、真实订单履约；
- 任意三维建模或复杂 3D 渲染；
- 用户随意输入任意尺寸后自动承诺生产；
- 未验证的商品兼容性自动推荐；
- 复杂个性化账户体系；
- 用户评论、评分、销量等未经真实数据支持的社会证明；
- 未确认的物流、税务、退款、支付渠道承诺；
- 生产级拖拽页面装修器；
- 以 AI 生成内容替代商品事实核验。

---

## 2. 技术架构与工程原则

### 2.1 推荐技术基线

| 层 | 选型 | 责任 |
|---|---|---|
| 公共站点 | Nuxt（兼容当前仓库与部署的稳定版本） | 页面、SSR、SEO、公开内容展示 |
| UI 框架 | Vue 3 + TypeScript | 组件和交互 |
| 样式 | Tailwind CSS | Tokens、响应式和一致的样式系统 |
| 路由 | Nuxt file-based routing | 公开页面与受限页面路由 |
| 数据获取 | `useFetch` / `useAsyncData` 封装 | SSR 数据预取、错误和缓存策略 |
| 运行时校验 | Zod 或与仓库兼容的 schema 工具 | 校验运营配置和 API 响应 |
| 状态 | Vue Composition API；复杂跨组件状态需要时使用 Pinia | 购物车/设计器状态 |
| 后端 | Go，复用现有 SaaS 基础服务 | 商品、SKU、价格、库存、配置、兼容规则、权限等 |
| 管理端 | 现有 Vben Admin | 商品/内容/推荐位运营（依现有系统能力逐步接入） |
| API 契约 | 优先 OpenAPI；如现有项目已有 Protobuf/gRPC 网关契约则沿用并明确边界 | 防止前后端字段漂移 |
| 测试 | Vitest + Vue Test Utils；关键流程可用 Playwright | 单元、组件、流程测试 |
| 包管理 | 遵循仓库现有 pnpm/npm/yarn 与 lockfile | 不随意切换包管理器 |

**版本原则**：先检查仓库已有版本和依赖兼容性，再锁定版本并提交锁文件。不得随意执行大版本升级。若仓库尚不存在，则选择互相兼容的稳定版本并记录选择依据。

### 2.2 系统边界

```text
浏览器 / 搜索引擎爬虫
        |
        v
CDN / 反向代理 / TLS
        |
        v
Nuxt SSR 应用（公开站点）
  - 页面渲染与 metadata
  - Section Registry
  - SSR 数据加载与缓存
  - 设计器前端交互
        |
        v
Go API / 现有 SaaS 基础服务
  - 商品、分类、SKU
  - 价格、库存、可售状态
  - 环境方案与兼容规则
  - 首页运营配置
  - 内容与指南
  - 购物车/订单（后续）
  - 权限、审计、配置
        |
        v
现有数据库 / 文件 / 对象存储 / 其他业务服务
```

- Nuxt 不得直连数据库，不得把后端密钥写入浏览器代码。
- `NUXT_*` 运行时配置中，只有 `runtimeConfig.public` 可暴露给浏览器；私密 API token、内部服务地址凭证必须保留在服务端。
- 商品价格、库存、可售状态与兼容性由 Go API 作为权威来源；前端只能显示 API 返回的数据。
- 不因开发便利在 Nuxt 中复制一套价格/库存业务规则。
- 不必一开始新增 BFF 微服务。Nuxt 服务端可以调用已有 Go API；只有出现明确的聚合、缓存、鉴权适配需求时再考虑独立 BFF。
- Vben 是管理中台，不要把管理后台包进公开站点的 SEO 页面。可以同域不同路径或独立子域部署，具体服从现有基础设施和认证设计。

### 2.3 路由级渲染策略

| 路由 | 渲染 | SEO |
|---|---|---|
| `/` | SSR + 缓存 | 可索引 |
| `/catalog` | SSR + 合理缓存 | 可索引 |
| `/catalog/:category` | SSR + 合理缓存 | 可索引，避免无限筛选 URL |
| `/products/:slug` | SSR | 核心商品信息必须进入初始 HTML |
| `/habitats` | SSR + 缓存 | 可索引 |
| `/habitats/:slug` | SSR + 缓存 | 可索引 |
| `/guides` | SSR 或预渲染 | 可索引 |
| `/guides/:slug` | 预渲染或 SSR | 可索引 |
| `/configurator` | SSR 页面外壳 + 客户端交互 | 可索引介绍内容；复杂状态不必索引 |
| `/cart` | 客户端交互为主 | 通常 `noindex` |
| `/account/**` | 客户端交互为主 | `noindex` |
| `/admin/**` | Vben 独立管理应用 | 禁止索引；必须鉴权 |

具体使用 Nuxt `routeRules`、SSR、预渲染或缓存时，必须验证实际部署环境支持相应能力。不得仅在开发环境看起来正常就宣称生产 SSR/缓存正常。

### 2.4 工程目录建议

先尊重已有仓库。若为新建站点，可采用如下清晰结构：

```text
.
├── app.vue
├── nuxt.config.ts
├── assets/
│   └── css/main.css
├── components/
│   ├── base/
│   ├── layout/
│   ├── product/
│   ├── category/
│   ├── habitat/
│   ├── configurator/
│   ├── content/
│   └── sections/
├── composables/
├── layouts/
├── middleware/
├── pages/
│   ├── index.vue
│   ├── catalog/index.vue
│   ├── catalog/[category].vue
│   ├── products/[slug].vue
│   ├── habitats/index.vue
│   ├── habitats/[slug].vue
│   ├── guides/index.vue
│   ├── guides/[slug].vue
│   ├── configurator.vue
│   ├── cart.vue
│   └── style-guide.vue
├── server/
│   ├── api/                  # 仅用于必要的服务端路由适配，不复制业务域
│   └── utils/
├── services/
│   ├── api-client.ts
│   ├── product.repository.ts
│   ├── content.repository.ts
│   ├── homepage.repository.ts
│   └── habitat.repository.ts
├── types/
├── utils/
├── public/
├── tests/
├── docs/
│   ├── decisions/
│   ├── api/
│   └── qa/
└── .env.example
```

---

## 3. 品牌与视觉设计规范

### 3.1 设计目标

视觉需要体现自然生态、专业饲养、产品可靠性和有设计感的品牌体验。避免廉价电商模板、过度装饰、全站纯黑金风格和过度拥挤的商品网格。主视觉应使用真实且获得合法使用权的爬宠及饲养环境摄影；不要用 AI 图像伪装成具体在售商品。

### 3.2 视觉方向

- 主背景：暖白、象牙白、浅石灰色；
- 主品牌色：森林绿/深苔绿，用于关键按钮、链接强调、少量大面积品牌区块；
- 辅助色：木色、岩石灰、土壤棕、自然沙色；
- 强调色：只用于价格、可用状态、提示等明确语义；
- 图片：环境全景、产品结构、材质细节、安装/尺寸图；保持一致的光线和色彩处理；
- 排版：清晰的层级、足够留白、适合俄语长词的布局；避免强行大写导致俄语可读性下降；
- 动效：轻量、目的明确，支持 `prefers-reduced-motion`；
- 图标：统一图标库或统一线性风格，不混用多套视觉体系。

### 3.3 设计 Tokens

必须在 Tailwind theme/CSS variables 中集中定义，实际数值在仓库审查和首轮视觉实现后锁定。页面禁止到处写任意颜色和间距。

建议 Tokens：
- `color-brand`
- `color-brand-strong`
- `color-background`
- `color-surface`
- `color-text`
- `color-muted`
- `color-border`
- `color-success`
- `color-warning`
- `color-danger`
- `font-body`
- `font-heading`
- `radius-sm/md/lg/xl`
- `shadow-card`
- `container-max`
- 统一间距和响应式断点。

所有颜色需满足可读性与对比度要求；交互控件必须有可见焦点态。

### 3.4 三层组件体系

**第一层：基础 UI**
- `BaseButton`
- `BaseInput`
- `BaseSelect`
- `BaseCheckbox`
- `BaseRadio`
- `BaseBadge`
- `BaseModal`
- `BaseDrawer`
- `BaseTabs`
- `BaseBreadcrumb`
- `BaseSkeleton`
- `BaseEmptyState`
- `BaseAlert`
- `BasePagination`

**第二层：业务组件**
- `ProductCard`
- `ProductGallery`
- `ProductPrice`
- `AvailabilityBadge`
- `ProductSpecTable`
- `CategoryCard`
- `HabitatBundleCard`
- `ProductGrid`
- `ProductCarousel`
- `ConfiguratorModuleCard`
- `ConfiguratorCanvas2D`
- `SectionRenderer`
- `GuideCard`

**第三层：页面组合**
- 首页各 Section；
- 目录/筛选区；
- 商品详情页；
- 环境方案详情；
- 设计器工作区；
- 运营预览页。

禁止业务组件直接读取 localStorage 或直接拼接 API URL。通过 composable/repository 注入数据与状态。基础组件不包含商品业务规则。

### 3.5 Tailwind 使用约束

- 统一使用当前项目的 Tailwind 主版本和配置方式；不要混用不兼容的 v3/v4 写法。
- 颜色、字号、圆角、阴影、容器宽度等必须从 Tokens 引用。
- 禁止在页面中反复复制同一段长 class 列表；高频样式封装为组件或可复用 variant。
- 不强制引入第二套 UI 组件库；先使用自建基础组件，只有复杂无障碍交互明显需要时再评估。
- 不用内联样式作为主要布局手段；仅对动态计算尺寸/位置等有明确理由的场景使用。
- 每个交互组件必须覆盖 default、hover、focus、disabled、loading、error（适用时）状态。
- 页面需适配窄屏、常见手机、平板、桌面宽屏；不能只验证 1440px 桌面。
- 俄语文本必须经过实际布局测试；避免硬编码固定宽度导致长词溢出。

### 3.6 图片规范

- 所有图片提供明确用途、替代文本和合适尺寸。
- 优先使用 AVIF/WebP 等现代格式，并为需要的场景提供兼容方案。
- 首屏主图优先级加载；非首屏图片懒加载。
- 明确图片比例，避免 CLS；商品图片不应被错误裁切。
- 不把重要文字只放在图片中。
- 只有获得使用权的图片才可进入生产；图片来源和授权记录进入 `docs/assets.md`。
- 商品图必须对应真实商品；概念图必须标注为示意图。

---

## 4. 页面信息架构与交互要求

### 4.1 全站导航

建议主导航：
- Каталог（商品目录）
- Среды обитания / Готовые решения（环境方案）
- Конфигуратор（环境设计器）
- Гиды（指南）
- О бренде（品牌介绍；只有有真实内容时上线）

Header 需包含品牌 Logo、目录/方案/设计器入口、搜索（若真实实现）、购物车入口和移动端导航。不要显示无效的登录、收藏、比较、语言切换或搜索按钮。如果按钮暂未实现，需隐藏或明确禁用并说明。

### 4.2 首页 `/`

区块顺序固定为：
1. Header；
2. Hero 主视觉；
3. 可证实服务信息条（未核验的配送/退换承诺不展示）；
4. 双入口卡片：
   - A：`设计我的饲养环境`，面向新手和组合用户；
   - B：`浏览全部商品/专业选购`，面向直接选购用户；
5. 热门分类；
6. 精选商品；
7. 环境方案；
8. 设计器推广 Banner；
9. 选购指南；
10. Footer。

Hero 要有清晰主标题、副标题和主 CTA，强调专业环境搭配和标准产品选择。不要使用虚构的销量、客户数、专家认证或“俄罗斯第一”等无法证实的表述。

### 4.3 商品目录 `/catalog`、`/catalog/:category`

- SSR 首屏应输出分类标题、简介（若有）、商品名称、价格（若已确认）、可售状态（若 API 支持）和商品链接。
- 支持分类、筛选、排序、分页或可控的加载更多。
- 筛选项只能来源于真实商品 schema 支持的字段；不要预设未存在的参数。
- URL query 应可复制分享，规范化参数顺序，避免无意义的重复 URL。
- 对组合筛选 URL 制定索引策略：默认不让大量低价值筛选组合进入索引；使用 canonical/noindex 或规范化 URL，依据实际路由策略实施。
- 空结果、加载失败、无库存、筛选重置均需有明确状态。
- 排序字段和价格顺序由后端提供或由前端基于已加载完整数据正确实现，不能在分页子集上假装全局排序。

### 4.4 商品详情 `/products/:slug`

必须展示（有数据时）：
- 真实主图、辅助图、名称、SKU/型号；
- 当前价格与币种（卢布，实际 API 返回）；
- 可售状态、规格、尺寸、公制单位；
- 材料、结构、通风/开口方式等产品实际字段；
- 适用条件和已验证兼容商品；
- 包装清单、安装/清洁说明（如真实资料存在）；
- 相关商品/组合建议；
- 加入购物车（第一版仅 demo 状态）；
- 加入设计器（仅当商品是可配置标准模块时显示）；
- 面包屑和可理解的页面标题。

禁止将“库存充足”“当天发货”“免费配送”“保修”等未经确认的承诺写死。无真实价格时显示“价格待确认/联系咨询”，不能使用虚构价格让用户误以为可购买。

### 4.5 环境方案 `/habitats`、`/habitats/:slug`

方案详情应清楚区分：
- 适用爬宠/适用条件（需经专业资料核实）；
- 环境目标和使用场景；
- 方案图片（实拍/示意需标明）；
- 组成模块及其 SKU；
- 模块数量、尺寸、材料；
- 兼容性说明；
- 总价（仅在所有价格可获得且计算规则明确时显示）；
- 方案可直接购买、可加入设计器或需要人工确认的状态。

不得把未经验证的组合描述为适合某一物种。对饲养环境相关的健康、温度、湿度、UVB、照明等建议应以可靠资料为依据，并标明物种差异；不能只为了 SEO 编造饲养建议。

### 4.6 设计器 `/configurator`

**第一版目标：标准模块 + 2D/平面预览 + 结构化清单。** 不做任意 3D 建模。

桌面布局：
- 左侧：标准模块目录/分类/筛选；
- 中间：2D/平面组合预览；
- 右侧：选中模块属性、规格、数量、清单和估算价格（价格有可靠数据时）；
- 底部/侧边明确展示保存、清空、加入演示购物车、咨询人工确认等操作。

移动端：
- 采用分步流程；
- 底部固定主要操作区；
- 选中模块、尺寸、数量和总清单始终可查看；
- 不强迫用户在窄屏上操作三栏布局。

交互和规则：
- 只能加入已注册的标准模块；
- 每个模块声明允许的连接点/兼容关系/尺寸限制；
- 兼容性由后端规则或经过测试的共享规则定义，不允许前端猜测；
- 不兼容组合必须显示原因并阻止确认，或明确标记为“需人工确认”；
- 不允许任意输入尺寸后直接显示“可生产”；
- 价格估算应标明“估算”及其数据来源/更新时间；价格缺失时不显示误导性总价；
- 设计结果可以第一版保存在浏览器本地，但应通过 repository/state 层封装，组件不得直接读写 localStorage；
- 页面刷新、空设计、模块删除、重复模块、错误组合、移动端操作均需测试；
- 设计器必须提供可访问的列表式清单，不可只靠图形表达信息。

### 4.7 购物车 `/cart`

第一版为前端演示购物车：
- 加入/删除商品、修改数量、显示清单；
- 明确标记“演示功能，不会创建真实订单或发起支付”；
- 不得显示“支付成功”“订单已创建”；
- 不收集银行卡、支付密码等敏感信息；
- 如未来接真实下单，必须由 Go 后端校验价格、库存、可售状态、用户权限和幂等性，不能信任客户端金额。

### 4.8 指南 `/guides`、`/guides/:slug`

- 以解决具体用户问题为主，不以关键词堆砌为目标；
- 每篇指南有清楚标题、摘要、正文、更新时间、作者/审核信息（只有真实存在时展示）、相关产品/方案；
- 物种相关内容需要可靠来源、适用范围和免责声明/注意事项；
- 文章内容需要可由内容系统或仓库结构化内容管理；禁止把所有文章硬编码在页面组件内；
- 支持 canonical、面包屑、文章结构化数据（仅字段真实时输出）。

### 4.9 首页运营原型 `/admin/homepage` 与 `/style-guide`

- `/admin/homepage` 是运营配置原型，开发期可以使用 Mock Repository/localStorage，但必须明确显示“Demo / 本地预览”，不能冒充已接入生产中台。
- `/style-guide` 用于展示 Tokens、基础组件、业务组件和所有交互状态；生产环境是否公开由部署配置决定。
- 运营后台不得对匿名用户开放真实管理能力；真实发布操作必须有鉴权和审计。

---

## 5. 动态内容运营架构

### 5.1 核心模式

使用：
**固定页面模板 + 固定 Slot 定义 + 可配置 Section 实例 + 结构化内容引用 + 真实业务数据 + 预览发布机制。**

不要建设无限制的拖拽式装修器。运营人员只能配置已经注册、经过测试的 Section 类型和字段。

### 5.2 固定首页 Slot

```ts
type HomeSlotKey =
  | 'home.hero'
  | 'home.trust_strip'
  | 'home.entry_cards'
  | 'home.popular_categories'
  | 'home.featured_products'
  | 'home.habitat_bundles'
  | 'home.configurator_banner'
  | 'home.buying_guides'
```

Slot 是前端定义的能力边界，不由运营人员任意创建。

### 5.3 Section Types

```ts
type SectionType =
  | 'hero_banner'
  | 'trust_strip'
  | 'entry_cards'
  | 'category_grid'
  | 'product_grid'
  | 'product_carousel'
  | 'habitat_bundle_grid'
  | 'configurator_banner'
  | 'editorial_guide_grid'
```

`Section Registry` 将已注册的 `sectionType` 映射到具体组件。未知类型必须安全降级并记录错误，不能执行任意代码，不能导致整页崩溃。

### 5.4 运营配置字段

建议字段：
- `id`
- `pageKey`
- `slotKey`
- `sectionType`
- `title`
- `enabled`
- `sortOrder`
- `selectionMode`: `manual | rule_based | collection`
- `productIds` / `categoryIds` / `habitatIds` / `guideIds`（仅适用类型）
- `collectionId`（后续需要时）
- `itemLimit`
- `startAt` / `endAt`
- `fallbackPolicy`
- `status`: `draft | published | archived`
- `version`
- `updatedAt` / `updatedBy`（真实接入后台后）
- `config`（必须经对应 schema 校验）

第一阶段以手动选取、手动排序为主。规则选品和可复用集合可后续扩展。

### 5.5 商品引用与权威数据

- 推荐区块只保存商品 ID/SKU 引用和顺序，不复制价格/库存作为权威值。
- 页面渲染时读取商品 API 的当前数据。
- 缺货/停售商品不得作为正常可售商品误导用户；若保留展示，应清楚标记状态。
- 备用策略必须显式配置：自动补位、隐藏缺位或显示空状态；不能静默替换成不相关商品。
- 如果无可用商品，默认隐藏区块或显示符合设计的空状态。
- API 失败时使用错误/重试/缓存回退策略，不能无声地把过期价格当作当前价格。

### 5.6 Draft / Preview / Publish

工作流：
1. 编辑 Draft；
2. 使用 Preview Token 或受保护预览路由查看 Draft；
3. 校验字段、引用、时间窗口、排序和商品可售状态；
4. 发布；
5. 发布动作生成版本号并记录审计信息；
6. 公开首页只读取 Published 配置；
7. 更新相关缓存；
8. 支持查看当前发布版本与回滚到历史版本（若后端能力允许）。

开发期可通过 localStorage 模拟；所有模拟逻辑必须封装在 `homepage.repository.ts`，组件不得直接访问 localStorage。后续切换真实 API 时，页面和 Section 组件不应重写。

### 5.7 配置运行时校验

- 每种 Section Type 具有独立 schema。
- 验证 slot 与 sectionType 的允许组合。
- 验证 `itemLimit` 合理范围、日期格式、引用 ID 类型、文本长度和 URL。
- 不允许注入任意 HTML/JS。
- 富文本必须安全净化；优先结构化字段而不是允许任意 HTML。
- 无效配置要记录错误，并采用安全的空状态或忽略该 Section。

---

## 6. 业务数据模型与 API 契约

> 以下为前端契约建议，不代表现有后端一定已有这些实体。先审查现有 Go 服务和 SaaS 数据模型；已有相近实体应映射复用，不得为了前端而重复造域模型。最终字段以真实 API 契约为准。

### 6.1 核心实体

```ts
type Currency = 'RUB'

interface Money {
  amountMinor: number       // 最小货币单位，约定后端精度
  currency: Currency
}

interface ProductImage {
  url: string
  alt: string
  width?: number
  height?: number
  role?: 'primary' | 'gallery' | 'detail' | 'diagram'
}

interface ProductVariant {
  id: string
  sku: string
  title: string
  attributes: Record<string, string | number | boolean>
  price?: Money
  availability: 'in_stock' | 'out_of_stock' | 'preorder' | 'unknown' | 'inquiry'
  stockQuantity?: number  // 只有业务确实允许公开时才返回/展示
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
  availability: 'in_stock' | 'out_of_stock' | 'preorder' | 'unknown' | 'inquiry'
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

### 6.2 API 客户端原则

- 所有 API 调用集中在 `services/` 层。
- 对 API 请求定义统一 base URL、超时、错误映射、trace/request ID 透传（如后端支持）。
- SSR 与客户端请求使用一致的数据契约，避免水合不一致。
- 运行时校验关键响应；发生 schema 不匹配时返回可观察错误，不要静默强制转换。
- 对 404、410、500、超时和空列表区分处理。
- 列表 API 应支持分页、筛选、排序和稳定的响应结构。
- 对未确认存在的端点，不要凭空编造为已可调用。可以先定义接口和 Mock Repository，并在 `docs/api/open-items.md` 记录待后端确认的 endpoint。

### 6.3 建议 API 资源（需对照现有服务）

```text
GET /api/v1/storefront/homepage
GET /api/v1/storefront/categories
GET /api/v1/storefront/categories/{slug}
GET /api/v1/storefront/products
GET /api/v1/storefront/products/{slug}
GET /api/v1/storefront/habitats
GET /api/v1/storefront/habitats/{slug}
GET /api/v1/storefront/guides
GET /api/v1/storefront/guides/{slug}
GET /api/v1/storefront/configurator/modules
POST /api/v1/storefront/configurator/validate
```

以上仅是建议契约，不得在未核实后端之前假设这些 endpoint 已存在。若已有 API 命名规则，应遵循既有规范并更新文档。

### 6.4 Repository 适配层

至少定义：
- `ProductRepository`
- `CategoryRepository`
- `HabitatRepository`
- `GuideRepository`
- `HomepageRepository`

开发阶段可实现 `MockXxxRepository`；接后端后实现 `ApiXxxRepository`。页面只依赖接口，不依赖具体实现。切换 Mock/API 应通过环境配置或依赖注入完成，不能散落在页面里的 `if (demo)` 判断。

### 6.5 Mock 数据要求

- 放在独立 `mocks/` 或测试 fixtures 中。
- 所有示例商品、价格、库存、文章、评价必须带 Demo 标识或仅在非生产环境启用。
- 生产 build 默认不允许意外加载 Mock。
- 不生成虚假的评价、评分、销量、促销倒计时或库存紧张提示。
- 图片若为占位图，必须明确标识；不得用占位图冒充真实商品图。

---

## 7. SEO 技术规范

### 7.1 SEO 目标与限制

目标是让搜索引擎能够发现、抓取、理解并索引有价值的俄语页面。SEO 不能保证排名或收录。不要承诺特定排名、流量或收录时间。

### 7.2 技术基础清单

1. 公开页面使用 SSR 或适当预渲染；检查“查看网页源代码”时关键正文和商品数据是否存在于初始 HTML。
2. 每个可索引页面有独立、准确的 `<title>`、meta description、H1 和 canonical。
3. 使用语义化 HTML：一个明确主标题，合理 H2/H3；按钮用 button，导航用链接。
4. 生成 XML sitemap，包含已发布、可索引的 canonical URL；排除 Draft、noindex、购物车、账户和管理页面。
5. `robots.txt` 不得误封 CSS、JS、图片等渲染资源；管理端、私有内容和非索引路由需有适当限制，但 `robots.txt` 不是访问控制。
6. 正确返回 HTTP 状态码：真实不存在的商品返回 404；已永久删除且不再替代的页面可返回 410；不能所有错误页都返回 200。
7. 处理重定向、尾斜杠、大小写和 slug 规范化；避免多个 URL 返回重复内容。
8. 图片使用有意义文件名、准确 alt、合适压缩和尺寸。
9. 建立清晰的站内链接：分类 → 商品，指南 → 相关商品/方案，方案 → 组成商品。
10. 检查移动端可用性、加载性能、Core Web Vitals、布局稳定性和交互响应。
11. 公开页面不得意外输出私有数据、token 或内部错误堆栈。
12. 生产环境上线前检查域名、HTTPS、canonical host、Sitemap URL 与 robots 配置。

### 7.3 Metadata 规则

建议通过 Nuxt `useSeoMeta` / `useHead` 统一封装，禁止每页重复写不一致的 metadata 逻辑。

- 首页：品牌 + 核心业务类别 + 清楚价值主张；
- 分类页：分类名称 + 真实商品类别；
- 商品页：商品名称、关键规格/型号（有真实数据时）；
- 方案页：方案名称 + 适用场景；
- 指南页：具体问题/主题 + 内容价值；
- 不允许将多个页面设为同一个泛化 title；
- description 应为自然俄语摘要，不要堆关键词；
- canonical 必须指向最终规范 URL；
- OG/Twitter 类社交 metadata 只使用真实可用的图像和文本；
- 不输出 `noindex` 与 sitemap 互相矛盾的配置。

### 7.4 Product / Offer 结构化数据

仅在真实字段可用时输出 JSON-LD。商品页可使用 `Product`，在真实价格和可售状态明确时再输出 `Offer`。字段应与页面可见内容一致。

- 名称、图片、SKU、品牌、描述：必须对应真实页面数据；
- 价格：不能使用示例价格或过期价格；
- 货币：RUB（如果真实价格以卢布结算）；
- availability：必须与当前商品可售状态一致；
- review/aggregateRating：只有真实、可核验且符合平台规则的评论数据才输出；没有就不输出；
- shippingDetails/returnPolicy：只有已确定且能履约的政策才输出；
- 结构化数据必须通过相应验证工具测试；
- JSON-LD 不得成为页面不可见虚假内容的载体。

其他结构化数据：
- `BreadcrumbList`：在页面确有面包屑时输出；
- `Article`/`BlogPosting`：指南内容有真实发布日期、更新时间等字段时输出；
- `Organization`：只有名称、logo、官方 URL 等真实信息确认后输出；
- 不要为了“结构化数据覆盖率”输出不真实字段。

### 7.5 URL 与索引策略

建议：
- `/catalog`
- `/catalog/terrariums`
- `/products/<stable-slug>`
- `/habitats/<stable-slug>`
- `/guides/<stable-slug>`

要求：
- slug 稳定、可读、唯一；俄语 slug 的拉丁转写策略需统一，不要不同页面随意混用；
- 筛选参数不会无限创建可索引的低价值页面；
- 购物车、账户、管理、内部预览页设置 noindex，并加鉴权（适用时）；
- 仅发布的真实内容进入 Sitemap；
- 产品下架时按业务情况决定 404/410、替代商品重定向或保留停售页，不能统一粗暴重定向首页。

### 7.6 俄语内容策略

- 网站默认语言为俄语；
- 商品标题与描述使用自然、准确的俄语，避免机器翻译式重复关键词；
- 单位优先采用公制，尺寸字段内部统一存储单位并明确转换规则；
- 价格以卢布展示，但只能使用后端真实价格；
- 术语表统一：物种名称、产品类别、材料、结构、通风、尺寸、适配等词汇；
- 如未来增加英语或其他语言，使用明确的 locale 路由和 hreflang；未真正维护多语言内容前不要输出无效 hreflang。
- 如果暂时没有可靠俄语编辑能力，必须把需要人工校对的内容列为上线阻塞项。

### 7.7 SEO 自动化测试

建立可自动执行的检查：
- 所有公开页面都有非空 title、description、canonical；
- 每页只有一个主要 H1（允许复杂语义结构，但默认保持一个清晰主标题）；
- 商品详情初始 HTML 包含名称、价格（有数据时）、SKU/规格（有数据时）；
- Draft、cart、account、admin 不进入 Sitemap；
- 404 路由返回正确状态码；
- 结构化数据 JSON 可解析；
- 页面不输出 Demo 商品到生产环境；
- sitemap 中所有 URL 为 canonical 且返回 200；
- 无 canonical 指向 localhost 或测试域名。

---

## 8. GEO（生成式引擎优化）与内容获客

### 8.1 GEO 的定义与现实限制

GEO 在此项目中指提升网站内容被生成式搜索、AI 问答和检索系统发现、理解及引用的可能性。**没有一个标签、插件或固定写法可以保证 AI 引用**。不要把 GEO 宣传为保证流量的捷径，也不要用虚假“AI 认证”标识。

### 8.2 站点内容的可引用性

- 清楚说明品牌/站点提供什么产品、面向什么用户、产品事实是什么；
- 商品规格用结构化字段呈现，避免关键参数只藏在图片或 PDF；
- 文章开头先直接回答问题，再解释原因、适用条件、步骤和例外；
- 明确区分事实、建议、经验和待确认事项；
- 对物种饲养建议注明适用物种、生命周期/环境条件差异及可靠参考来源；
- 对尺寸、材料、通风、温湿度、照明、底材等内容采用表格和清晰小标题；
- 使用准确、可核验、能持续维护的内容，标注真实更新时间；
- 不制造虚假作者资历、专家审稿、品牌历史或客户案例；
- 避免大量低质量、同义改写、关键词堆砌的自动生成文章；
- 页面应提供对用户有帮助的独立信息，而不只是复制产品目录。

### 8.3 推荐内容主题（需要专业核实后发布）

按真实商品范围规划：
- 如何根据爬宠种类和体型评估饲养空间；
- 选择饲养箱时需要检查的尺寸、通风、开口和材质；
- 环境模块如何组合，以及哪些组合需要人工确认；
- 不同装饰、躲避、攀爬和底材的用途与限制；
- 安装、清洁和维护；
- 常见选购错误与检查清单；
- 标准商品和组合方案的差异；
- 设计器使用教程。

这些是内容选题，不是已核实的饲养结论。发布前必须由可靠资料或有资质/经验的专业审核者核验。不要为了关键词流量提供可能危害动物健康的笼统建议。

### 8.4 GEO 结构化内容模板

每篇指南可按以下结构：
1. 问题与直接答案；
2. 适用对象与不适用范围；
3. 关键参数/选择标准；
4. 分步骤检查；
5. 常见错误；
6. 需要专业判断的例外；
7. 参考资料与更新时间；
8. 相关商品或方案（仅相关且真实可用时）。

### 8.5 GEO 监测指标

不使用无法验证的“AI 可见度评分”作为唯一 KPI。可监测：
- 公开页面可抓取率、索引状态；
- 自然搜索展示、点击、CTR 和落地页转化；
- 指南到商品/方案的点击率；
- 商品页有效访问与加购意向；
- 来自 AI/推荐来源的引荐流量（若分析工具能可靠识别）；
- 内容事实完整度、引用来源覆盖率和更新时间；
- 生成式 AI 中抽样查询的品牌/页面引用情况（人工抽样记录，不把它当作稳定排名保证）。

---

## 9. 俄语市场与用户体验本地化

- 默认语言俄语；价格显示卢布；尺寸采用公制。
- 所有时间、日期、数字格式遵循俄语用户习惯。
- 俄语按钮和导航需要人工校对，避免中文直译。
- 支付、配送、退货、税务、消费者权益、隐私和个人数据处理等政策需根据实际经营主体、交易模式与目标市场进行专业核实；未确认前不做法律承诺。
- 不假设某一支付方式、手机号登录方式或物流方式必然可用。
- 网站不应把朋友现有平台、仓库或供应商资源描述成 YOMSP 已拥有的能力，除非合作关系、可用库存和履约责任已确认。
- 联系方式、公司信息、售后渠道必须真实。
- 不要显示虚假的“俄罗斯本地发货”“本地仓现货”等文字。

---

## 10. 安全、隐私、性能与可访问性

### 10.1 安全

- 所有输入在服务端验证；前端校验只用于体验。
- 运营配置和富文本必须防 XSS；禁止任意 HTML/JS 执行。
- 管理接口必须鉴权、授权和审计；不能依赖前端隐藏按钮作为权限控制。
- 不将私钥、API token、数据库地址凭证写入客户端。
- 限制图片上传类型、大小和来源；如果涉及上传，后端需验证内容而不只看扩展名。
- 对可能改变业务状态的请求使用 CSRF/鉴权/幂等机制（依据认证架构）。
- 错误日志不得泄露敏感数据。
- 不收集业务不需要的个人信息。

### 10.2 性能

- 首屏核心内容 SSR 输出；
- 对首屏主图做尺寸与优先级优化；
- 延迟加载非首屏图片；
- 避免巨型依赖和不必要的客户端 JS；
- 组件按需加载；设计器等复杂交互可采用动态导入；
- 控制布局位移，图片声明宽高/比例；
- API 使用合理缓存、超时和错误回退；
- 以真实测试环境评估 Core Web Vitals，不得只根据本地开发服务器作性能结论。

### 10.3 可访问性

- 键盘可操作所有核心功能；
- 所有输入有 label；
- 图片有准确 alt（装饰图用空 alt）；
- 模态框管理焦点，关闭后还原焦点；
- 颜色不能是唯一状态提示；
- 支持焦点可见和合理对比度；
- 支持减少动态效果偏好；
- 设计器提供文本清单替代纯图形操作；
- 表单错误信息与对应字段关联。

### 10.4 监控与日志

- 区分客户端错误、Nuxt SSR 错误、Go API 错误；
- 若现有基础服务支持 request ID/trace ID，则贯穿请求链路；
- 不记录敏感 token 或不必要的用户信息；
- 生产环境提供健康检查、错误率和延迟监控（按现有基础设施实现）；
- 关键业务失败不能只在浏览器 console 中出现。

---

## 11. 环境变量与配置管理

至少提供 `.env.example`，使用占位值，不包含真实密钥。

示例：
```env
NUXT_PUBLIC_SITE_URL=https://example.invalid
NUXT_PUBLIC_SITE_NAME=YOMSP
NUXT_API_BASE_URL=http://localhost:8080
NUXT_PUBLIC_DEMO_MODE=true
```

约束：
- `NUXT_PUBLIC_*` 一律视为可公开信息；
- 私密 API 凭证只能由 Nuxt 服务端或 Go 服务端持有；
- 生产域名必须由部署配置注入；
- Demo 模式生产默认关闭；
- 不把本地测试域名硬编码到 canonical、sitemap 或 OG metadata；
- 对缺少关键环境变量的生产启动应给出清楚错误，不能静默退回 demo。

---

## 12. Vibe Coding / Coding Agent 工作流程

### Gate 0：仓库审查与事实清单（不得跳过）

检查并输出：
- 当前目录、应用边界、包管理器和锁文件；
- Nuxt/Vue/TS/Tailwind 版本与现有配置；
- 已有组件、Tokens、路由和测试；
- API/Go 服务目录、OpenAPI/Protobuf/接口文档；
- 认证方式、环境变量、部署方式；
- 已有商品/内容/首页配置能力；
- 当前构建、lint、typecheck、测试是否通过；
- 需要向用户确认的阻塞项。

先只读审查，未得到计划确认前不要做大规模重构。如果用户明确要求直接执行，则在仓库事实允许范围内先做最小基线，仍须记录假设。

### Gate 1：技术基线与数据契约

- 锁定版本和包管理器；
- 确定路由、SSR、Tailwind Tokens、组件规范；
- 对照 Go API，确定真实 endpoint 和字段；
- 为缺失 API 建立 Open Items；
- 确定 Demo 数据隔离方案；
- 形成 `docs/architecture.md`、`docs/api-contracts.md`、`docs/decisions/`。

### Gate 2：设计系统与应用骨架

- 建立全局布局、Header、Footer、容器、Tokens；
- 实现基础组件与 `/style-guide`；
- 实现响应式断点和无障碍状态；
- 验证移动端与桌面端；
- 暂不批量堆砌业务页面。

### Gate 3：Mock Repository 与核心公开页面

按顺序：
1. 首页；
2. 商品目录和分类；
3. 商品详情；
4. 环境方案列表与详情；
5. 指南列表与详情；
6. 设计器；
7. 演示购物车。

每个页面先完成状态、响应式、语义化 HTML、metadata 和组件复用，再进入下一页。Mock 必须明确标识。

### Gate 4：首页运营配置原型

- 定义 Slot、Section Registry、Section schemas；
- 建立首页 Section 配置；
- 实现编辑、预览、发布状态的本地 Demo；
- 确保公开首页只读 Published；
- 测试无效配置和无可用商品情况；
- 将 localStorage 限制在 Repository 层。

### Gate 5：Go API 集成

- 以真实 API 替换 Mock Repository；
- 对 API 响应进行运行时校验；
- 处理超时、空数据、404、服务不可用和部分字段缺失；
- 确认 SSR 请求不会泄露私密凭证；
- 不实现未确认的业务规则；
- 价格、库存、兼容性等以 Go 为准。

### Gate 6：SEO/GEO 技术验收

- 验证 SSR 初始 HTML；
- 验证 metadata、canonical、robots、sitemap；
- 验证 Product/Offer/Breadcrumb/Article JSON-LD；
- 确认无虚假价格/评价/库存/政策；
- 验证路由状态码、重定向、筛选 URL 和 noindex；
- 检查俄语内容和术语；
- 建立 SEO/GEO 内容发布 checklist。

### Gate 7：质量与交付

运行仓库中实际存在的命令；缺少脚本时先补齐合理脚本：
- lint；
- typecheck；
- unit/component tests；
- build；
- 必要的 E2E；
- SSR/HTML 检查；
- SEO 自动检查；
- 响应式人工/浏览器检查。

提交：
- 完整文件清单；
- 实际命令与输出摘要；
- 未完成事项；
- 生产接入步骤；
- `.env.example`；
- README；
- 截图/验收记录；
- 已知限制与后续优先级。

---

## 13. 建议实施顺序与优先级

### P0：必须先完成
1. 仓库审查；
2. 技术版本锁定；
3. 设计 Tokens 和基础组件；
4. Repository/API 契约；
5. SSR 首页骨架；
6. 商品目录和详情；
7. SEO metadata、canonical、sitemap、robots；
8. Demo/生产数据隔离；
9. 构建和测试流程。

### P1：核心业务体验
1. 环境方案；
2. 2D 模块化设计器；
3. 首页动态 Section；
4. 运营预览/发布原型；
5. 指南内容系统；
6. 移动端交互打磨；
7. 结构化数据和性能优化。

### P2：真实业务接入
1. 真实商品、SKU、价格、库存 API；
2. 真实首页发布配置；
3. 兼容性规则 API；
4. 联系/咨询表单（含防垃圾与隐私策略）；
5. 分析工具与转化事件；
6. 真实购物车/订单/支付（只有商业与合规条件确认后）。

### P3：增长迭代
1. 内容运营工作流和审核；
2. 搜索和更高级筛选；
3. 站内搜索索引；
4. 多语言；
5. 更高级的设计器；
6. SEO/GEO 实验与转化优化。

---

## 14. 验收标准（Definition of Done）

### 14.1 工程
- [ ] 技术栈与锁定版本符合本文档，变更有明确决策记录；
- [ ] lint/typecheck/test/build 实际运行并记录结果；
- [ ] 无未解释的 TypeScript 错误；
- [ ] 关键组件和 Repository 有测试；
- [ ] Mock 数据不会意外进入生产；
- [ ] `.env.example`、README 和架构文档齐全。

### 14.2 视觉与交互
- [ ] 首页按规定区块顺序实现；
- [ ] 视觉统一使用 Tokens 和共享组件；
- [ ] 桌面、平板、手机布局可用；
- [ ] 所有可见主按钮均有真实行为，或明确标注 Demo/未实现；
- [ ] 空状态、错误、加载、禁用状态完整；
- [ ] 俄语长文本不会导致布局破坏；
- [ ] 设计器在移动端使用分步流程。

### 14.3 业务真实性
- [ ] 没有虚构价格、库存、评价、销量、认证、客户数、物流和售后承诺；
- [ ] Demo 数据有明确标识；
- [ ] 商品与方案只显示真实可核验的兼容信息；
- [ ] 购物车清楚说明不会创建真实订单/支付；
- [ ] 没有把供应商/朋友的平台能力描述为品牌自有能力。

### 14.4 SEO
- [ ] 公共页面使用 SSR 或合理预渲染；
- [ ] 初始 HTML 包含页面主内容；
- [ ] title、description、canonical 正确；
- [ ] sitemap 只含已发布且可索引页面；
- [ ] robots/noindex 策略无冲突；
- [ ] 404 等 HTTP 状态码正确；
- [ ] Product/Offer/Breadcrumb/Article JSON-LD 与可见数据一致；
- [ ] 无 localhost/test 域名进入生产 metadata。

### 14.5 GEO/内容
- [ ] 俄语内容有人工校对；
- [ ] 专业饲养指南有可靠来源和适用范围；
- [ ] 内容直接回答用户问题，结构清晰；
- [ ] 无关键词堆砌、虚假专家背书或低质量批量内容；
- [ ] 内容维护责任与更新时间策略明确。

### 14.6 安全与可访问性
- [ ] 管理能力不对匿名用户开放；
- [ ] 私密配置不进入客户端 bundle；
- [ ] 富文本/用户输入经过安全处理；
- [ ] 核心流程支持键盘操作；
- [ ] 图片、表单、焦点和错误状态满足基本无障碍要求。

---

## 15. 需要用户/业务方补充确认的真实信息

Coding Agent 应建立清单，不得自行编造：
1. 正式域名和 canonical 主机；
2. 最终品牌 Logo、品牌图像及使用权；
3. 实际商品清单、SKU、价格、币种、规格、库存与可售状态；
4. 商品图片及其版权/使用授权；
5. 供应商供货、备货、交期和缺货处理规则；
6. 俄罗斯境内/跨境配送范围、价格、时效和责任；
7. 实际经营主体、联系信息、隐私政策、退换货和售后规则；
8. 支付方案与真实交易能力（第一版默认不接支付）；
9. Go API 的真实地址、认证方式、OpenAPI/Protobuf 契约；
10. 现有 SaaS 的商品/内容/权限/审计服务是否可复用；
11. 环境模块的真实尺寸、连接规则和兼容性数据；
12. 俄语内容审核人/专业顾问及引用资料；
13. 分析工具与隐私合规方案；
14. 生产部署环境、CDN、缓存、日志和监控策略。

这些项目未确认前，允许以隔离 Mock 完成 UI 和架构，但不能宣称网站已具备真实交易、真实库存、实际配送或专业审核能力。

---

## 16. 参考资料与实现核验

Coding Agent 应在实施时核对当前版本官方文档，避免使用过时 API。优先来源：
- Nuxt 官方文档：渲染模式、路由规则、数据获取、SEO metadata、部署；
- Vue 官方文档：Composition API、SSR；
- Tailwind CSS 官方文档：主题变量、响应式与状态；
- Google Search Central：JavaScript SEO、Product structured data、sitemap；
- Yandex Webmaster 官方文档：商品结构化数据、Sitemap、验证工具；
- OpenAPI 官方规范及仓库现有 API 契约；
- Go 项目已有服务规范与测试要求。

SEO/GEO 的技术实施应以当前官方文档为准；不要凭记忆臆造搜索引擎规则。结构化数据只帮助机器理解页面，不保证排名、富结果展示或 AI 引用。

---

# 附录 A：Coding Agent 启动提示词（第一轮）

将以下内容作为 Coding Agent 第一条任务提示词：

> 你正在实现 YOMSP 俄罗斯爬宠用品独立站。请完整阅读 `docs/` 中的项目主规范（若该文档位于仓库根目录，请以其为准），把它当作本项目的业务和工程约束。
>
> **当前只执行 Gate 0：仓库审查与事实清单。不要立即编码，不要重构，不要安装或升级依赖。**
>
> 请检查当前仓库目录、技术栈版本、lockfile、Nuxt/Vue/TypeScript/Tailwind 配置、现有组件和页面、测试脚本、CI/CD、环境变量、Go API 契约、现有 SaaS 服务和部署方式。识别哪些要求已经满足、哪些已有实现可复用、哪些存在冲突、哪些信息缺失。
>
> 输出：
> 1. 当前工程事实（附文件路径和证据）；
> 2. 与项目规范冲突的地方；
> 3. 可复用模块和不能确定的事项；
> 4. P0-P3 分阶段实施计划；
> 5. 需要业务方确认的阻塞项；
> 6. 建议新增/修改的文件清单；
> 7. 当前 lint/typecheck/test/build 的实际状态（如果执行不会修改文件）。
>
> 不要虚构仓库文件、API endpoint、业务数据或命令执行结果。发现缺少真实商品数据、API 或部署信息时，记录为 Open Item，并提出使用隔离 Mock 的实现建议。输出审查报告后停止，等待确认再执行下一阶段。

# 附录 B：后续阶段通用提示词

> 只实施已经批准的当前 Gate，不要提前实现后续阶段。开始前复述本阶段目标和验收标准；先阅读相关代码和文档；保持已有架构与技术栈；以小步、可测试的变更实施。完成后运行实际可用的 lint、typecheck、test、build，并报告真实结果、修改文件、截图/验证方式、遗留问题。任何未确认的业务事实必须标记为待确认或 Demo，不得编造。若发现规范与仓库现实冲突，先列出冲突和影响，不要擅自作破坏性决策。

---

**文档结束**
