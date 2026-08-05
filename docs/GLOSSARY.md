# Ark Tech Platform 术语表（Glossary）

> 统一业务与技术语言。本文档是项目内所有文档、代码、讨论的术语权威来源。
> 新增术语须在本表登记，避免同义多词或一词多义。

---

## 架构概念

| 术语 | 英文 | 定义 |
|------|------|------|
| **Ark Tech Platform** | — | 面向多产品 SaaS 的技术平台与业务承载底座，提供多租户、认证授权、数据隔离、菜单权限、业务套餐、资源配额、操作审计、参数配置、异步任务、文件、通知和产品服务接入能力 |
| **平台控制面** | Platform Control Plane | 平台管理员的全局操作域：租户生命周期、套餐配置、存储渠道、全局审计。需要 `platform_operator=true` 四重校验 |
| **租户数据面** | Tenant Data Plane | 租户成员的操作域：用户管理、文件操作、参数覆盖。`tenant_id` 由 auth context 注入，不来自客户端 |
| **产品层** | Product Layer | 四层架构最上层，包含 GEO Engine、AI Agent Management 等具体业务产品 |
| **业务中台** | Business Platform | 跨产品商业化能力层（产品注册/客户运营/订阅计费/渠道佣金） |
| **技术中台** | Platform Foundation | 通用技术底座（租户/认证/审计/任务/文件/通知），不含业务逻辑 |
| **基础设施** | Infrastructure | 数据库、缓存、对象存储、消息队列 |

---

## 租户与多产品

| 术语 | 英文 | 定义 |
|------|------|------|
| **租户** | Tenant | 一个客户企业。一个租户可开通多个产品线，产品线间数据在租户内隔离 |
| **多产品叠加** | Multi-Product Overlay | 一个租户开通多个产品线的能力，各产品线数据独立隔离 |
| **租户生命周期** | Tenant Lifecycle | `PENDING → ACTIVE → SUSPENDED / EXPIRED → CANCELLED` 状态机 |
| **原子开通事务** | Atomic Provisioning Transaction | 租户+菜单权限组+部门+管理员在一个事务内创建，全成功或全回滚 |
| **产品线** | Product Line | 租户开通的某个产品服务实例（如 GEO Engine） |
| **租户编码** | Tenant Code | 租户唯一标识，系统生成，不接受客户端指定 |

---

## 认证与授权

| 术语 | 英文 | 定义 |
|------|------|------|
| **防御深度** | Defense in Depth | 多层安全校验：网关(JWT)→应用(tenant_id 强制)→ORM(Ent Privacy)→数据库(外键校验)。每层独立 |
| **四重校验** | Four-Factor Verification | 平台控制面的安全约束：`is_platform=true` + JWT `platform_operator=true` + Casbin 平台策略 + 中间件 |
| **代管会话** | Managed Session | 业务员以客户身份操作时签发的短生命周期 Token，绑定目标租户，敏感操作拦截 |
| **平台身份** | Platform Identity | 平台管理员的全局身份，跨租户操作能力 |
| **租户身份** | Tenant Identity | 用户在特定租户内的身份，`tenant_id` + `user_id` + `roles` 组成 |
| **JWT** | JSON Web Token | Access Token（短有效期）+ Refresh Token（长有效期）轮换机制 |
| **Casbin** | — | RBAC 策略引擎，管理角色-权限映射关系 |
| **RBAC** | Role-Based Access Control | 基于角色的访问控制，权限通过角色授予 |

---

## 套餐与配额

| 术语 | 英文 | 定义 |
|------|------|------|
| **租户菜单权限组** | Tenant Menu Permission Group | 菜单权限 + API 权限 + 功能开关 + 资源配额的聚合体，绑定到租户 |
| **菜单权限组版本** | Permission Group Version | 不可变版本快照，支持发布/回滚，防止意外修改影响已绑定租户 |
| **能力包** | Capability Pack | 套餐 = 菜单权限 + API 权限 + 功能开关 + 资源配额 |
| **Feature Flag** | — | 功能开关，四阶段生命周期：创建→灰度→全量→废弃→清理 |
| **软/硬限制** | Soft/Hard Limit | 超额策略：soft=允许但记录超额费用，hard=拒绝操作返回 403 `QUOTA_EXCEEDED` |
| **幂等键** | Idempotency Key | 资源额度占用/释放的去重标识，防止重复操作 |

---

## 数据与权限

