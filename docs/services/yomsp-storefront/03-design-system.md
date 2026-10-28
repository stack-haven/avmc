# 03 · 设计系统与组件体系

> 来源：原规范 §3（品牌与视觉设计规范）
> 上游：[02 页面规格](02-ia-and-pages.md) · 实现落点：[04 §5 目录结构](04-frontend-architecture.md#5-目录结构)

---

## 1. 设计目标

视觉需要体现**自然生态、专业饲养、产品可靠性**和设计感的品牌体验。

**避免**：廉价电商模板、过度装饰、全站纯黑金风格、过度拥挤的商品网格。

主视觉必须使用**真实且获得合法使用权**的爬宠及饲养环境摄影；**不得**用 AI 图像伪装成具体在售商品。

## 2. 视觉方向

| 维度 | 规范 |
|---|---|
| 主背景 | 暖白、象牙白、浅石灰色 |
| 主品牌色 | 森林绿 / 深苔绿；用于关键按钮、链接强调、少量大面积品牌区块 |
| 辅助色 | 木色、岩石灰、土壤棕、自然沙色 |
| 强调色 | 仅用于价格、可用状态、提示等**明确语义** |
| 图片 | 环境全景、产品结构、材质细节、安装/尺寸图；保持一致光线与色彩处理 |
| 排版 | 清晰层级、足够留白、适配俄语长词；**避免强行大写**（俄语可读性差） |
| 动效 | 轻量、目的明确，支持 `prefers-reduced-motion` |
| 图标 | 统一图标库或统一线性风格，**不混用多套视觉体系** |

## 3. Design Tokens

必须在 Tailwind theme / CSS 变量中**集中定义**。实际数值在首轮视觉实现后锁定。**页面禁止到处写任意颜色和间距。**

### 3.1 Token 清单（命名约定：CSS 变量 `--color-brand`，Tailwind `bg-brand` 等）

| 分类 | Token |
|---|---|
| 颜色 | `color-brand` `color-brand-strong` `color-background` `color-surface` `color-text` `color-muted` `color-border` `color-success` `color-warning` `color-danger` |
| 字体 | `font-body` `font-heading` |
| 圆角 | `radius-sm` `radius-md` `radius-lg` `radius-xl` |
| 阴影 | `shadow-card` |
| 容器 | `container-max` |
| 间距/断点 | 统一 spacing scale + 统一响应式断点 |

### 3.2 约束

- 所有颜色需满足可读性与对比度要求；交互控件必须有**可见焦点态**。
- 颜色**不能**作为唯一状态提示（见 [09 §3](09-quality-security-a11y.md#3-可访问性)）。
- Token 落地形态（Tailwind v4 `@theme` vs CSS variables + `@theme inline`）在 [04 §2 技术基线](04-frontend-architecture.md#2-技术基线) 锁定后一次性确定，**不得混用 v3/v4 写法**。

## 4. 三层组件体系

### 第一层：基础 UI（无业务知识）

`BaseButton` `BaseInput` `BaseSelect` `BaseCheckbox` `BaseRadio` `BaseBadge` `BaseModal` `BaseDrawer` `BaseTabs` `BaseBreadcrumb` `BaseSkeleton` `BaseEmptyState` `BaseAlert` `BasePagination`

### 第二层：业务组件

`ProductCard` `ProductGallery` `ProductPrice` `AvailabilityBadge` `ProductSpecTable` `CategoryCard` `HabitatBundleCard` `ProductGrid` `ProductCarousel` `ConfiguratorModuleCard` `ConfiguratorCanvas2D` `SectionRenderer` `GuideCard`

### 第三层：页面组合

首页各 Section、目录/筛选区、商品详情页、环境方案详情、设计器工作区、运营预览页。

### 4.1 硬规则

- 业务组件**禁止**直接读 localStorage、**禁止**直接拼 API URL；数据与状态经 composable / repository 注入。
- 基础组件**不含**商品业务规则（例如不得在 `BaseBadge` 内判断库存语义）。
- 每个交互组件必须覆盖：`default` `hover` `focus` `disabled` `loading` `error`（适用时）。

## 5. Tailwind 使用约束

1. 统一使用项目锁定的 Tailwind 主版本与配置方式，**不混用**不兼容的 v3/v4 写法。
2. 颜色、字号、圆角、阴影、容器宽度**必须**从 Tokens 引用。
3. **禁止**在页面反复复制同一段长 class 列表；高频样式封装为组件或可复用 variant。
4. **不强制**引入第二套 UI 组件库；先用自建基础组件，只有复杂无障碍交互明显需要时再评估（需经确认）。
5. 不用内联样式作为主要布局手段；仅对动态计算尺寸/位置等有明确理由的场景使用。
6. 页面需适配**窄屏 / 常见手机 / 平板 / 桌面宽屏**，不能只验证 1440px。
7. 俄语文本必须经过**实际布局测试**；避免硬编码固定宽度导致长词溢出。

## 6. 图片规范

- 所有图片提供明确用途、替代文本（alt）和合适尺寸；
- 优先 AVIF/WebP，并为需要的场景提供兼容方案；
- 首屏主图优先级加载，非首屏图片懒加载；
- 明确图片比例，避免 CLS；商品图片不应被错误裁切；
- **不把重要文字只放在图片中**；
- 只有获得使用权的图片才可进入生产；来源与授权记录进入 `docs/assets.md`（站点仓库内维护）；
- 商品图必须对应真实商品；概念图必须标注为示意图。

## 7. 落地状态（2026-10-28）

| 项 | 状态 | 位置 |
|---|---|---|
| Design Tokens | ✅ 已落地（数值为初稿，待视觉评审） | `storefront-service/app/assets/css/main.css`（Tailwind v4 `@theme`） |
| 第一层基础组件（14 个） | ✅ 已实现 | `storefront-service/app/components/base/` |
| 覆盖层焦点管理 | ✅ `useOverlay`（Esc / Tab 循环 / 焦点归还 / 滚动锁） | `storefront-service/app/composables/useOverlay.ts` |
| `/style-guide` | ✅ 覆盖 Tokens + 全部组件与状态 | `storefront-service/app/pages/style-guide.vue` |
| 第二层业务组件 | ⬜ Gate 3 | `app/components/{product,category,habitat,configurator,content,sections}` |
| 浏览器视觉 / 响应式验证 | ⬜ 待 Playwright（Gate 3） | 见 `docs/services/yomsp-storefront/11-open-items.md` L-9 |

> 实现细节与偏离说明记录在 `storefront-service/docs/architecture.md`，不在此重复。

## 8. 设计系统验收清单

- [ ] `/style-guide` 覆盖全部 Tokens 与三层组件
- [ ] 每个交互组件有 6 种状态展示
- [ ] 焦点可见、对比度达标
- [ ] `prefers-reduced-motion` 下动效降级
- [ ] 俄语长词（如 `инфракрасный обогреватель`）在 360px 宽度下不溢出
- [ ] 页面中无硬编码 hex 色值 / 任意间距（除明确动态场景）