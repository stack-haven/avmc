# 06 · 核心业务流程

> 系统最关键的业务流程设计，含时序图和泳道图。

---

## 一、客户开通多产品流程

### 1.1 泳道图

```mermaid
sequenceDiagram
    actor Sales as 业务员
    participant Console as 业务员控制台
    participant Channel as 渠道引擎
    participant Agent as 代理控制台
    participant Tenant as 租户底座
    participant Billing as 计费引擎
    participant Notify as 消息通知
    actor Customer as 客户

    Sales->>Console: 录入客户信息 + 勾选产品
    Note over Console: 客户：XX餐厅<br/>产品1：GEO Pro ¥9,000/月<br/>产品2：CRM Starter ¥3,000/月<br/>合计：¥12,000/月<br/>业务员预估提成：¥XXX

    Console->>Console: 核算预估费用+提成
    Sales->>Console: 确认提交

    Console->>Channel: 提交开通申请
    Channel->>Agent: 推送审核通知
    
    Agent->>Agent: 审核客户信息和套餐
    Agent->>Channel: ✅ 审核通过

    Channel->>Tenant: 创建租户「XX餐厅」
    Channel->>Tenant: 开通 GEO 产品线
    Channel->>Tenant: 开通 CRM 产品线
    Channel->>Tenant: 创建客户 Owner 账号

    Channel->>Billing: 创建 GEO 订阅
    Channel->>Billing: 创建 CRM 订阅

    Channel->>Channel: 建立业务员→客户的代管关系

    Channel->>Notify: 发激活短信给客户
    Channel->>Notify: 通知业务员"客户已开通"

    Notify-->>Customer: 📱 激活短信
    Notify-->>Sales: 📱 客户已开通，可开始服务
```

### 1.2 异常处理

| 异常 | 处理 |
|------|------|
| 代理审核拒绝 | 退回业务员，附原因。客户信息保留，业务员可修改后重新提交 |
| 租户创建失败 | 回滚已创建的资源，返回错误。业务员可重试 |
| 产品线开通部分失败 | 已开通的保留，失败的标记 pending，后台异步重试 |
| 计费创建失败 | 租户已创建但订阅未生效——后台异步补偿 |

---

## 二、代客管理操作流程

### 2.1 业务员代管客户生成文章

```mermaid
sequenceDiagram
    actor Sales as 业务员
    participant Console as 业务员控制台
    participant Auth as 认证中心
    participant Tenant as 租户底座
    participant Product as GEO 产品服务
    participant Billing as 计费引擎
    participant Audit as 审计日志

    Note over Sales: 已登录业务员控制台
    
    Sales->>Console: 选择客户「XX餐厅」→ 进入代管
    Console->>Auth: 请求代管会话（target_tenant=T_A）
    Auth->>Auth: 校验：张三 是否有 T_A 的代管权限
    Auth-->>Console: ✅ 代管Token（mode=managed, tenant=T_A）

    Note over Console: 🔄 代管模式：XX餐厅

    Sales->>Console: 录入品牌案例 3 条
    Console->>Product: POST /geo/cases<br/>Header: tenant=T_A, mode=managed
    Product->>Tenant: 解析租户上下文 → T_A
    Product->>Product: 数据写入 T_A 的租户空间
    Product->>Audit: 记录：张三代管 T_A 录入案例
    Product-->>Console: ✅ 案例创建成功

    Sales->>Console: 触发 AI 生成文章
    Console->>Product: POST /geo/articles/generate
    Product->>Billing: 检查配额（T_A，GEO，article）
    Billing-->>Product: ✅ 配额充足（剩余 28/30）
    Product->>Billing: 扣减配额（used+1）
    Product->>Product: 执行 AI 生成
    Product->>Audit: 记录：张三代管 T_A 生成文章
    Product-->>Console: ✅ 文章生成完成

    Sales->>Console: 退出代管
    Console->>Auth: 销毁代管Token
    Console-->>Sales: 回到业务员视角
```

### 2.2 客户自管查看文章

```mermaid
sequenceDiagram
    actor Customer as 客户Owner
    participant Console as 客户控制台
    participant Auth as 认证中心
    participant Product as GEO 产品服务

    Customer->>Console: 登录
    Console->>Auth: 认证
    Auth-->>Console: Token（user_type=customer, tenant=T_A）

    Customer->>Console: 查看文章列表
    Console->>Product: GET /geo/articles<br/>Header: tenant=T_A, mode=self
    Product->>Product: 查询 T_A 的文章数据
    Product-->>Console: 返回文章列表
    Note over Console: 客户看到：<br/>· 自己录入的数据<br/>· 业务员帮自己生成的文章<br/>· 每条数据标注操作人

    Customer->>Console: 查看代管记录
    Console->>Product: GET /geo/managed-log
    Product-->>Console: 返回操作记录
    Note over Console: 显示：<br/>· 业务员张三 7/18 录入案例3条<br/>· 业务员张三 7/19 生成文章1篇
```

