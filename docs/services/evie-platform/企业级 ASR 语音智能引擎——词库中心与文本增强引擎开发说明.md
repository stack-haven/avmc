<!-- NOTE:2026-08-25
本文档为开发说明文档。在 2026-08-25 M0-M11 重构后，
详细开发计划与验收标准以 [8-词库中心与文本增强引擎开发计划](./development/8-词库中心与文本增强引擎开发计划.md) 为事实来源。
本文档作为产品需求背景与业务场景说明保留；技术实现细节（术语、proto 路径、Ent schema）请参考 8- 以及 development/ 下的技术文档。
-->

# 企业级 ASR 语音智能引擎——词库中心与文本增强引擎开发说明

## 一、项目背景

当前系统是一个面向企业服务场景的 **ASR 语音智能引擎**。

系统整体链路：

```text
用户语音
   ↓
ASR语音识别
   ↓
原始文本
   ↓
文本增强引擎
   ↓
标准化文本
   ↓
后续 AI Agent / LLM
```

当前 ASR 层已经完成多供应商模式开发，包括但不限于：

* FunASR
* 讯飞
* 阿里云
* 其他 ASR Provider

本次开发**不修改现有 ASR 供应商管理和 ASR 识别能力**。

本次重点开发：

```text
语音智能引擎
├── 词库中心
└── 文本增强引擎
```

其中：

> **词库中心负责语言知识资产管理。**

> **文本增强引擎负责使用这些语言知识，对 ASR 输出文本进行清洗、标准化、别名解析和错误矫正。**

---

# 二、最重要的设计原则

整个实现必须遵守以下原则。

### 原则1：词库不是业务主数据系统

词库中心不负责：

* 员工管理
* 组织管理
* 客户管理
* 产品管理
* 项目管理

这些业务数据可以作为词库的数据来源，但词库中心只负责管理：

> **语言表达及其标准化关系。**

例如企业组织系统同步：

```text
田华
技术研发部
```

词库中心只保存语言知识：

```text
田华 → PERSON
技术研发部 → ORGANIZATION
```

企业管理员进一步维护：

```text
小田 → ALIAS → 田华
```

---

### 原则2：不要建立“人员词库、组织词库、业务词库”等专用模块

正确模型：

```text
Dictionary
    ↓
DictionaryEntry
    ↓
category
```

例如：

```text
田华
category = PERSON
```

```text
技术研发部
category = ORGANIZATION
```

```text
金种籽
category = BUSINESS_TERM
```

人员、组织、业务名词只是词条分类，不是独立领域模块。

---

### 原则3：词库与文本增强策略解耦

严格区分：

```text
词库：
系统知道什么

Vocabulary Context：
本次请求允许使用什么知识

Policy：
本次请求怎么使用这些知识

Text Enhancement Engine：
实际执行处理
```

不要把 Policy 参数直接绑定到词条。

---

### 原则4：确定性处理和推断性处理必须分离

确定性：

```text
小田 → 田华
金种子 → 金种籽
```

这是明确知识，不需要算法置信度。

推断性：

```text
功课 → 攻克
```

这是算法判断，需要评分和策略决策。

---

### 原则5：默认不使用 LLM

第一期：

```text
LLM = OFF
```

预留扩展接口即可。

不要为了“AI化”而把 LLM 加入第一期核心链路。

---

# 三、核心领域模型

本次重点实现以下领域对象。

```text
Dictionary
DictionaryEntry
DictionaryRelation
DictionaryCategory
DictionaryVersion
VocabularyContext
EnhancementProfile
EnhancementPolicy
EnhancementResult
EnhancementChange
```

不要求所有对象都必须作为独立数据库表实现，但领域职责必须清晰。

---

# 四、词库 Dictionary

Dictionary 表示一组具有共同作用域和生命周期的语言知识集合。

## 4.1 词库作用域

第一期固定：

```text
PLATFORM
SYSTEM
TENANT
```

含义：

### PLATFORM

平台级通用词库。

所有系统可以使用。

例如：

```text
人工智能
数据库
API
大模型
```

---

### SYSTEM

具体业务系统词库。

例如金种籽系统：

```text
金种籽
黑种籽
元宝
产值
指令官
```

词库中心不需要理解这些业务含义。

---

### TENANT

企业租户专属词库。

例如：

```text
田华
小田
技术研发部
XX项目
XX客户
```

