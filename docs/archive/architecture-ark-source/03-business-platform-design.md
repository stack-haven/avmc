# 03 · 业务中台详细设计

> 渠道管理、客户运营、佣金结算、产品线注册。
> 所有产品线共用的"管生意"能力。

---

## 一、模块总览

```mermaid
graph TB
    subgraph 业务中台["业务中台"]
        CHANNEL["渠道管理引擎<br/>代理生命周期·业务员管理·产品授权"]
        CUSTOMER["客户运营引擎<br/>开通审核·代客管理·客户健康度"]
        COMMISSION["佣金结算引擎<br/>多产品分佣·二级分润·结算对账"]
        PRODUCT_REG["产品线注册中心<br/>产品接入·菜单注册·定价注册"]
    end

    CHANNEL --> CUSTOMER
    COMMISSION --> CHANNEL
    PRODUCT_REG --> CHANNEL
    PRODUCT_REG --> COMMISSION
```

---

## 二、渠道管理引擎

### 2.1 代理生命周期

```mermaid
stateDiagram-v2
    [*] --> 申请中: 代理提交入驻
    申请中 --> 审核中: 平台收到申请
    审核中 --> 已开通: 审核通过
    审核中 --> 已拒绝: 审核不通过
    已拒绝 --> 申请中: 重新提交

    已开通 --> 运营中: 缴纳保证金
    运营中 --> 业绩预警: 季度不达标
    业绩预警 --> 运营中: 改善达标
    业绩预警 --> 降级处理: 连续不达标
    降级处理 --> 运营中: 降级为非独家

    运营中 --> 主动退出: 代理申请退出
    运营中 --> 违规清退: 平台强制清退
    主动退出 --> 已关闭: 结算完成
    违规清退 --> 已关闭: 扣押保证金
```

### 2.2 产品授权矩阵

```mermaid
graph TB
    subgraph 平台["平台管理"]
        PRODUCTS["产品池<br/>GEO / SEO / CRM / ERP"]
    end

    subgraph 授权["代理授权"]
        direction TB
        A1["代理A（省总代）<br/>授权：全产品线"]
        A2["代理B（GEO专代）<br/>授权：GEO"]
        A3["代理C（综合代理）<br/>授权：GEO + CRM"]
    end

    subgraph 继承["业务员继承"]
        B1_S["业务员A1<br/>可卖：全产品线"]
        B2_S["业务员B1<br/>可卖：GEO"]
        B3_S["业务员C1<br/>可卖：GEO + CRM"]
    end

    PRODUCTS -->|"配置授权"| A1
    PRODUCTS -->|"配置授权"| A2
    PRODUCTS -->|"配置授权"| A3
    
    A1 -.->|"自动继承"| B1_S
    A2 -.->|"自动继承"| B2_S
    A3 -.->|"自动继承"| B3_S
```

### 2.3 业务员离职交接

```mermaid
sequenceDiagram
    actor Agent as 代理
    participant Channel as 渠道引擎
    participant Customer as 客户运营
    participant Notify as 消息通知
    participant SalesNew as 新业务员

    Agent->>Channel: 停用业务员张三
    Channel->>Channel: 查询张三名下客户列表
    Channel-->>Agent: 返回客户列表（5个客户）
    
    Agent->>Channel: 批量分配给李四
    Channel->>Customer: 更新客户分配关系
    Channel->>Channel: 记录历史关系（张三→转出）
    
    Customer->>Notify: 通知5个客户
    Notify->>Notify: "您的服务专员已变更为李四（139xxxx）"
    
    Channel->>SalesNew: 李四控制台显示新客户
    SalesNew->>Customer: 查看客户历史代管记录
```

---

## 三、客户运营引擎

### 3.1 客户开通审核流程

