# 04 · 前端架构与代码落点

> 来源：原规范 §2（技术架构与工程原则）、§11（环境变量与配置管理）+ Gate 0 仓库审查事实
> 上游：[01 产品范围](01-product-scope.md) · 下游：[06 API 与 Mock](06-api-and-mock.md)、[10 交付计划](10-delivery-plan.md)

---

## 1. Gate 0 · 仓库审查事实（2026-10-28）

| # | 事实 | 证据 |
|---|---|---|
| 1 | 根仓库 `avmc` 是 Ark Tech Platform 文档 + 三子仓库聚合仓 | `.gitmodules`：`frontend-service`、`backend-service`、`mobile-desktop-service` |
| 2 | `frontend-service` 是 **Vben Admin 5.7.0** pnpm + Turbo monorepo，定位为**管理后台** | `frontend-service/package.json`（`name: vben-admin-monorepo`，`preinstall: only-allow pnpm`，turbo 脚本） |
| 3 | `frontend-service/apps` 全部是后台/示例应用，**无公开站点、无 Tailwind、无 Nuxt** | `apps/{web-antd-admin,web-antd,web-ele,...}`；`grep tailwind` 仅命中 `packages/@core/base/shared`；仓库内无 Nuxt 依赖 |
| 4 | 仓库内**不存在** storefront 相关代码、proto 或契约 | `backend-service/proto/{ai,common,evie,packages,platform,version}`；全仓 grep `storefront\|yomsp` 无命中 |
| 5 | 根 `packages/` 仅剩空目录脚手架（无提交文件） | `find packages -type f` 无输出 |
| 6 | 本地 Node **v22.19.0**，pnpm 9.12.0，npm 10.9.3 | `node -v && pnpm -v` |
| 7 | Nuxt 最新版 4.6.3 要求 `node ^22.22.3 \|\| ^24.15.0 \|\| >=26`，**当前 Node 不满足**；Nuxt 4.5.2 要求 `^22.19.0`，**满足** | `npm view nuxt@<v> engines.node` |
| 8 | 最新稳定依赖：vue 3.5.44 / tailwindcss 4.3.3 / @tailwindcss/vite 4.3.3 / zod 4.6.7 / pinia 4.1.0 / vitest 5.0.5 / @playwright/test 1.64.1 | `npm view <pkg> version` |
| 9 | 文档中心已有服务文档范式：`docs/services/<service>/01-...07-...md` + README 导航 | `docs/services/geo-content-engine/` |
| 10 | 平台规定「新增产品服务前先登记 `docs/services`」「端承载层子仓库平级」 | `docs/services/README.md`、`.agents/AGENTS.md` §端承载三分天下 |

### 1.1 与规范冲突 / 需澄清的点

| # | 冲突 | 处理建议 |
|---|---|---|
| C1 | 规范 §2.4 给出的是 **Nuxt 3 风格**目录（根级 `app.vue`/`pages/`）；Nuxt 4 默认 `srcDir = app/` | **选 Nuxt 4.5.x → 采用 `app/` 结构**（见 §5）。两套结构不能混用，必须在 Gate 1 一次性定死 |
| C2 | 规范说 "兼容当前仓库与部署的稳定版本"，但仓库内没有任何 Nuxt 应用可对齐 | 以「Node 现有能力 + 最新稳定」为准，见 §2 |
| C3 | `frontend-service` 定位是管理后台，不宜承载公开 SSR 站点 | 新建独立子仓库（见 §4），并同步更新 `.gitmodules` / `AGENTS.md` / `RULES.md` 结构表 |
| C4 | 规范要求管理中台用 Vben，但本阶段不做后端 → `/admin/homepage` 只能是纯前端 Demo | 保留路由但强制标注"Demo / 本地预览"，不接真实权限；真实运营后台后续落 `frontend-service` |

---

## 2. 技术基线（✅ 已锁定 2026-10-28，已装并验证）