租户之间必须严格隔离。

---

# 五、词库 Source

作用域和来源必须分离。

例如：

```text
scope = TENANT
source = ORGANIZATION_SYNC
```

表示：

> 这是租户词库中的组织架构同步数据。

来源建议支持：

```text
PLATFORM
SYSTEM
MANUAL
IMPORT
SYNC
API
```

第一期重点：

```text
MANUAL
SYNC
IMPORT
SYSTEM
PLATFORM
```

---

# 六、词条 DictionaryEntry

一个 DictionaryEntry 表示：

> **一个标准语言概念。**

例如：

```text
标准词：
田华
```

而不是把：

```text
田华
小田
田工
```

当作三个完全独立的标准词。

---

## 6.1 基础属性

至少支持：

```text
id
dictionary_id
standard_text
category
description
status
source
source_id
priority
created_at
updated_at
```

可扩展：

```text
pinyin
pinyin_initial
normalized_text
```

---

# 七、词条 Category

第一期建议内置基础分类：

```text
PERSON
ORGANIZATION
PRODUCT
LOCATION
PERSON_TITLE
BUSINESS_TERM
TECH_TERM
OTHER
```

允许未来扩展自定义 Category。

Category 的职责只是：

> 描述词条性质。

不能让 Category 直接决定处理行为。

例如：

```text
田华
category = PERSON
```

不代表一定执行实体解析。

真正决定处理方式的是：

```text
DictionaryRelation
+
EnhancementPolicy
```

---

# 八、词条关系 DictionaryRelation

这是词库中心最核心的模型之一。

一个标准词条可以拥有多个语言关系。

例如：

```text
田华
│
├── 小田       ALIAS
├── 田工       ALIAS
├── 田经理     ALIAS
└── 田花       HOMOPHONE / MISS_RECOGNITION
```

第一期建议至少支持：

```text
ALIAS
CORRECTION
HOMOPHONE
PHONETIC_SIMILAR
ABBREVIATION
RELATED
```

其中：

### ALIAS

业务别名。

例如：

```text
小田 → 田华
```

必须支持人工维护。

---

### CORRECTION

确定性错误表达。

例如：

```text
金种子 → 金种籽
```

---

### HOMOPHONE

同音表达。

例如：

```text
田花 → 田华
```

但它不等于一定自动替换。

是否处理由文本增强策略决定。

---

### PHONETIC_SIMILAR

近音表达。

---

### ABBREVIATION

简称。

---

### RELATED

相关表达。

第一期不应该因为 RELATED 自动替换文本。

---

# 九、特别强调：企业别名必须人工确认

例如：

```text
企业组织架构
      ↓
同步
      ↓
田华
```

系统可以自动获得：

```text
田华
```

但不能自动推断：

```text
小田 = 田华
```

正确流程：

```text
组织架构同步
      ↓
标准实体“田华”
      ↓
管理员添加：
小田 → ALIAS → 田华
      ↓
正式生效
```

未来可以增加：

```text
系统发现候选别名
      ↓
管理员确认
      ↓
正式关系
```

但第一期不要自动认定。

---

# 十、词库生命周期

词条和词库不要轻易物理删除。

建议：

```text
DRAFT
ACTIVE
DISABLED
ARCHIVED
```

企业人员离职时：

```text
田华
ACTIVE
 ↓
DISABLED / ARCHIVED
```

而不是物理删除。

原因：

> 历史 ASR 记录和增强记录可能仍然引用该词条。

---

# 十一、词库版本

词库需要版本概念。

例如：

```text
Tenant A
v21
v22
v23
```

词库发布后生成新版本。

文本增强请求使用某一个明确版本。

这样保证：

> **同一次文本增强处理过程中使用的语言知识保持一致。**

---

# 十二、Vocabulary Context

这是整个设计中非常重要的运行时对象。

它不是一个长期维护的业务实体。

它是：

> **一次文本增强请求运行时构建的有效词库上下文。**

---

## 12.1 默认组成

```text
Platform Dictionary
        +
System Dictionary
        +
Tenant Dictionary
        ↓
Vocabulary Context
```

默认优先级：

```text
TENANT
  >
SYSTEM
  >
PLATFORM
```

---

# 十三、Vocabulary Context 的构建机制

不要每次请求都直接查询数据库。

错误方式：

