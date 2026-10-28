# 09 · 质量、安全与可访问性

> 来源：原规范 §10（安全、隐私、性能与可访问性）、§14（验收标准 DoD）、§16（参考与核验）
> 上游：[04 架构](04-frontend-architecture.md) · [10 交付计划](10-delivery-plan.md)

---

## 1. 安全

- 所有输入在**服务端**验证；前端校验只用于体验。
- 运营配置与富文本**必须防 XSS**；禁止任意 HTML/JS 执行。
- 管理接口必须鉴权、授权与审计；**不能依赖前端隐藏按钮**作为权限控制（平台级约束，见 `.agents/REVIEW.md`）。
- 不将私钥、API token、数据库地址凭证写入客户端。
- 限制图片上传类型、大小与来源；上传场景后端需验证内容而非扩展名。
- 可能改变业务状态的请求使用 CSRF/鉴权/幂等机制（依据认证架构）。
- 错误日志不得泄露敏感数据。
- 不收集业务不需要的个人信息。

### 1.1 本阶段特有风险（Mock 站）

| 风险 | 缓解 |
|---|---|
| `/admin/homepage` Demo 页面被误当真实后台 | 强制 Demo 横幅；`routeRules` 生产 `noindex` + 仅非生产启用（或 IP/预览 token 保护）；页面内明确「不会写入生产」 |
| Demo 价格被搜索引擎/用户当成真实价格 | Demo 模式整体 `noindex`（生产接入真实数据前不开放索引）+ 页面内示例标注 |
| Mock 数据误入生产构建 | CI 产物断言（见 [06 §5.3](06-api-and-mock.md#53-生产隔离)） |
| localStorage 中的 Demo 配置被当作运营真相 | Repository 层封装 + 版本前缀 + 一键重置 |

## 2. 性能

- 首屏核心内容 SSR 输出；
- 首屏主图做尺寸与优先级优化（`fetchpriority` / `preload`）；
- 非首屏图片懒加载；
- 避免巨型依赖与不必要的客户端 JS；设计器等复杂交互**动态导入**；
- 控制布局位移：图片声明宽高/比例；
- API 使用合理缓存、超时与错误回退；
- 以**真实测试环境**评估 Core Web Vitals，不得只凭本地 dev server 下结论。

### 2.1 预算建议（Gate 2 后按基线校准）

| 指标 | 目标（移动端 p75，真实环境） |
|---|---|
| LCP | < 2.5s |
| CLS | < 0.1 |
| INP | < 200ms |
| 首屏 JS（gzip） | < 200KB（不含第三方） |

## 3. 可访问性

- 键盘可操作**所有核心功能**；
- 所有输入有 label；
- 图片有准确 alt（装饰图用空 alt）；
- 模态框管理焦点，关闭后还原焦点；
- 颜色**不能**是唯一状态提示；
- 支持焦点可见与合理对比度；
- 支持 `prefers-reduced-motion`；
- 设计器提供**文本清单**替代纯图形操作；
- 表单错误信息与对应字段关联（`aria-describedby`）。

## 4. 监控与日志

- 区分客户端错误、Nuxt SSR 错误、Go API 错误（三段独立处理）；
- 后端支持 request ID / trace ID 时贯穿请求链路；
- 不记录敏感 token 或不必要的用户信息；
- 生产提供健康检查、错误率与延迟监控（按现有基础设施实现）；
- **关键业务失败不能只在浏览器 console 中出现**。

## 5. 验收标准（Definition of Done）

### 5.1 工程

- [ ] 技术栈与锁定版本符合本文档，变更有决策记录
- [ ] lint / typecheck / test / build **实际运行**并记录结果
- [ ] 无未解释的 TypeScript 错误
- [ ] 关键组件与 Repository 有测试
- [ ] Mock 数据不会意外进入生产
- [ ] `.env.example`、README、架构文档齐全

### 5.2 视觉与交互

- [ ] 首页按规定区块顺序实现
- [ ] 视觉统一使用 Tokens 与共享组件
- [ ] 桌面 / 平板 / 手机布局可用
- [ ] 所有可见主按钮均有真实行为，或明确标注 Demo/未实现
- [ ] 空状态、错误、加载、禁用状态完整
- [ ] 俄语长文本不破坏布局
- [ ] 设计器移动端使用分步流程

### 5.3 业务真实性

- [ ] 没有虚构价格、库存、评价、销量、认证、客户数、物流与售后承诺
- [ ] Demo 数据有明确标识
- [ ] 商品与方案只显示真实可核验的兼容信息
- [ ] 购物车清楚说明不会创建真实订单/支付
- [ ] 没有把供应商/朋友的平台能力描述为品牌自有能力

### 5.4 SEO

- [ ] 公共页使用 SSR 或合理预渲染
- [ ] 初始 HTML 包含页面主内容
- [ ] title / description / canonical 正确
- [ ] sitemap 只含已发布且可索引页面
- [ ] robots / noindex 策略无冲突
- [ ] 404 等 HTTP 状态码正确
- [ ] Product/Offer/Breadcrumb/Article JSON-LD 与可见数据一致
- [ ] 无 localhost / test 域名进入生产 metadata

### 5.5 GEO / 内容

- [ ] 俄语内容有人工校对
- [ ] 专业饲养指南有可靠来源与适用范围
- [ ] 内容直接回答用户问题、结构清晰
- [ ] 无关键词堆砌、虚假专家背书或低质量批量内容
- [ ] 内容维护责任与更新时间策略明确

### 5.6 安全与可访问性

- [ ] 管理能力不对匿名用户开放
- [ ] 私密配置不进入客户端 bundle
- [ ] 富文本/用户输入经过安全处理
- [ ] 核心流程支持键盘操作
- [ ] 图片、表单、焦点与错误状态满足基本无障碍要求

## 6. 每个 Gate 的验证命令（目标态）

```bash
# 站点仓库 storefront-service/
pnpm install
pnpm lint          # eslint + stylelint
pnpm typecheck     # nuxt typecheck (vue-tsc)
pnpm test          # vitest run
pnpm test:e2e      # playwright（Gate 3+）
pnpm build         # nuxt build
pnpm check:demo    # 自定义：断言生产产物无 mock 痕迹
pnpm check:seo     # 自定义：抓取本地 build 的 SSR HTML 校验 metadata/canonical/JSON-LD
```

> 脚本名在 Gate 1 定稿后写入 `package.json`，并同步本文件与实际脚本，保持一致。

## 7. 参考与实现核验

实施时核对当前版本官方文档，避免使用过时 API：Nuxt（渲染模式、routeRules、data fetching、SEO metadata、部署）、Vue（Composition API、SSR）、Tailwind（主题变量、响应式、状态）、Google Search Central、Yandex Webmaster、OpenAPI 规范、Go 项目既有服务规范。