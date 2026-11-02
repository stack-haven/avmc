# 10 · 交付计划与 Gates

> 来源：原规范 §12（Vibe Coding 工作流程）、§13（实施顺序与优先级）、附录 A/B
> 上游：[09 DoD](09-quality-security-a11y.md#5-验收标准definition-of-done) · [11 Open Items](11-open-items.md)

---

## 1. Gate 状态

| Gate | 名称 | 状态 | 说明 |
|---|---|---|---|
| Gate 0 | 仓库审查与事实清单 | ✅ 完成（2026-10-28） | 见 [04 §1](04-frontend-architecture.md#1-gate-0--仓库审查事实2026-10-28) |
| Gate 1 | 技术基线与数据契约 | ✅ 完成（2026-10-28） | 决策与执行结果见 [04 §9](04-frontend-architecture.md#9-gate-1-决策记录-已确认并执行)；代码仓库 `storefront-service`（子仓库，已在根仓库 `.gitmodules` 登记） |
| Gate 2 | 设计系统与应用骨架 | 🟡 部分完成（2026-10-28） | Tokens、14 个基础组件、`useOverlay`、`/style-guide` 已完成并实测；**360/768/1440 浏览器视觉验证待 Gate 3 引入 Playwright 后补** |
| Gate 3 | Mock Repository 与核心公开页面 | ✅ 完成（2026-10-28） | 6 个 Mock Repository + 7 个页面；58 单测 / 10 E2E / 产物零 Mock 断言通过 |
| Gate 4 | 首页运营配置原型 | 🟡 基础版已随 Gate 3 落地 | 启用/排序/本地发布可用；字段级 schema 校验与预览 token 待补 |
| Gate 5 | Go API 集成 | ⏸ 暂缓（**本阶段明确不做**） | 后端未开发 |
| Gate 6 | SEO/GEO 技术验收 | 🟡 基础项已落地 | canonical/hreflang/og 已按语言输出；sitemap/robots 待补 |
| Gate 7 | 质量与交付 | ⬜ 未开始 | — |

> 与规范原文的差异：Gate 5（Go API 集成）在本阶段**不执行**，以 Mock 为主交付；`ApiXxxRepository` 只留骨架。

---

## 2. Gate 1 · 技术基线与数据契约

**产出**

1. 锁定版本与包管理器（`package.json` + `pnpm-lock.yaml` + `.nvmrc`）；
2. 确定路由、SSR 策略、Tailwind Tokens 形态、组件规范；
3. 对照 Go API 确定真实 endpoint —— **本阶段无后端，转为 Open Items**；
4. 确定 Demo 数据隔离方案；
5. 形成 `docs/architecture.md`、`docs/api-contracts.md`、`docs/decisions/0001..000N`。

**门禁**：D1–D6 全部确认后才允许 `pnpm create nuxt` / 安装依赖。✅ 已通过（D6 远程仓库除外）。

## 3. Gate 2 · 设计系统与应用骨架

**产出**

1. 全局布局、`Header` / `Footer` / `DemoBanner`、容器、Tokens 落地；
2. 14 个基础组件 + `/style-guide`；
3. 响应式断点与无障碍状态；
4. 移动端 + 桌面端验证截图。

**暂不做**：批量堆砌业务页面。

**验证**：`pnpm dev` 下 `/style-guide` 覆盖全部状态；360 / 768 / 1440 三档截图。

## 4. Gate 3 · Mock Repository 与核心公开页面

严格按顺序，**每个页面完成状态/响应式/语义化/metadata/组件复用后再进下一页**：

| 序 | 页面 | 完成判据 |
|---|---|---|
| 1 | `/` 首页 | 9 区块顺序正确、Section Registry 可用、Demo 标识可见 |
| 2 | `/catalog` + `/catalog/[category]` | 筛选/排序/分页/空态/错误态完整，URL 可分享 |
| 3 | `/products/[slug]` | 首屏 SSR 含名称/SKU/规格；无价格时显示"价格待确认"；面包屑 |
| 4 | `/habitats` + `/habitats/[slug]` | 区分购买/设计器/人工确认；示意图标注 |
| 5 | `/guides` + `/guides/[slug]` | 内容来自结构化数据而非硬编码；更新时间/来源字段 |
| 6 | `/configurator` | 桌面三栏 + 移动分步；兼容性阻断；列表清单可访问；localStorage 经 repository |
| 7 | `/cart` | 演示声明明显；数量/删除/合计；无支付相关文案 |

**Mock 规则**：见 [06 §5](06-api-and-mock.md#5-mock-数据要求)。

## 5. Gate 4 · 首页运营配置原型

- 定义 Slot、Section Registry、Section schemas；
- 建立首页 Section 配置（8 个 Slot 一一对应）；
- 实现编辑 / 预览 / 发布状态的**本地 Demo**；
- 公开首页只读 `published`；
- 测试无效配置与无可用商品情况；
- localStorage 限制在 Repository 层。

## 6. Gate 5 · Go API 集成（⏸ 本阶段不做）

保留触发条件，供后续启用：

- 后端 `storefront` 契约确认并可用；
- 以真实 API 替换 Mock Repository；
- 运行时校验响应；
- 处理超时、空数据、404、不可用、字段缺失；
- 确认 SSR 请求不泄露私密凭证；
- 价格、库存、兼容性以 Go 为准。

## 7. Gate 6 · SEO/GEO 技术验收

按 [07 §2 清单](07-seo-geo.md#2-技术基础清单) + [07 §9 自动化测试](07-seo-geo.md#9-seo-自动化测试ci-必做) 执行；确认无虚假价格/评价/库存/政策；验证状态码、重定向、筛选 URL 与 noindex；检查俄语内容与术语；建立内容发布 checklist。

## 8. Gate 7 · 质量与交付

运行仓库中**实际存在**的命令；缺少脚本时先补齐合理脚本：lint / typecheck / unit+component tests / build / 必要 E2E / SSR HTML 检查 / SEO 自动检查 / 响应式人工检查。

**提交物**：完整文件清单、实际命令与输出摘要、未完成事项、生产接入步骤、`.env.example`、README、截图/验收记录、已知限制与后续优先级。

---

## 9. P0–P3 优先级

### P0（必须先完成）

1. 仓库审查 ✅
2. 技术版本锁定
3. Design Tokens 与基础组件
4. Repository / API 契约（Mock 形态）
5. SSR 首页骨架
6. 商品目录与详情
7. SEO metadata / canonical / sitemap / robots 基础
8. Demo / 生产数据隔离
9. 构建与测试流程

### P1（核心业务体验）

1. 环境方案
2. 2D 模块化设计器
3. 首页动态 Section
4. 运营预览/发布原型
5. 指南内容系统
6. 移动端交互打磨
7. 结构化数据与性能优化

### P2（真实业务接入）

1. 真实商品/SKU/价格/库存 API
2. 真实首页发布配置
3. 兼容性规则 API
4. 联系/咨询表单（含防垃圾与隐私策略）
5. 分析工具与转化事件
6. 真实购物车/订单/支付（商业与合规条件确认后）

### P3（增长迭代）

内容运营工作流与审核 · 搜索与高级筛选 · 站内搜索索引 · 多语言 · 更高级设计器 · SEO/GEO 实验与转化优化。

---

## 附录 A · Agent 启动提示词（第一轮）

> 你正在实现 YOMSP 俄罗斯爬宠用品独立站。先完整阅读 `docs/services/yomsp-storefront/`（README → 01 → 02 → 04 → 06），把它当作业务与工程约束。
>
> **当前只执行 Gate 0：仓库审查与事实清单。不要立即编码，不要重构，不要安装或升级依赖。**
>
> 检查仓库目录、技术栈版本、lockfile、Nuxt/Vue/TS/Tailwind 配置、现有组件与页面、测试脚本、CI/CD、环境变量、Go API 契约、现有 SaaS 服务与部署方式。识别哪些要求已满足、哪些可复用、哪些冲突、哪些缺失。
>
> 输出：① 当前工程事实（附路径与证据）；② 与规范冲突处；③ 可复用模块与不确定事项；④ P0–P3 分阶段计划；⑤ 需业务方确认的阻塞项；⑥ 建议新增/修改文件清单；⑦ lint/typecheck/test/build 的实际状态（若执行不会修改文件）。
>
> 不要虚构仓库文件、API endpoint、业务数据或命令结果。发现缺少真实商品数据/API/部署信息时记录为 Open Item，并提出隔离 Mock 的实现建议。输出审查报告后**停止**，等待确认再执行下一阶段。

## 附录 B · 后续阶段通用提示词

> 只实施已经批准的当前 Gate，不提前实现后续阶段。开始前复述本阶段目标与验收标准；先读相关代码与文档；保持已有架构与技术栈；小步、可测试地变更。完成后运行**实际可用**的 lint / typecheck / test / build，并报告真实结果、修改文件、验证方式、遗留问题。任何未确认的业务事实必须标记为待确认或 Demo，不得编造。若规范与仓库现实冲突，先列冲突与影响，不擅自做破坏性决策。

## 内容区/物种模块交付状态（2026-11）

| Phase | 内容 | 状态 |
|---|---|---|
| A | 内容契约 + demo 路由 + repositories + sitemap/robots + 单测 | ✅ |
| B | 知识库 UI（索引/详情 Read 模式）+ 指南合并方案 B + JSON-LD | ✅ |
| C | 物种 hub（清单/阅读路径/参数侧栏）+ 首页物种条 + 商品反查 chips + E2E | ✅ |
| D | /admin/content 原型 + 交叉链接收口 + 设计门禁复测 + 文档同步 | ✅ |

门禁：typecheck/lint/unit(35)/E2E(33)/check:demo(228)/check:i18n 全绿；
taste-skill 新页 = 基线 2 FAIL 或已记录可辩护项；hallmark 33 FAIL 基线不增。

## 物种扩容 + 首页动线调整（2026-11，人工验收反馈）

> 触发：人工验收通过 Journal + Species 后提出两点——物种模块上移到 hero 之后；4 个物种太少。

| 项 | 内容 | 状态 |
|---|---|---|
| R1 | 调研：全球热门爬宠分层（Tier A/B/C）+ 淘汰理由 + 俄语市场适配 | ✅ `docs/research-species-expansion.md` |
| R2 | 物种 4 → 19：新增守宫 3 / 蜥蜴 3 / 蛇 4（新类群）/ 龟 3（新类群）/ 蛙 2 | ✅ |
| R3 | 配套商品 11 个（大箱体/竖箱/湿舱/温湿度计/浅水盘/12% UVB/白杨木屑/水龟三件套/晒台） | ✅ `p-025…p-035` |
| R4 | 配套方案 4 个（蛇类 120 / 干旱 150 / 陆龟 120 / 水龟 100） | ✅ `h-006…h-009` |
| R5 | 配套文章 12 篇（物种 8 + 跨物种 4），三语，接入 readingPath | ✅ `a-007…a-018` |
| R6 | 首页 `home.species_strip` 上移到 hero 之后（`sortOrder` 15），9 个精选物种 | ✅ |
| R7 | 物种呈现改为「缩略图 + 名称」选择行：19 种里只有 4 种有核验照片，照片瓦片会把 15 格变成坏图 | ✅ |
| R8 | 缺图策略：类型层 `image?` 可选 + 设计化占位（纹理缩略图），不借位近缘物种照片 | ✅ |
| R9 | 数据完整性单测（引用商品/文章/方案全存在）+ 9 条 E2E | ✅ |

门禁：typecheck/lint/unit(45)/E2E(47)/check:demo(232)/check:i18n 全绿；
taste-skill `/` `/species` `/journal` `/catalog` = 2 FAIL 基线，`/species/[slug]` = 4 FAIL 基线；hallmark 33 FAIL 不增。
未完成：15 个新物种照片（L-27）、调研结论外部来源核验（L-28）。

## 首页重排（方案 B，2026-11 人工验收反馈第二轮）

> 触发：物种模块上移后整体协调度变差；用户要求①信任条回到物种选择之上②物种作为重点展示③只重排不改内容。

| 项 | 内容 | 状态 |
|---|---|---|
| O1 | 体验诊断 7 条（入口三重叠加/位置重量错配/信任夹心/卖什么太晚/节奏断裂/提及倒挂/移动过长） | ✅ 见对话记录 |
| O2 | 新顺序：hero → **trust(night)** → **species 重点带** → categories → featured → habitats → **entry_cards 下移** → configurator → journal | ✅ 仅改 `sortOrder` |
| O3 | 深色同步：信任条新增 `config.tone: 'night'`（运营可配），与 hero/物种带共用 night 画布，开场章不被浅色切断 | ✅ |
| O4 | 物种带呈现：桌面 3×3 tile、移动 2 列紧凑行（名字两行不截断）；去装饰编号；scrim 仅照片 tile | ✅ |
| O5 | 夜间纹理资产 `scale-pattern-night.svg` + `scale-bg-night` utility（平铺，不拉伸） | ✅ |
| O6 | `SectionRenderer` 输出 `data-section`，E2E 以章节序列断言顺序与同画布（computed backgroundColor 相等） | ✅ |
| O7 | 门禁：unit 45 / E2E 48 / check:demo 230 / i18n / taste `/` = 基线 2 FAIL / hallmark 33 不增 | ✅ |