| 层 | 选型 | 锁定版本 | 选定理由 |
|---|---|---|---|
| 运行时 | Node | **22.19.0**（`.nvmrc` + `engines`） | `nuxt@4.5.2` 的 `engines` 为 `^22.19.0`；`@nuxt/cli@3.37.0` 为 `>=18`，工具链可运行 |
| 框架 | Nuxt | **4.5.2**（精确锁定） | 4.6.x 要求 `node ^22.22.3`，当前环境不满足；4.5.2 为兼容上限内最新稳定 |
| UI | Vue / vue-router | 3.5.44 / 5.4.0 | 随 Nuxt 依赖链（nuxt 要求 `vue ^3.5.40`、`vue-router ^5.2.0`） |
| 类型 | TypeScript | 5.9.3 | 刻意不采用 7.x（原生移植版）作为生产基线 |
| 样式 | Tailwind CSS **v4** + `@tailwindcss/vite` | 4.3.3 | v4 官方 Vite 集成；**不用** `@nuxtjs/tailwindcss`（v3 时代模块） |
| 运行时校验 | Zod | 4.6.7 | Section 配置、API 响应校验 |
| 状态 | Composition API 为主；Pinia + `@pinia/nuxt` | 4.1.0 / 1.0.3 | `@pinia/nuxt` peer 明确要求 `pinia ^4.1.0` |
| 测试 | Vitest + `@nuxt/test-utils` | 5.0.5 / 4.3.4 | `@nuxt/test-utils` peer 支持 `vitest ^5`、`nuxt ^4` |
| Lint | ESLint + `@nuxt/eslint` | **10.13.0** / 1.17.0 | `@nuxt/eslint-config` 内部 `@eslint/js@10` 与 `eslint-plugin-unicorn@73` 要求 `eslint ^10`，故用 10 而非 9 |
| 多语言 | `@nuxtjs/i18n` | 10.6.0（vue-i18n 11.4.x） | 官方模块；`prefix_except_default`，默认 `ru`，`zh` 走 `/zh/**` |
| E2E | `@playwright/test` | 1.64.1（Chromium） | 响应式 / SSR / 404 / i18n 回归 |
| 包管理 | pnpm（独立 lockfile） | 9.12.0 | 与平台其他前端子仓库一致 |

**兼容性验证方式**：逐包 `npm view <pkg> engines/peerDependencies` 交叉核对 + `pnpm install` peer 告警审阅。
唯一残留告警：`@nuxt/cli@3.37.0` → `@bomb.sh/tab` 声明 `cac@^6` 与 hoisted `cac@7` 不符，仅影响 shell 补全，不影响构建运行。

> 若后续把 Node 升到 22.22+/24，可平滑升级到 Nuxt 4.6.x；届时需重跑本表与 CI 验证。

### 2.1 不引入的东西（第一版）

- 不引入第二套 UI 组件库（Ant Design Vue / Element Plus 等）——公开站点自建基础组件；
- ~~不引入 i18n 框架~~ → **已引入**（2026-10-29 用户要求）：默认 `ru` + `zh` 语言包，
  UI 文案全部走 locale 文件，`hreflang` 按语言输出（见 §9.3）；
- 不引入 3D 引擎；
- 不做 Turbo monorepo（单应用足够，共享契约走 `backend-service/proto` 生成）。

---

## 3. 系统边界

```
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
Go API / 现有 SaaS 基础服务   ←—— 本阶段不存在，Mock Repository 顶替
```

硬规则：

- Nuxt **不得**直连数据库；**不得**把后端密钥写入浏览器代码。
- `runtimeConfig.public` 之外的一切视为服务端私密；API token、内部地址凭证只留在服务端。
- 价格、库存、可售状态、兼容性以 Go API 为权威；**前端不得复制一套价格/库存业务规则**。
- 不在 Nuxt 中新增 BFF 微服务；只有出现明确聚合/缓存/鉴权适配需求时再评估。
- Vben 管理端不要把后台页面塞进公开站点的可索引页面。

## 4. 代码落点建议 ⚠️ 待确认

### 4.1 三个候选方案