```mermaid
flowchart TB
    SALES["业务员提交开通申请"] --> FORM["填写：<br/>· 客户企业信息<br/>· 勾选产品线+档次<br/>· 选择月付/年付"]
    FORM --> CALC["系统自动核算：<br/>· 预估月费<br/>· 业务员预估提成<br/>· 代理预估佣金"]
    CALC --> SUBMIT["提交申请"]

    SUBMIT --> AGENT_REVIEW{"代理审核"}
    AGENT_REVIEW -->|"✅ 通过"| AUTO_OPEN["系统自动开通：<br/>· 创建租户<br/>· 开通产品线<br/>· 创建客户Owner账号<br/>· 建立代管关系"]
    AGENT_REVIEW -->|"❌ 拒绝"| BACK["退回业务员<br/>（附原因）"]

    AUTO_OPEN --> NOTIFY_C["通知客户<br/>（激活短信）"]
    AUTO_OPEN --> NOTIFY_S["通知业务员<br/>（可开始代管服务）"]
    AUTO_OPEN --> AUDIT["记录审计日志"]
```

### 3.2 代客管理会话

```mermaid
sequenceDiagram
    actor Sales as 业务员
    participant Console as 业务员控制台
    participant Auth as 认证中心
    participant Tenant as 租户底座
    participant Product as 产品服务
    participant Audit as 审计日志

    Sales->>Console: 选择客户"XX餐厅" → 进入代管
    Console->>Auth: 请求代管会话（target_tenant=T_A）
    Auth->>Auth: 校验授权关系
    Auth-->>Console: 返回代管Token（mode=managed, tenant=T_A）
    
    Note over Console: 界面顶部显示：<br/>"代管模式：XX餐厅 [退出]"

    Sales->>Console: 录入品牌案例
    Console->>Product: POST /cases（Header: X-Tenant-Id=T_A, X-Mode=managed）
    Product->>Tenant: 解析租户上下文
    Product->>Product: 数据写入T_A的租户空间
    Product->>Audit: 记录：张三（业务员）代管T_A录入案例
    Product-->>Console: 操作成功
    Console-->>Sales: 客户A的案例列表刷新

    Sales->>Console: 退出代管
    Console->>Auth: 销毁代管Token
    Console-->>Sales: 回到业务员自身视角
```

### 3.3 客户健康度分层

```mermaid
flowchart LR
    subgraph 健康客户["🟢 健康客户"]
        H1["月活跃"]
        H2["用量 50-90%"]
        H3["注册 > 3个月"]
    end

    subgraph 需关注["🟡 需关注"]
        W1["用量 < 30%（可能不会用）"]
        W2["连续超额（套餐不够）"]
        W3["注册 1-3 个月"]
    end

    subgraph 流失风险["🔴 流失风险"]
        R1["30 天无操作"]
        R2["续费前曾犹豫"]
        R3["有投诉记录"]
    end

    subgraph 已流失["⚫ 已流失"]
        L1["到期未续"]
        L2["主动取消"]
    end

    健康客户 -->|"用量下降"| 需关注
    需关注 -->|"恢复活跃"| 健康客户
    需关注 -->|"持续恶化"| 流失风险
    流失风险 -->|"干预有效"| 需关注
    流失风险 -->|"干预无效"| 已流失
```

---

## 四、佣金结算引擎

### 4.1 多产品线分佣模型

```mermaid
flowchart TB
    PAYMENT["客户 XX公司 本月付费 ¥14,000"] --> SPLIT["按产品线拆分"]
    
    SPLIT --> GEO_FEE["GEO Pro：¥9,000"]
    SPLIT --> CRM_FEE["CRM Starter：¥5,000"]

    GEO_FEE --> GEO_CALC["GEO 佣金计算<br/>首单/续费判断 → 佣金比例"]
    CRM_FEE --> CRM_CALC["CRM 佣金计算<br/>首单/续费判断 → 佣金比例"]

    GEO_CALC --> GEO_RESULT["代理 GEO 佣金<br/>业务员 GEO 提成"]
    CRM_CALC --> CRM_RESULT["代理 CRM 佣金<br/>业务员 CRM 提成"]

    GEO_RESULT --> MERGE["合并结算单"]
    CRM_RESULT --> MERGE
```

### 4.2 月度结算流程

```mermaid
sequenceDiagram
    participant System as 结算引擎
    participant Bill as 计费数据
    participant Agent as 代理
    participant Platform as 平台财务
    
    Note over System: 每月1号 00:00 自动触发
    
    System->>Bill: 拉取上月所有已付账单
    Bill-->>System: 返回（按租户+产品线分列）
    
    System->>System: 按代理分组<br/>按产品线独立计算佣金<br/>区分首单/续费
    
    System->>System: 生成结算预览单<br/>· 代理总佣金<br/>· 业务员分佣明细<br/>· 各产品线佣金明细

    System->>Agent: 推送结算预览（每月1号）
    
    Agent->>System: 核对（有异议提交工单）
    
    alt 无异议
        System->>Platform: 每月5号 生成正式结算单
        Platform->>Agent: 每月10号 打款
    else 有异议
        System->>Platform: 标记争议，人工处理
        Platform->>Agent: 协商解决
        System->>System: 按协商结果调整结算单
    end
```