```text
每次ASR文本
 ↓
MySQL查平台词库
 ↓
MySQL查系统词库
 ↓
MySQL查租户词库
 ↓
组合
 ↓
文本增强
```

正确方式：

```text
词库发布
 ↓
生成词库索引
 ↓
缓存
 ↓
请求到达
 ↓
获取对应词库版本
 ↓
构建 Vocabulary Context
 ↓
执行文本增强
```

---

# 十四、Context Cache

建议使用缓存机制。

Context Key 可以类似：

```text
platform:{version}
system:{system_id}:{version}
tenant:{tenant_id}:{version}
```

组合后的 Context 可以进一步缓存。

例如：

```text
platform-v12
system-jz-v8
tenant-10001-v23
```

形成：

```text
VocabularyContext
```

---

# 十五、词库更新后的处理

例如：

```text
tenant-v23
```

增加：

```text
小熊 → 熊龙军
```

发布：

```text
v24
```

那么：

```text
v23 Context
```

失效。

异步构建：

```text
v24 Context
```

新请求使用 v24。

正在处理的请求继续使用原版本。

保证：

> **单次请求的 Context 一致性。**

---

# 十六、词库冲突处理

如果出现：

```text
平台：
小田 → A

系统：
小田 → B

租户：
小田 → 田华
```

默认：

```text
田华
```

因为：

```text
TENANT > SYSTEM > PLATFORM
```

但是不能静默吞掉冲突。

需要产生：

```text
Dictionary Conflict
```

供后台查询。

冲突信息至少包括：

```text
input
candidate
source_scope
source_dictionary
priority
resolved_candidate
```

---

# 十七、Vocabulary Context 不仅服务文本增强

必须设计成通用语言上下文。

未来可以同时服务：

```text
Vocabulary Context
      │
      ├── ASR Hotword Builder
      │       ├── FunASR
      │       ├── Xunfei
      │       └── Aliyun
      │
      ├── Text Enhancement
      │
      └── Future NLP / Entity Recognition
```

这样词库中心和 ASR Provider 解耦。

---

# 十八、文本增强引擎

本模块正式名称：

# Text Enhancement Engine

中文：

# 文本增强引擎

不要再将其内部简单设计成“纠错程序”。

它负责：

```text
文本清洗
口水词处理
别名解析
标准词映射
确定性替换
拼音纠错
模糊匹配
上下文纠错
```

第一期：

```text
LLM = OFF
```

---

# 十九、文本增强处理流水线

固定基础顺序：

```text
ASR Raw Text
      ↓
① Text Cleaning
      ↓
② Filler / Disfluency Processing
      ↓
③ Vocabulary Matching
      ↓
④ Alias Resolution
      ↓
⑤ Deterministic Replacement
      ↓
⑥ Pinyin Correction
      ↓
⑦ Fuzzy Matching
      ↓
⑧ Contextual Correction
      ↓
Enhanced Text
```

注意：

> Vocabulary Matching 是底层能力，不应该被理解成一个独立的“纠错阶段”。

---

# 二十、第一层：文本清洗

处理：

```text
异常空格
重复标点
特殊字符
明显乱码
ASR重复片段
```

例如：

```text
我...我想   给技术部  小田
```

标准化：

```text
我想给技术部小田
```

---

# 二十一、第二层：口水词 / Disfluency

第一期支持：

```text
嗯
呃
额
啊
哦
哈
那个
就是
然后
这个
```

但绝对禁止简单：

```text
replace("嗯", "")
```

必须考虑：

```text
位置
上下文
词条身份
语义
```

建议内部分类：

```text
STRONG_FILLER
WEAK_FILLER
CONTEXTUAL_FILLER
```

例如：

```text
呃 / 额
```

通常可以直接删除。

而：

```text
那个
就是
然后
这个
```

需要上下文判断。

---

# 二十二、第三层：Vocabulary Matching

采用：

```text
Trie
HashMap
倒排索引
```

等适合高速匹配的数据结构。

核心目标：

> **低延迟发现文本中的已知语言表达。**

例如：

```text
我要给技术部小田申请200个种子
```

快速识别：

```text
技术部
小田
种子
```

---

# 二十三、第四层：Alias Resolution

例如：

```text
小田
 ↓
ALIAS
 ↓
田华
```

这是：

> Entity / Alias Resolution

不是 Error Correction。

如果企业词库存在明确人工关系：