| 方案 | 位置 | 优点 | 缺点 | 结论 |
|---|---|---|---|---|
| **A. 新建子仓库** | `/avmc/storefront-service`（submodule，与 `frontend-service` 平级） | 独立部署（SSR 需 Node 运行时，与 Vben 静态托管不同）；独立 lockfile/CI；不污染 Vben 的 turbo/eslint/oxlint/cspell/lefthook 门禁；边界清晰 | 多一个仓库；需更新 `.gitmodules` 和平台结构文档 | ✅ **推荐** |
| B. 塞进 `frontend-service/apps/web-storefront` | Vben monorepo 内 | 复用 pnpm workspace、共享 `packages/locales` | Vben 的 `preinstall only-allow pnpm`、turbo 任务、lint 规则、`check:dep` 会覆盖 Nuxt 应用；Vue/Vite 版本被 Vben 锁死；`packages/@core` 是 admin UI，storefront 无法复用；**破坏 `frontend-service = Web 后台` 的既有定位** | ❌ 不推荐 |
| C. 完全独立的外部仓库 | 不在 `avmc` 内 | 品牌独立性最强 | 失去与平台契约同步、统一治理和子仓库指针机制 | ❌ 不推荐 |

### 4.2 推荐方案 A 的理由（关键 3 条）

1. **部署形态不同**：公开站点是 SSR/预渲染 + CDN，管理后台是 SPA 静态产物。混在一个 monorepo 会让 CI/部署流水线互相牵制。
2. **工具链冲突真实存在**：`frontend-service` 有 `preinstall: only-allow pnpm`、turbo pipeline、`vsh check-*`、oxlint/oxfmt/stylelint、lefthook。Nuxt 应用进同一个 workspace 会被这些规则套住，且 Vue/Vite 版本被 Vben 决定。
3. **边界规则已经写明**：`.agents/AGENTS.md` 与 `.agents/RULES.md` 明确「Web 后台功能归 frontend-service」「任何业务 API 契约定义在 backend-service/proto」。新增公开站点承载层应显式登记，而不是偷塞进后台仓库。

### 4.3 采用方案 A 后需要同步的文件（确认后执行）

```
.gitmodules                                     # 新增 storefront-service
.agents/AGENTS.md                               # 仓库结构 + 端承载表新增一行
.agents/RULES.md                                # 仓库结构 + 提交规则新增一行
docs/README.md                                  # 目录说明
docs/services/README.md                         # 产品服务/承载层登记（已预先登记）
CLAUDE.md                                       # 子仓库列表
storefront-service/                             # 新仓库（含自身 docs/、.env.example）
```

> ⚠️ 这是**平台结构变更**，属 `requires-confirmation` 档：需你明确批准后我再新建仓库与改上述文档。

---

## 5. 目录结构（Nuxt 4 `app/` 布局）

```text
storefront-service/
├── nuxt.config.ts
├── package.json
├── pnpm-lock.yaml
├── .nvmrc                      # 22.19.0
├── .env.example
├── tsconfig.json
├── eslint.config.mjs
├── vitest.config.ts
├── playwright.config.ts
├── app/
│   ├── app.vue
│   ├── error.vue
│   ├── assets/css/main.css     # Tailwind v4 @theme + tokens
│   ├── components/
│   │   ├── base/               # 第一层：无业务知识
│   │   ├── layout/             # Header / Footer / MobileNav / DemoBanner
│   │   ├── product/
│   │   ├── category/
│   │   ├── habitat/
│   │   ├── configurator/
│   │   ├── content/
│   │   └── sections/           # Section Registry 渲染目标
│   ├── composables/            # useRepositories / useSeo / useMoney / useDemoFlag
│   ├── layouts/                # default / minimal
│   ├── middleware/             # demo-guard / noindex
│   ├── pages/
│   │   ├── index.vue
│   │   ├── catalog/index.vue
│   │   ├── catalog/[category].vue
│   │   ├── products/[slug].vue
│   │   ├── habitats/index.vue
│   │   ├── habitats/[slug].vue
│   │   ├── guides/index.vue
│   │   ├── guides/[slug].vue
│   │   ├── configurator.vue
│   │   ├── cart.vue
│   │   ├── style-guide.vue
│   │   └── admin/homepage.vue
│   ├── plugins/                # repositories.ts（依赖注入）
│   ├── services/
│   │   ├── contracts.ts        # Repository 接口 + domain 类型引用
│   │   ├── api-client.ts       # baseURL/超时/错误映射/request-id
│   │   ├── mock/               # MockRepository 实现 + mock 数据
│   │   │   ├── fixtures/*.ts
│   │   │   └── *.mock-repository.ts
│   │   ├── api/                # ApiRepository（本阶段仅骨架，不接真实端点）
│   │   ├── product.repository.ts
│   │   ├── category.repository.ts
│   │   ├── habitat.repository.ts
│   │   ├── guide.repository.ts
│   │   ├── homepage.repository.ts
│   │   └── configurator.repository.ts
│   ├── stores/                 # cart.ts / configurator.ts（Pinia）
│   └── utils/                  # money / units / slug / seo 工具
├── shared/
│   ├── types/                  # 跨 app/server 的领域类型
│   └── schemas/                # Zod：Section、API 响应、筛选参数
├── server/
│   ├── api/                    # 仅必要的服务端适配（sitemap.xml、robots.txt、preview token）
│   └── utils/
├── public/                     # favicon、占位图（必须可识别为占位）
├── tests/
│   ├── unit/
│   └── e2e/
└── docs/
    ├── architecture.md
    ├── api-contracts.md
    ├── open-items.md
    ├── assets.md               # 图片授权记录
    ├── decisions/              # ADR
    └── qa/
```

