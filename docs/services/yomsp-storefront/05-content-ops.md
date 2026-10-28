# 05 · 首页内容运营架构

> 来源：原规范 §5（动态内容运营架构）
> 上游：[02 首页区块顺序](02-ia-and-pages.md#2-首页-) · 数据落点：[06 Mock 规范](06-api-and-mock.md)

---

## 1. 核心模式

**固定页面模板 + 固定 Slot 定义 + 可配置 Section 实例 + 结构化内容引用 + 真实业务数据 + 预览发布机制。**

**不建设**无限制的拖拽式装修器。运营人员只能配置**已经注册、经过测试**的 Section 类型和字段。

## 2. 固定首页 Slot

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

Slot 是**前端定义的能力边界**，不由运营人员任意创建。

## 3. Section Types

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

`Section Registry` 把已注册的 `sectionType` 映射到具体组件。**未知类型必须安全降级并记录错误**：不执行任意代码、不导致整页崩溃。

### 3.1 Slot ↔ SectionType 允许组合

| Slot | 允许的 sectionType |
|---|---|
| `home.hero` | `hero_banner` |
| `home.trust_strip` | `trust_strip` |
| `home.entry_cards` | `entry_cards` |
| `home.popular_categories` | `category_grid` |
| `home.featured_products` | `product_grid` \| `product_carousel` |
| `home.habitat_bundles` | `habitat_bundle_grid` |
| `home.configurator_banner` | `configurator_banner` |
| `home.buying_guides` | `editorial_guide_grid` |

## 4. 运营配置字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | Section 实例 ID |
| `pageKey` | `'home'` | 页面标识 |
| `slotKey` | `HomeSlotKey` | 所属 Slot |
| `sectionType` | `SectionType` | 渲染组件类型 |
| `title` | string? | 区块标题 |
| `enabled` | boolean | 是否启用 |
| `sortOrder` | number | 排序 |
| `selectionMode` | `manual \| rule_based \| collection` | 选品方式（第一阶段只用 `manual`） |
| `productIds` / `categoryIds` / `habitatIds` / `guideIds` | string[]? | 仅适用类型 |
| `collectionId` | string? | 后续需要时启用 |
| `itemLimit` | number? | 上限 |
| `startAt` / `endAt` | string? | 时间窗 |
| `fallbackPolicy` | `hide \| show_empty_state \| fill_from_rule` | 兜底策略 |
| `status` | `draft \| published \| archived` | 状态 |
| `version` | number | 版本号 |
| `updatedAt` / `updatedBy` | string? | 真实接入后台后才填 |
| `config` | Record<string, unknown> | 必须经对应 schema 校验 |

第一阶段以**手动选取 + 手动排序**为主；规则选品和可复用集合后续扩展。

## 5. 商品引用与权威数据

- 推荐区块**只保存商品 ID/SKU 引用和顺序**，不复制价格/库存作为权威值。
- 渲染时读取商品 API 的**当前**数据。
- 缺货/停售商品不得作为正常可售商品误导用户；若保留展示须清楚标记状态。
- 备用策略必须**显式配置**：自动补位 / 隐藏缺位 / 显示空状态；**不能静默替换成不相关商品**。
- 无可用商品时，默认隐藏区块或显示符合设计的空状态。
- API 失败时使用错误/重试/缓存回退策略，**不能无声地把过期价格当作当前价格**。

## 6. Draft / Preview / Publish

```text
1. 编辑 Draft
2. 用 Preview Token 或受保护预览路由查看 Draft
3. 校验字段、引用、时间窗口、排序、商品可售状态
4. 发布
5. 发布生成版本号并记录审计信息
6. 公开首页只读取 Published 配置
7. 更新相关缓存
8. 支持查看当前发布版本与回滚（后端能力允许时）
```

### 6.1 本阶段（无后端）的落法

- 全部模拟逻辑封装在 `homepage.repository.ts`；**组件不得直接访问 localStorage**；
- localStorage key 统一前缀（如 `yomsp:demo:homepage:v1`），支持"重置为默认 Demo 配置"；
- 页面顶部与 `/admin/homepage` 均显示 **Demo / 本地预览** 标识；
- 后续切换真实 API 时，**页面与 Section 组件不应重写**——只替换 repository 实现。

## 7. 配置运行时校验

每种 Section Type 有独立 Zod schema，校验：

1. slot 与 sectionType 的允许组合（见 §3.1）；
2. `itemLimit` 合理范围、日期格式、引用 ID 类型、文本长度、URL 合法性；
3. **禁止**注入任意 HTML/JS；
4. 富文本必须安全净化；**优先结构化字段**而不是允许任意 HTML。

无效配置的行为：记录错误（可观察，不只 console）+ 采用安全空状态或忽略该 Section。**不得整页崩溃。**

## 8. 验收要点

- [ ] 未知 `sectionType` 不渲染且记录错误，其余区块正常
- [ ] 无效 `config` 被 schema 拦截并降级
- [ ] 公开首页只读 `published`；`draft` 仅预览路由可见
- [ ] `fallbackPolicy` 三种策略行为可验证
- [ ] 组件层零 `localStorage` 调用（用 grep 断言）
- [ ] Demo 配置可一键重置