```text
小田 → 田华
```

直接执行。

不需要：

```text
拼音算法
模糊算法
LLM
```

---

# 二十四、第五层：确定性替换

例如：

```text
金种子
 ↓
CORRECTION
 ↓
金种籽
```

同样：

> 不需要置信度。

确定性知识命中后直接处理。

---

# 二十五、确定性结果需要锁定

这是防止过度纠正的关键。

例如：

```text
小田
 ↓
田华
```

一旦通过明确的企业 Alias 关系解析：

```text
LOCKED
```

后续：

```text
拼音纠错
模糊匹配
上下文纠错
```

默认不能再次修改该结果。

同样：

```text
金种子 → 金种籽
```

确定性替换后锁定。

---

# 二十六、第六层：拼音纠错

用于处理：

```text
同音
近音
ASR语音识别偏差
```

例如：

```text
功课
 ↓
攻克
```

这里才开始产生：

```text
candidate
score
```

评分可以综合：

```text
Pinyin Similarity
Character Similarity
ASR Confidence
Dictionary Weight
Context Feature
```

---

# 二十七、第七层：模糊匹配

处理：

```text
错别字
近似词
ASR字词偏差
```

候选评分可以综合：

```text
编辑距离
字符相似度
拼音相似度
词条权重
ASR置信度
上下文
```

但第一期不要引入过度复杂的机器学习模型。

---

# 二十八、第八层：上下文纠错

例如：

```text
今天把技术难点功课下来
```

单看：

```text
功课
```

无法确定。

但结合：

```text
技术难点
+
下来
```

判断：

```text
攻克
```

上下文范围第一期建议：

> 当前句 + 有限前后文本窗口。

不要一开始做全文级语义推理。

---

# 二十九、ASR Confidence

如果现有 ASR Provider 已经提供：

```text
segment confidence
word confidence
timestamp
```

文本增强引擎应该接收并保留。

ASR Confidence 是文本增强算法的重要输入特征。

例如：

```text
田华
confidence = 0.99
```

与：

```text
田花
confidence = 0.42
```

应该采用不同的纠错策略。

---

# 三十、Policy

Policy 不负责：

> 判断一个词是什么。

Policy 负责：

> **决定文本增强引擎怎么处理。**

第一期支持：

```text
text_cleaning
filler_removal
alias_resolution
deterministic_replacement
pinyin_correction
fuzzy_matching
context_correction
llm = false
```

---

# 三十一、Policy 配置

第一期配置：

```text
文本清洗       ON/OFF
口水词处理     ON/OFF
别名解析       ON/OFF
确定性替换     ON/OFF
拼音纠错       ON/OFF
模糊匹配       ON/OFF
上下文纠错     ON/OFF
LLM            OFF
```

---

# 三十二、Policy 不直接开放算法阈值

第一期：

```text
Levenshtein threshold
Pinyin threshold
Context threshold
```

由系统内置。

不要让普通业务管理员配置。

原因：

> 算法阈值属于算法工程参数，不应该成为业务配置。

未来可以增加：

```text
高级策略
```

再开放。

---

# 三十三、建议增加 Enhancement Mode

提供：

### HIGH_PERFORMANCE

```text
清洗
+
口水词
+
别名
+
确定性替换
```

### STANDARD

```text
以上
+
拼音
+
模糊
```

### HIGH_ACCURACY

```text
以上
+
上下文
```

这样业务不需要理解复杂算法。

---

# 三十四、确定性与推断性必须严格区分

## 确定性

```text
ALIAS
CORRECTION
EXACT_STANDARDIZATION
```

命中：

> 直接执行。

---

## 推断性

```text
PINYIN
FUZZY
CONTEXT
```

需要：

```text
score
threshold
decision
```

---

# 三十五、推断结果的动作

建议：

```text
KEEP
REPLACE
SUGGEST
```

例如：

```text
score >= auto_threshold
```

执行：

```text
REPLACE
```

中间区间：

```text
SUGGEST
```

低置信度：

```text
KEEP
```

具体阈值第一期由系统内置。

---

# 三十六、删除是独立动作

例如：

```text
呃
```

不是：

```text
呃 → ""
```

而是：

```text
DELETE
```

动作类型至少支持：

```text
KEEP
REPLACE
DELETE
SUGGEST
RESOLVE
```

---

# 三十七、文本增强结果