| 术语 | 英文 | 定义 |
|------|------|------|
| **数据权限** | Data Permission | 五级数据范围：全部数据 / 本人数据 / 本部门数据 / 本部门及下级数据 / 自定义范围 |
| **部门层级链** | Department Ancestor Chain | 部门层级祖先链，带循环检测，支持数据权限向上汇总 |
| **数据隔离** | Data Isolation | 租户间数据在应用层（tenant_id 强制）和存储层双重隔离 |
| **产品间数据隔离** | Cross-Product Data Isolation | 产品 A 不能直接访问产品 B 的数据库表，跨产品数据交换走 API |
| **append-only** | — | 操作审计日志只追加不修改不删除，保证审计完整性 |

---

## 工程实践

| 术语 | 英文 | 定义 |
|------|------|------|
| **大仓模式** | Monorepo | `backend-service` 保持单一 Go module，`app/` 下按模块划分，保留未来独立服务拆分能力 |
| **契约优先** | Contract First | 所有 API 变更先更新 Proto 文件，再生成代码。Proto 是唯一事实来源 |
| **产品注册制** | Product Registry Pattern | 新产品上线走配置注册（编码/菜单/定价/配额/表单），不改中台代码 |
| **断点续接** | Breakpoint Continuation | 中断后回来的标准流程：读 README→路线图→专题文档→最近提交 |
| **执行守门规则** | Gatekeeper Rules | 后端开发必须按序执行：Proto→API(生成)→Service→Biz→Data→Ent→Wire→Test |
| **生成代码不手改** | Generated Code Immutability | API、Ent gen、OpenAPI、Swagger UI bundle 只由源文件生成，不手工修改 |

---

## 异步与事件

| 术语 | 英文 | 定义 |
|------|------|------|
| **租约抢占** | Lease-based Claiming | 多 Worker 通过数据库 UPDATE 条件竞争获取任务执行权，`SKIP LOCKED` 防止互等 |
| **幂等入队** | Idempotent Enqueue | 任务入队使用 scope+key+fingerprint 防重，相同任务不重复创建 |
| **重试退避** | Retry Backoff | 失败任务按指数退避重试（10s→20s→40s→...→1800s），最多 10 次 |
| **死信队列** | Dead Letter Queue | 多次重试仍失败的任务进入死信队列，等待人工重放 |
| **Webhook** | — | 事件订阅机制，签名投递（HMAC-SHA256），失败重试，支持人工重放 |

---

## 文件与存储

| 术语 | 英文 | 定义 |
|------|------|------|
| **存储渠道** | Storage Provider | 文件存储后端（S3-compatible / Local），支持多渠道，默认渠道可切换 |
| **文件额度** | File Quota | 租户级文件数量和存储字节数上限，上传前检查+确认后占用+删除后释放 |
| **Multipart Upload** | — | 大文件分片上传，支持断点续传 |

---

## 服务与模块

| 术语 | 英文 | 定义 |
|------|------|------|
| **platform/admin** | — | 平台基础管理后台服务，承载技术中台所有后端能力。不承载产品业务逻辑 |
| **ai/service** | — | AI/Chat 通用能力服务，SSE 流式聊天 |
| **version/service** | — | 版本发布服务雏形，当前🔴冻结，恢复前必须复审 |
| **web-antd-admin** | — | 前端管理后台默认应用，基于 Vben Admin 5.0 + Ant Design Vue |
| **微服务拆分条件** | Service Split Criteria | 独立部署/独立扩缩容/独立公共 API/独立数据生命周期/独立团队 ownership——满足任一才进入拆分评审 |

---

## 状态标记

| 标记 | 含义 |
|:---:|------|
| `[ ]` | 待开发 |
| `[~]` | 进行中 / 重构中 / 待验证收口 |
| `[x]` | 已完成（自动化验证 + 人工功能验证 + 文档同步均通过） |
| `[.]` | 暂缓（明确推迟） |

## 优先级标记

| 标记 | 含义 | 触发条件 |
|:---:|------|------|
| **P0** | 必须现在做 | 缺失会导致平台不可用或安全风险 |
| **P1** | 当前迭代 | 下一批要完成的能力 |
| **P2** | 下一迭代 | P1 完成后启动 |
| **P3** | 远期规划 | 有明确业务需求时启动 |

---

> 📌 术语有歧义或需要新增？在 `docs/architecture/README.md` 和本文件同步更新。