---

## 三、佣金结算流程

### 3.1 月度结算泳道图

```mermaid
sequenceDiagram
    participant System as 结算引擎
    participant Billing as 计费引擎
    participant Channel as 渠道引擎
    participant Agent as 代理
    participant Sales as 业务员
    participant Platform as 平台财务

    Note over System: 每月1号 00:00 自动触发

    System->>Billing: 拉取上月已付账单
    Billing-->>System: 返回（按租户×产品线分列）

    System->>Channel: 拉取代理-客户归属关系
    Channel-->>System: 返回（每个客户归属哪个代理+业务员）

    System->>System: 按代理分组汇总<br/>· 区分首单/续费<br/>· 按产品线独立计算<br/>· 生成：代理佣金 + 业务员提成

    System->>Agent: 推送结算预览
    Agent->>Agent: 核对数据

    alt 无异议
        Agent->>System: 确认
        System->>Platform: 生成正式结算单
        Platform->>Agent: 每月10号 支付佣金
        Agent->>Sales: 支付业务员提成
    else 有争议
        Agent->>System: 提交争议工单
        System->>Platform: 标记争议，人工介入
        Platform->>Agent: 协商处理
    end
```

---

## 四、新产品线接入流程

```mermaid
flowchart TB
    DEV["产品开发团队"] --> REG1["① 注册产品线基本信息"]
    REG1 --> REG2["② 注册菜单树 + 权限点"]
    REG2 --> REG3["③ 注册定价方案 + 配额维度"]
    REG3 --> REG4["④ 开发产品业务功能"]
    
    REG4 --> INT1["⑤ 接入认证中心（Token校验）"]
    INT1 --> INT2["⑥ 接入计费引擎（用量上报）"]
    INT2 --> INT3["⑦ 接入消息通知（事件触发）"]
    INT3 --> INT4["⑧ 接入文件存储（资源上传）"]
    INT4 --> INT5["⑨ 接入审计日志（操作记录）"]
    INT5 --> INT6["⑩ API网关注册路由"]
    
    INT6 --> REVIEW["平台审核"]
    REVIEW -->|"✅ 通过"| ONLINE["产品上线"]
    REVIEW -->|"❌ 退回"| DEV

    ONLINE --> AGENT_SEE["代理控制台：<br/>可销售产品列表出现新产品"]
    ONLINE --> CUSTOMER_SEE["客户控制台：<br/>可选购新产品"]
```

---

## 五、业务员离职交接流程

```mermaid
flowchart TB
    TRIGGER["业务员离职/被停用"] --> LIST["代理查看该业务员名下客户列表"]
    LIST --> SELECT["勾选需要转移的客户"]
    SELECT --> TARGET["选择目标业务员"]

    TARGET --> EXEC["执行转移"]
    EXEC --> UPDATE["更新客户分配关系"]
    UPDATE --> HISTORY["记录历史关系（谁→谁，何时）"]
    UPDATE --> CLEAR["清除离职业代员对客户的代管权限"]
    CLEAR --> GRANT["授予新业务员代管权限"]

    GRANT --> NOTIFY_CUSTOMER["通知客户：服务专员变更"]
    GRANT --> NOTIFY_NEW["通知新业务员：有新客户接手"]
    GRANT --> NOTIFY_AGENT["代理控制台更新客户分布"]
```

---

## 六、客户续费流程

```mermaid
sequenceDiagram
    actor Customer as 客户
    actor Sales as 业务员
    participant Billing as 计费引擎
    participant Notify as 消息通知
    participant Comm as 结算引擎

    Note over Billing: 订阅到期前 15 天
    Billing->>Notify: 触发续费提醒
    Notify->>Sales: 📱 客户「XX餐厅」GEO Pro 15天后到期
    Notify->>Customer: 📱 您的 GEO Engine 即将到期

    Sales->>Customer: 主动联系，沟通续费

    Note over Billing: 订阅到期前 7 天
    Billing->>Notify: 再次提醒

    Note over Billing: 订阅到期前 3 天
    Billing->>Notify: 最后提醒

    alt 客户续费
        Customer->>Billing: 完成续费支付
        Billing->>Billing: 更新订阅（到期日延长）
        Billing->>Comm: 标记为续费（用于佣金计算）
        Billing->>Notify: ✅ 续费成功
        Notify->>Sales: 📱 客户续费成功，续费提成 ¥XXX
    else 客户未续费
        Billing->>Billing: 订阅状态 → expired
        Billing->>Notify: ⚠️ 订阅过期
        Notify->>Sales: 📱 客户已过期，请跟进
        Note over Customer: 客户无法使用该产品<br/>数据保留 30 天
    end
```