不要只返回最终文本。

内部结果至少包含：

```text
request_id
raw_text
enhanced_text
policy_id
context_version
changes[]
```

每一个 Change：

```text
original_text
result_text
action
type
source
source_id
confidence
reason
locked
```

例如：

```text
{
  original: "小田",
  result: "田华",
  action: "RESOLVE",
  type: "ALIAS",
  source: "TENANT_DICTIONARY",
  confidence: null,
  locked: true
}
```

另一个：

```text
{
  original: "功课",
  result: "攻克",
  action: "REPLACE",
  type: "PINYIN_CONTEXT",
  confidence: 0.91,
  locked: false
}
```

---

# 三十八、最终输出

业务 Agent 默认只需要：

```text
{
  "text": "我想给技术部田华申请200颗种籽，今天攻克了一个技术难点。"
}
```

调试模式可以返回：

```text
{
  "text": "...",
  "changes": [...],
  "context_version": "...",
  "policy": "..."
}
```

---

# 三十九、示例完整流程

输入：

> 呃，我要给技术部小田申请200个种子，今天功课了一个技术难点。

ASR 输出：

```text
呃，我要给技术部小田申请200个种子，今天功课了一个技术难点。
```

经过清洗：

```text
我要给技术部小田申请200个种子，今天功课了一个技术难点。
```

Vocabulary Context：

```text
Platform
+
System
+
Tenant
```

发现：

```text
小田
种子
功课
```

确定性：

```text
小田 → 田华
种子 → 种籽
```

短语标准化：

```text
200个种籽
→
200颗种籽
```

上下文纠错：

```text
功课
→
攻克
```

最终：

```text
我要给技术部田华申请200颗种籽，今天攻克了一个技术难点。
```

---

# 四十、短语级标准化

这是第一期必须支持的能力。

不能只做：

```text
Word → Word
```

还需要：

```text
Phrase → Phrase
```

例如：

```text
200个种籽
→
200颗种籽
```

因此词库 Entry 至少需要区分：

```text
WORD
PHRASE
```

或者采用统一 Entry 模型，通过长度和类型识别。

---

# 四十一、分词设计

不能完全依赖普通中文分词。

建议采用：

```text
词库 Trie / Phrase Index
+
基础中文分词
```

优先匹配企业/系统/平台词库中的完整词条和短语。

例如：

```text
金种籽
```

必须优先整体匹配。

而：

```text
200个种籽
```

需要允许：

```text
200
+
个
+
种籽
```

组合判断。

---

# 四十二、过度纠正防护

必须实现：

> **单次文本增强中，一个片段不能无限循环处理。**

建议：

```text
每个 token / span
最多一次确定性转换
最多一次推断性转换
```

并设置：

```text
processed
locked
```

状态。

确定性结果：

```text
locked = true
```

推断性结果：

```text
locked = false
```

但进入下一层后如果已被更高优先级规则处理，应避免重复修改。

---

# 四十三、处理优先级

建议：

```text
文本清洗
   ↓
口水词
   ↓
精确词库
   ↓
Alias
   ↓
确定性替换
   ↓
短语规则
   ↓
拼音
   ↓
模糊
   ↓
上下文
```

总体原则：

> **确定性知识优先于算法推断。**

---

# 四十四、不要自动覆盖确定性结果

例如：

```text
小田
→
田华
```

即使模糊算法认为：

```text
小田 → 小田项目
score = 0.98
```

也不能覆盖企业已经确认的：

```text
小田 → 田华
```

---

# 四十五、流式 ASR 的设计边界

现有 ASR 支持：

```text
Streaming
Full Segment
```

文本增强引擎必须同时考虑两种模式。

## 整段模式

```text
完整文本
 ↓
一次增强
```

简单。

## 流式模式

```text
segment 1
segment 2
segment 3
...
```

第一期要求：

> 支持增量处理，但不要在每个临时 ASR 片段上进行高成本上下文推断。

建议：

```text
中间结果：
轻量清洗 + 确定性处理

Final Segment：
完整文本增强
```

这样性能和准确率更平衡。

---

# 四十六、多人对话

明确：

> **第一期不支持多人对话。**

不要设计：

```text
speaker_1
speaker_2
speaker_3
```

相关业务逻辑。

但数据结构可以预留：

```text
speaker_id
```

不实现具体功能。

---

# 四十七、性能要求

