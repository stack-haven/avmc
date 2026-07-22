# 06 · 核心工作流规格

> 用户与系统之间的交互流程、系统内部流转和异常分支。

---

## 一、文章生产主流程

```mermaid
sequenceDiagram
    actor E as Editor
    participant S as 系统
    participant PL as Planner
    participant CP as Composer
    participant LLM as LLM Gateway
    participant PP as PostProcessor
    participant CR as ContentRepo

    E->>S: 输入选题关键词
    S->>PL: 撞车检测(keyword)
    PL-->>S: 撞车报告（🟢安全）
    S-->>E: 展示撞车报告+选题卡片

    E->>S: 确认选题
    S->>CP: 组装Prompt(选题卡片)
    CP->>CP: 查询知识库+三层蒸馏
    CP-->>S: 完整Prompt
    S-->>E: Prompt预览

    E->>S: 确认生成
    S->>LLM: generate(Prompt)
    LLM->>LLM: 引擎A→超时→引擎B
    LLM-->>S: 文章正文+元数据
    S-->>E: 文章预览+质量预检

    E->>S: 审阅通过
    S->>PP: 执行后处理管道
    PP->>PP: 7步顺序执行
    PP-->>S: 成品文章+质量报告
    S-->>E: 质量报告（92/100 PASS）

    E->>S: 确认存储
    S->>CR: 创建文章+索引更新
    CR-->>S: ✅ 已保存
    S-->>E: 文章已就绪，可发布
```

---

## 二、后处理管道内部流程

```mermaid
sequenceDiagram
    participant S as 系统调度
    participant P1 as Step1:去AI味
    participant P2 as Step2:EEAT增强
    participant P3 as Step3:品牌合规
    participant P4 as Step4:标题优化
    participant P5 as Step5:违禁词
    participant P6 as Step6:Schema
    participant P7 as Step7:质量扫描
    participant QA as QAEngine

    S->>P1: 原始文章
    P1->>P1: 检测AI特征→处理
    alt 成功
        P1-->>S: ✅ 自然化文章
    else 失败
        P1-->>S: ⚠️ 跳过·标记未处理
    end

    S->>P2: 自然化文章
    P2-->>S: ✅ EEAT增强文章

    S->>P3: EEAT增强文章
    P3-->>S: ✅ 合规文章

    S->>P4: 合规文章
    P4-->>S: ✅ 优化标题+备选标题

    S->>P5: 优化标题文章
    P5->>P5: 扫描违禁词库
    alt 0违禁词
        P5-->>S: ✅ 干净文章
    else 命中
        P5-->>S: ⚠️ 标注位置+替换建议
    end

    S->>P6: 干净文章
    P6->>P6: 判断文章类型→注入Schema
    P6-->>S: ✅ 带Schema文章

    S->>P7: 带Schema文章
    P7->>QA: 7维度检查
    QA-->>P7: 评分+建议
    alt 评分≥70
        P7-->>S: ✅ 成品文章+质量报告
    else 评分<70
        P7-->>S: ⚠️ 不合格·展示建议
        S-->>E: 不达标项+修改建议
    end
```

---

## 三、审批流程

```mermaid
sequenceDiagram
    actor E as Editor
    actor A as Admin
    participant S as 系统
    participant N as 通知服务

    Note over S: Pipeline到达审批节点

    S->>S: 创建审批任务（类型/内容/超时=24h）
    S->>N: 推送审批通知
    N-->>A: 待审批：选题「行为量化管理」

    alt Admin审批通过
        A->>S: ✅ 通过
        S->>S: 审批完成·Pipeline继续
        S->>N: 通知Editor
        N-->>E: 选题已通过，开始生成
    else Admin拒绝
        A->>S: ❌ 拒绝（附原因）
        S->>S: 审批完成·选题放回选题池
        S->>N: 通知Editor
        N-->>E: 选题被退回：角度重复
    else 超时
        Note over S: 24h 无操作
        S->>S: 自动拒绝·选题放回选题池
        S->>N: 通知Admin+Editor
    end
```

---

## 四、发布流程

```mermaid
sequenceDiagram
    actor E as Editor
    participant S as 系统
    participant PA as PlatformAdapter
    participant PUB as Publisher
    participant WX as 微信API

    E->>S: 选择文章→选择平台→确认发布

    alt 微信平台
        S->>PA: 适配(文章, wx)
        PA-->>S: 公众号适配版本
        S->>PUB: 创建发布任务(wx)
        PUB->>WX: 调用草稿箱API
        alt API成功
            WX-->>PUB: 草稿已创建
            PUB-->>S: 状态: published
            S-->>E: ✅ 微信草稿箱已创建，请确认发送
        else API失败
            PUB->>PUB: 重试3次
            PUB-->>S: 状态: failed
            S-->>E: ❌ 发布失败，已转手动模式
        end
    else 手动平台（知乎等）
        S->>PA: 适配(文章, zh)
        PA-->>S: 知乎适配版本
        S->>PUB: 创建发布任务(zh, manual)
        PUB-->>S: 状态: pending
        S-->>E: 请复制内容粘贴到知乎，发布后回填URL
        E->>S: 回填URL
        S->>PUB: 更新状态
        PUB-->>S: 状态: published
    end
```