### 5.1 与原规范目录的映射差异

| 原规范 | 本方案 | 原因 |
|---|---|---|
| 根级 `pages/ components/ composables/` | `app/` 下同名目录 | Nuxt 4 srcDir 约定 |
| `services/`、`types/`、`utils/` 在根 | `app/services`、`shared/types`、`app/utils` | `app/` 内代码可被 Vue 侧解析；跨端共享类型放 `shared/` |
| `tests/` | 保留根级 | 与 Vitest/Playwright 惯例一致 |
| `docs/` | `storefront-service/docs/` **+** 本目录（平台侧） | 平台侧保留产品/架构事实来源，仓库侧保留 API 契约、QA、资产授权 |

---

## 6. 渲染策略

| 路由 | 渲染 | 索引 |
|---|---|---|
| `/` | SSR + 缓存 | 可索引 |
| `/catalog` | SSR + 合理缓存 | 可索引 |
| `/catalog/:category` | SSR + 合理缓存 | 可索引，避免无限筛选 URL |
| `/products/:slug` | SSR | 核心商品信息必须进入初始 HTML |
| `/habitats`、`/habitats/:slug` | SSR + 缓存 | 可索引 |
| `/guides` | SSR 或预渲染 | 可索引 |
| `/guides/:slug` | 预渲染或 SSR | 可索引 |
| `/configurator` | SSR 外壳 + 客户端交互 | 介绍内容可索引；复杂状态不索引 |
| `/cart` | 客户端交互为主 | `noindex` |
| `/account/**` | 客户端交互为主 | `noindex`（第一版不实现账户） |
| `/admin/**` | 仅 Demo 预览 | 禁止索引 + 非生产才允许 |

实现方式：`nuxt.config.ts` 的 `routeRules` + 页面级 `useSeoMeta`。**必须验证实际部署环境**是否支持对应缓存/预渲染能力——本地开发正常 ≠ 生产 SSR 正常。

---

## 7. 环境变量

`.env.example`（占位值，不含真实密钥）：

```env
# 站点
NUXT_PUBLIC_SITE_URL=https://example.invalid
NUXT_PUBLIC_SITE_NAME=YOMSP
NUXT_PUBLIC_SITE_LOCALE=ru-RU

# 后端（本阶段无用，占位）
NUXT_API_BASE_URL=http://localhost:8080

# Demo / Mock
NUXT_PUBLIC_DEMO_MODE=true
```

| 变量 | 暴露范围 | 说明 |
|---|---|---|
| `NUXT_PUBLIC_*` | 浏览器可见 | 一律视为**可公开信息**，禁止放密钥 |
| `NUXT_API_BASE_URL` | 服务端 | 私有；客户端请求走同域代理或服务端转发 |
| `NUXT_PUBLIC_DEMO_MODE` | 浏览器可见 | 生产默认 `false`；**唯一** Demo 开关，同时控制 Mock 数据与全站 Demo 提示条（无法只开 Mock 不显示提示，避免“有假数据无提示”的危险组合） |

### 7.1 约束