核心目标：

### 快速路径

以下能力尽量做到低延迟：

```text
文本清洗
口水词
精确匹配
别名解析
确定性替换
```

重点采用：

```text
Trie
HashMap
倒排索引
缓存
```

---

### 慢路径

允许相对更高成本：

```text
模糊匹配
上下文纠错
```

但必须具备：

```text
超时
降级
```

能力。

---

# 四十八、失败降级

任何一个增强阶段失败：

> **不能导致整个 ASR 请求失败。**

例如：

```text
上下文纠错超时
```

应该：

```text
保留当前文本
继续输出
```

而不是：

```text
整个请求失败
```

---

# 四十九、可观测性

必须记录：

```text
request_id
tenant_id
system_id
policy_id
context_version
raw_text
enhanced_text
processing_time
```

以及每个阶段耗时：

```text
cleaning_time
filler_time
dictionary_match_time
alias_time
deterministic_time
pinyin_time
fuzzy_time
context_time
```

这样后续可以分析：

> 到底哪个环节最慢。

---

# 五十、质量反馈机制

第一期不实现机器学习，但必须保留未来数据基础。

例如：

```text
系统：
功课 → 攻克

用户：
认为错误
```

可以记录：

```text
Enhancement Feedback
```

未来用于：

```text
规则优化
词库优化
模型优化
```

---

# 五十一、后台功能建议

最终后台结构建议：

```text
语音智能引擎
│
├── 词库中心
│   │
│   ├── 词库管理
│   ├── 词条管理
│   ├── 关系管理
│   ├── 分类管理
│   ├── 版本管理
│   ├── 冲突记录
│   └── 变更记录
│
├── 文本增强
│   │
│   ├── 增强场景
│   ├── 增强策略
│   └── 增强记录
│
└── 现有ASR
    │
    ├── 语音识别
    ├── 识别记录
    └── 供应商管理
```

现有 ASR 部分不要修改。

---

# 五十二、词库后台不要做成复杂的“业务主数据管理”

管理员看到的核心就是：

```text
词库
词条
关系
版本
冲突
```

而不是：

```text
员工管理
组织管理
客户管理
产品管理
```

这些应该通过同步接口把数据送入词库。

---

# 五十三、企业自动同步接口

后续企业业务系统可以调用：

```text
同步标准实体
```

例如：

```text
田华
技术研发部
项目A
```

词库中心负责：

```text
新增
更新
停用
版本
```

但是：

```text
小田 → 田华
```

仍然由企业人工维护。

---

# 五十四、系统与业务系统的边界

非常重要：

```text
业务系统
    ↓
提供业务实体
    ↓
词库中心
    ↓
转换成语言知识
```

而不是：

```text
词库中心
    ↓
管理业务实体
```

例如：

```text
HR系统：
员工ID=123
姓名=田华
部门=技术部
```

词库中心只关心：

```text
田华
PERSON
```

业务实体 ID 可以作为：

```text
external_id
```

保存，用于关联，但不承担员工管理职责。

---

# 五十五、最终系统职责边界

必须严格遵守：

```text
┌────────────────────────────┐
│ ASR                        │
│ 语音 → 原始文本             │
└──────────────┬─────────────┘
               ↓
┌────────────────────────────┐
│ Vocabulary Center           │
│ 语言知识资产                 │
└──────────────┬─────────────┘
               ↓
┌────────────────────────────┐
│ Vocabulary Context          │
│ 当前请求可用语言知识         │
└──────────────┬─────────────┘
               ↓
┌────────────────────────────┐
│ Text Enhancement Policy     │
│ 决定怎么处理                 │
└──────────────┬─────────────┘
               ↓
┌────────────────────────────┐
│ Text Enhancement Engine     │
│ 实际处理                    │
└──────────────┬─────────────┘
               ↓
          标准化文本
               ↓
        后续 AI Agent
```

---

# 五十六、第一期明确不做

Coding Agent 不得自行扩大范围。

以下全部暂不实现：

```text
❌ LLM纠错
❌ 多人对话
❌ Speaker Diarization
❌ TTS
❌ 业务Agent
❌ 复杂自学习
❌ 自动认定企业人员别名
❌ 员工管理
❌ 组织管理
❌ 客户管理
❌ 产品管理
❌ 独立热词词库
```

特别注意：

> **热词不是独立词库。**

未来热词应该从：