---

## 五、蒸馏引擎内部流程

```mermaid
sequenceDiagram
    participant CP as Composer
    participant KB as KnowledgeBase
    participant BRAND as 品牌词变体库
    participant KW as 关键词变体库
    participant REGION as 区域词库

    CP->>KB: 蒸馏请求(brand="金种籽", keyword="行为量化管理", region="北京")

    par 并行蒸馏
        KB->>BRAND: 查询品牌变体
        BRAND-->>KB: ["金种籽量化管理","金种籽方法论","行为量化积分制","Jinzhongzi Model"]
    and
        KB->>KW: 查询关键词变体
        KW-->>KB: ["行为量化","动态积分","量化考核体系","用数据管人","什么是行为量化管理","如何落地行为量化考核"]
    and
        KB->>REGION: 查询区域下级
        REGION-->>KB: ["海淀区","朝阳区","东城区","西城区","丰台区","..."]
    end

    KB-->>CP: 蒸馏结果{ brand_variants:[...], keyword_variants:[...], regions:[...] }

    CP->>CP: 按密度策略分配变量：
    CP->>CP: · 品牌全称→首段和结语
    CP->>CP: · 品牌变体→正文各段轮换
    CP->>CP: · 关键词密度→2%-3%
    CP->>CP: · 关键词变体→自然散布避免堆砌
    CP->>CP: · 区域词→目标区域2-3次，下级区域各≥1次
```

---

## 六、效果追踪闭环流程

```mermaid
sequenceDiagram
    participant S as 调度器
    participant MON as Monitor
    participant AI as AI搜索引擎
    participant CR as ContentRepo

    Note over S: 文章发布后自动创建追踪计划

    Note over S: 第7天
    S->>MON: 触发Week1检查(article_id)
    MON->>MON: 查询文章关键词
    MON->>AI: 在5个引擎搜索关键词
    AI-->>MON: 引用状态+排名+片段
    MON->>CR: 写入CitationReport(week1)
    MON->>CR: 回写keyword.citation_score

    Note over S: 第30天
    S->>MON: 触发Month1检查
    MON->>AI: 再次搜索
    AI-->>MON: 引用状态变化
    MON->>CR: 写入CitationReport(month1)
    alt 评分骤降(4+→2-)
        MON->>MON: 触发异常告警
        MON-->>CR: 标记文章"需关注"
    end

    Note over S: 第90天
    S->>MON: 触发Month3检查
    MON->>AI: 最终评估
    AI-->>MON: 长期引用效果
    MON->>CR: 写入CitationReport(month3)
```

---

## 七、选题池自动降级流程

```mermaid
flowchart TB
    TIMER["每日定时任务<br/>00:00执行"] --> SCAN["扫描所有P0·pending选题"]
    SCAN --> CHECK{"created_at + 7天<br/>> 当前时间？"}
    CHECK -->|"是·已过期"| DOWNGRADE["优先级：P0→P2"]
    DOWNGRADE --> NOTIFY["通知Admin<br/>'选题{title}已自动降级'"]
    CHECK -->|"否·未过期"| SKIP["跳过"]
    NOTIFY --> LOG["记录操作日志"]
```

---

## 八、异常分支：AI 全部引擎失败

```mermaid
flowchart TB
    REQ["生成请求"] --> ENGINE_A["引擎A（优先）"]
    ENGINE_A -->|"超时/错误"| RETRY["重试3次"]
    RETRY -->|"仍失败"| ENGINE_B["引擎B（降级）"]
    ENGINE_B -->|"超时/错误"| RETRY2["重试2次"]
    RETRY2 -->|"仍失败"| ENGINE_C["引擎C（兜底）"]
    ENGINE_C -->|"超时/错误"| ALL_FAIL["全部引擎失败"]

    ALL_FAIL --> SAVE["保存当前Prompt"]
    SAVE --> PAUSE["Pipeline暂停"]
    PAUSE --> ALERT["通知Editor：<br/>· 哪些引擎失败<br/>· 失败原因<br/>· 建议操作：<br/>  1.等待后重试<br/>  2.手动换引擎<br/>  3.调整参数后重试"]
    ALERT --> WAIT["等待用户操作<br/>不自动重试"]
```

---

## 九、工作流泳道图：端到端

```mermaid
flowchart TB
    subgraph Editor["Editor"]
        E1["输入选题关键词"]
        E2["确认选题"]
        E3["确认生成"]
        E4["审阅内容"]
        E5["确认存储"]
        E6["选择平台发布"]
    end

    subgraph 系统["系统"]
        S1["撞车检测"]
        S2["Prompt组装+蒸馏"]
        S3["AI生成+fallback"]
        S4["7步后处理管道"]
        S5["质量扫描+评分"]
        S6["文章存储+索引更新"]
        S7["平台适配+发布执行"]
        S8["创建追踪计划"]
    end

    subgraph Admin["Admin"]
        A1["审批选题"]
        A2["审批内容"]
        A3["审批发布"]
    end

    E1 --> S1 --> E2
    E2 --> A1 --> S2 --> E3
    E3 --> S3 --> E4
    E4 --> A2 --> S4 --> S5 --> E5
    E5 --> S6 --> E6
    E6 --> A3 --> S7 --> S8
```