1. 生产域名必须由部署配置注入，**不得**硬编码到 canonical / sitemap / OG metadata。
2. **Demo 模式生产默认关闭**；缺少关键环境变量时生产启动应**明确报错**，不得静默退回 demo。
3. `NUXT_PUBLIC_DEMO_MODE=true` 时页面必须有可见 Demo 标识（见 [06 §5](06-api-and-mock.md#5-mock-数据要求)）。

---

## 8. Mock / API 切换机制（本阶段核心）

```ts
// app/services/contracts.ts
export interface Repositories {
  product: ProductRepository
  category: CategoryRepository
  habitat: HabitatRepository
  guide: GuideRepository
  homepage: HomepageRepository
  configurator: ConfiguratorRepository
}
```

```ts
// app/plugins/repositories.ts
export default defineNuxtPlugin(() => {
  const { demoMode } = useRuntimeConfig().public
  const repos: Repositories = demoMode ? createMockRepositories() : createApiRepositories()
  return { provide: { repos } }
})
```

规则：

- 页面只依赖 `useRepositories()`，**不依赖具体实现**；
- **禁止**在页面里写 `if (demoMode)` 分支；
- Mock 数据只被 `app/services/mock/` 引用，生产构建不得打包进主 chunk（用 `import.meta.dev` / 动态 import 隔离，并在 CI 加一条构建产物检查）；
- `createApiRepositories()` 本阶段**只保留骨架**，不写入猜测的 endpoint（见 [06 §3](06-api-and-mock.md#3-建议-api-资源open-items)）。

## 9. Gate 1 决策记录（✅ 已确认并执行）

| # | 决策 | 结论 | 状态 |
|---|---|---|---|
| D1 | 代码位置 | 新建子仓库 `storefront-service`（方案 A） | ✅ 本地已 `git init -b coding/ai` 并提交首个 commit |
| D2 | Node / Nuxt | Node 22.19.0 + Nuxt 4.5.2 | ✅ `.nvmrc` + `engines` + 精确版本锁定 |
| D3 | 样式方案 | Tailwind v4 + `@tailwindcss/vite` | ✅ 已接入，Tokens 落在 `app/assets/css/main.css` |
| D4 | 状态管理 | Composition API 为主 + Pinia（仅购物车/设计器） | ✅ 模块已注册，Gate 1 尚无 store |
| D5 | 目录结构 | Nuxt 4 `app/` 布局 | ✅ 已按 `app/` 落地 |
| D6 | 远程仓库 | 待用户提供地址/命名（建议 `avmc-storefront-service`） | ⏳ 阻塞 submodule 登记 |

### 9.1 D6 未决期间的处置

✅ 已完成：远程 `stack-haven/avmc-storefront-service`（默认分支 `coding/ai`）已创建并推送；
根仓库 `.gitmodules` 已登记，`.agents/AGENTS.md` / `RULES.md` / `CLAUDE.md` 结构表已同步。

### 9.3 多语言（2026-10-29 新增）

| 项 | 结论 |
|---|---|
| 框架 | `@nuxtjs/i18n` 10.6.0，`strategy: prefix_except_default` |
| 语言 | `ru`（默认，无前缀）、`zh`（`/zh/**`） |
| 文案边界 | **UI 走 locale 文件**；商品/指南等**内容来自数据源，不翻译**（翻译内容 = 伪造内容） |
| SEO | `usePageSeo` 统一生成 title/description/canonical（当前语言）/hreflang（ru-RU、zh-CN、x-default）/og/JSON-LD |
| 域名来源 | 只用 `NUXT_PUBLIC_SITE_URL`；**不用** i18n 的 `baseUrl`，避免 canonical 与 hreflang 域名不一致 |
| 守卫 | `pnpm check:i18n` 断言两语言 key 一致 + 代码引用 key 必须存在 |
| 待办 | 内容本地化需后端本地化字段支持（`11-open-items.md` L-17） |

### 9.2 执行期发现的偏差（已修正）

| 偏差 | 处理 |
|---|---|
| `routeRules.robots` 不在 Nuxt 4.5 类型中 | 改用 `headers: { 'X-Robots-Tag': 'noindex, nofollow' }`（标准响应头，`typecheck` 通过） |
| `NUXT_PUBLIC_DEMO_BANNER` 独立开关存在"有 Mock 无提示"风险 | 合并为单一 `NUXT_PUBLIC_DEMO_MODE`，开 Mock 必显提示 |