```text
Vocabulary Context
```

根据 ASR Provider 的能力生成对应的 Hotword Configuration。

---

# 五十七、第一期核心闭环

最终必须实现下面这个闭环：

```text
                    ASR
                     │
                     ▼
              Raw Transcript
                     │
                     ▼
              Vocabulary Context
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
 Platform/System/Tenant       Enhancement Policy
        │                         │
        └────────────┬────────────┘
                     ▼
           Text Enhancement Engine
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
    Clean          Resolve        Correct
      │              │              │
      └──────────────┼──────────────┘
                     ▼
              Enhanced Text
                     │
                     ▼
               Future Agent
```

---

# 五十八、核心示例必须通过

开发完成后，至少需要验证以下案例。

### Case 1：企业别名

输入：

```text
给小田申请奖励
```

词库：

```text
小田 → ALIAS → 田华
```

输出：

```text
给田华申请奖励
```

---

### Case 2：确定性纠错

输入：

```text
金种子
```

词库：

```text
金种子 → CORRECTION → 金种籽
```

输出：

```text
金种籽
```

---

### Case 3：口水词

输入：

```text
呃我想给那个技术部小田申请奖励
```

输出：

```text
我想给技术部田华申请奖励
```

---

### Case 4：拼音纠错

输入：

```text
今天功课了一个技术难点
```

上下文：

```text
技术难点
```

输出：

```text
今天攻克了一个技术难点
```

---

### Case 5：短语标准化

输入：

```text
申请200个种籽
```

规则：

```text
数量 + 种籽
```

输出：

```text
申请200颗种籽
```

---

### Case 6：低置信度

如果系统无法确定：

```text
A → B
```

不要强制修改。

输出：

```text
原文
```

并记录：

```text
SUGGEST
```

---

### Case 7：确定性结果不能被后续算法覆盖

```text
小田
 ↓
田华
 ↓
LOCKED
```

后续算法不得再次修改。

---

### Case 8：租户隔离

企业 A：

```text
小田 → 田华
```

企业 B：

```text
小田 → 王强
```

两个租户同一句：

```text
给小田申请奖励
```

必须得到：

```text
A → 给田华申请奖励
B → 给王强申请奖励
```

绝不能串库。

---

# 五十九、Coding Agent 的实施要求

Coding Agent 在开发时不要从 UI 开始。

推荐实施顺序：

```text
Phase 1
领域模型
 ↓
Phase 2
词库 CRUD
 ↓
Phase 3
词条关系
 ↓
Phase 4
词库版本
 ↓
Phase 5
词库索引
 ↓
Phase 6
Vocabulary Context
 ↓
Phase 7
Text Enhancement Core
 ↓
Phase 8
Deterministic Pipeline
 ↓
Phase 9
Pinyin/Fuzzy
 ↓
Phase 10
Context Correction
 ↓
Phase 11
Policy
 ↓
Phase 12
缓存/性能
 ↓
Phase 13
审计/可观测
 ↓
Phase 14
后台管理界面
 ↓
Phase 15
完整测试
```

不要先做漂亮 UI 再补核心引擎。

---

# 六十、最终架构目标

本次开发完成后，应形成一个可以被任何企业业务系统调用的通用基础能力：

```text
                企业业务系统
                     │
                     │ 同步语言知识
                     ▼
              ┌─────────────┐
              │ 词库中心     │
              └──────┬──────┘
                     │
                     ▼
              Vocabulary Context
                     │
                     │
ASR ──────→ Raw Text
                     │
                     ▼
             Text Enhancement
                     │
                     ▼
              Enhanced Text
                     │
                     ▼
             AI Agent / LLM
```

最终达到的目标不是：

> “做一个 ASR 纠错功能”。

而是：

> **建立一个独立于具体业务、具体企业和具体 ASR 厂商的企业级语音语言知识与文本增强基础设施。**

其中：

**ASR负责听见。**

**词库中心负责知道。**

**Vocabulary Context负责提供当前场景需要知道的内容。**

**Policy负责决定怎么处理。**

**文本增强引擎负责执行。**

**未来AI Agent负责理解和行动。**

这个边界一旦按照上述方式实施，后面无论你接入金种籽、OA、CRM、ERP，还是完全不同的企业服务系统，都不需要重新设计词库和文本增强核心，只需要向词库中心提供对应的企业语言知识即可。
