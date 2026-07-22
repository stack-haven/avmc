# Protovalidate Skills

AI Agent 技能包，为 [protovalidate](https://github.com/bufbuild/protovalidate) 提供完整的验证规则参考。

[English](README.md)

> **重要说明**：本技能包适用于 **protovalidate**（新一代验证库）。
>
> `protoc-gen-validate` (PGV) 已处于维护模式。新项目和现有项目应迁移到 protovalidate。
>
> - [迁移指南](https://github.com/bufbuild/protovalidate/blob/main/docs/MIGRATION.md)
> - [博客：为什么选择 protovalidate？](https://blog.buf.build/announcing-protovalidate)

## 用途

帮助 AI 助手（如 Claude Code）正确编写 Protobuf 验证规则：
- 字段级验证（字符串、数值、数组等）
- CEL 表达式自定义验证
- 跨字段验证
- 自定义错误消息（中文/英文）
- 框架集成（Kratos 等）

## 目录结构

```
├── SKILL.md                    # 主技能文件
├── references/                 # 规则参考
│   ├── string-rules.md         # 字符串规则：min_len, pattern, email, uuid...
│   ├── number-rules.md         # 数值规则：gt, gte, lt, lte, in...
│   ├── complex-rules.md        # 复杂类型：repeated, map, enum, bytes...
│   ├── message-rules.md        # 消息级验证：required, oneof, 跨字段...
│   ├── cel-expressions.md      # CEL 表达式语法和函数
│   └── custom-errors.md        # 自定义错误消息
├── examples/                   # 示例
│   ├── common-patterns.md      # 常用模式：登录、注册、分页...
│   └── chinese-validation.md   # 中文验证：手机号、身份证、车牌...
└── integrations/               # 框架集成
    ├── README.md               # 如何添加新框架
    └── kratos.md               # Go-Kratos 集成
```

## 安装

### 通过 skills CLI（推荐）

```bash
# 项目级（推荐）
npx skills add lwx-cloud/protovalidate-skills

# 个人级（所有项目共享）
npx skills add lwx-cloud/protovalidate-skills -g
```

### 或让 AI 助手安装

```
Install protovalidate-skills from https://github.com/lwx-cloud/protovalidate-skills
```

### 或手动安装

```bash
# 项目级
git clone https://github.com/lwx-cloud/protovalidate-skills.git .claude/skills/protovalidate-skills

# 个人级
git clone https://github.com/lwx-cloud/protovalidate-skills.git ~/.claude/skills/protovalidate-skills
```

## 使用方法

在对话中调用：
```
/protovalidate-skills
```

或直接提问：
- "如何用 protovalidate 验证手机号？"
- "protovalidate 如何实现跨字段验证？"

### 作为知识库

直接查阅 `references/` 和 `examples/` 目录下的 Markdown 文件。

## 快速示例

```protobuf
message User {
  // 字符串验证（自定义中文错误消息）
  string username = 1 [(buf.validate.field).cel = {
    id: "username_format",
    message: "用户名必须为3-32个字符，只能包含字母、数字和下划线",
    expression: "this.matches('^[a-zA-Z0-9_]{3,32}$')"
  }];

  // 数值验证
  int32 age = 2 [(buf.validate.field).int32 = { gte: 0, lte: 150 }];

  // 内置格式验证
  string email = 3 [(buf.validate.field).string.email = true];
}
```

## 相关资源

- [protovalidate 官方文档](https://protovalidate.com)
- [protovalidate-go](https://github.com/bufbuild/protovalidate-go)
- [buf.validate 规则定义](https://buf.build/bufbuild/protovalidate)

## License

MIT