### 4.3 佣金比例配置（按产品线差异化）

| 产品线 | 代理类型 | 首单佣金比例 | 续费佣金比例 | 业务员建议提成 |
|--------|:------:|:----------:|:----------:|:------------:|
| GEO | 独家 | 50% | 20% | 佣金的 50-70% |
| GEO | 非独家 | 40% | 15% | 佣金的 50-70% |
| SEO | 通用 | 40% | 15% | 佣金的 50% |
| CRM | 通用 | 60% | 25% | 佣金的 60% |
| ERP | 通用 | 30% | 10% | 佣金的 50% |

> CRM 佣金比例最高——作为新推产品用高佣金激励渠道推广。这是业务运营的杠杆。

---

## 五、产品线注册中心

### 5.1 新产品上线接入流程

```mermaid
flowchart TB
    DEV["产品开发团队"] --> STEP1["① 注册产品线基本信息<br/>· 产品编码<br/>· 产品名称<br/>· 产品描述<br/>· 产品图标"]
    
    STEP1 --> STEP2["② 注册菜单树<br/>· 产品包含的功能菜单<br/>· 菜单层级结构<br/>· 每个菜单对应的权限点"]
    
    STEP2 --> STEP3["③ 注册定价方案<br/>· 定价档位表<br/>· 月付/年付价格"]
    
    STEP3 --> STEP4["④ 注册配额维度<br/>· 配额维度定义<br/>· 各档次的配额值<br/>· 超额规则（软/硬限制）"]
    
    STEP4 --> STEP5["⑤ 注册开通表单<br/>· 客户开通时需要填的字段<br/>· 字段校验规则"]
    
    STEP5 --> STEP6["⑥ 平台审核"]
    STEP6 -->|"✅ 通过"| ONLINE["产品上线<br/>· 代理可授权<br/>· 客户可选购<br/>· 菜单动态展示<br/>· 计费自动接入"]
    STEP6 -->|"❌ 退回"| DEV
```

### 5.2 产品线注册数据契约

```mermaid
erDiagram
    PRODUCT_LINE {
        string product_code PK "产品编码（如 GEO/CRM）"
        string product_name "产品名称"
        string description "产品描述"
        string icon "产品图标 URL"
        string status "启用|停用|开发中"
    }

    PRODUCT_MENU {
        string menu_id PK "菜单唯一标识"
        string product_code FK "所属产品"
        string parent_id "父菜单ID（树形结构）"
        string menu_name "菜单名称"
        string route_path "路由路径"
        string permission_key "权限标识"
        int sort_order "排序"
    }

    PRODUCT_PLAN {
        string plan_id PK "方案标识"
        string product_code FK "所属产品"
        string plan_name "方案名称"
        decimal monthly_price "月付价格"
        decimal yearly_price "年付价格"
    }

    PRODUCT_QUOTA {
        string quota_id PK "配额标识"
        string product_code FK "所属产品"
        string plan_id FK "所属方案"
        string dimension "配额维度名"
        int limit_value "配额值"
        string overage_policy "超额策略（soft/hard）"
        decimal overage_unit_price "超额单价"
    }
```

---

## 六、业务中台与技术中台的协作

```mermaid
flowchart LR
    subgraph 典型场景["典型运营场景：客户开通"]
        S1["业务员提交申请<br/>（业务中台·客户运营）"]
        S2["代理审核<br/>（业务中台·渠道管理）"]
        S3["创建租户+产品线<br/>（技术中台·租户底座）"]
        S4["设置配额<br/>（技术中台·计费引擎）"]
        S5["发激活短信<br/>（技术中台·消息通知）"]
        S6["建立代管关系<br/>（业务中台·客户运营）"]
        S7["记录审计<br/>（技术中台·审计日志）"]
    end

    S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7
```
