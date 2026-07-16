# Protovalidate Skills

AI Agent skill package providing comprehensive validation rules reference for [protovalidate](https://github.com/bufbuild/protovalidate).

[中文文档](README_CN.md)

> **Important**: This skill is for **protovalidate**, the next-generation validation library.
>
> `protoc-gen-validate` (PGV) is in maintenance mode. New and existing projects should transition to protovalidate.
>
> - [Migration Guide](https://github.com/bufbuild/protovalidate/blob/main/docs/MIGRATION.md)
> - [Blog Post: Why protovalidate?](https://blog.buf.build/announcing-protovalidate)

## Purpose

Help AI assistants (like Claude Code) write correct Protobuf validation rules:
- Field-level validation (string, number, array, etc.)
- CEL expression custom validation
- Cross-field validation
- Custom error messages (Chinese/English)
- Framework integration (Kratos, etc.)

## Directory Structure

```
├── SKILL.md                    # Main skill file
├── references/                 # Rules reference
│   ├── string-rules.md         # String rules: min_len, pattern, email, uuid...
│   ├── number-rules.md         # Number rules: gt, gte, lt, lte, in...
│   ├── complex-rules.md        # Complex types: repeated, map, enum, bytes...
│   ├── message-rules.md        # Message-level: required, oneof, cross-field...
│   ├── cel-expressions.md      # CEL expression syntax and functions
│   └── custom-errors.md        # Custom error messages
├── examples/                   # Examples
│   ├── common-patterns.md      # Common patterns: login, registration, pagination...
│   └── chinese-validation.md   # Chinese validation: mobile, ID card, license plate...
└── integrations/               # Framework integrations
    ├── README.md               # How to add new frameworks
    └── kratos.md               # Go-Kratos integration
```

## Installation

### Via skills CLI (Recommended)

```bash
# Project-level (recommended)
npx skills add lwx-cloud/protovalidate-skills

# Personal-level (all projects)
npx skills add lwx-cloud/protovalidate-skills -g
```

### Or ask your AI agent

```
Install protovalidate-skills from https://github.com/lwx-cloud/protovalidate-skills
```

### Or manually

```bash
# Project-level
git clone https://github.com/lwx-cloud/protovalidate-skills.git .claude/skills/protovalidate-skills

# Personal-level
git clone https://github.com/lwx-cloud/protovalidate-skills.git ~/.claude/skills/protovalidate-skills
```

## Usage

Invoke in conversation:
```
/protovalidate-skills
```

Or ask directly:
- "How to validate mobile phone with protovalidate?"
- "How to implement cross-field validation?"

### As Knowledge Base

Browse Markdown files in `references/` and `examples/` directories directly.

## Quick Example

```protobuf
message User {
  // String validation with custom message
  string username = 1 [(buf.validate.field).cel = {
    id: "username_format",
    message: "Username must be 3-32 characters, letters, numbers and underscores only",
    expression: "this.matches('^[a-zA-Z0-9_]{3,32}$')"
  }];

  // Number validation
  int32 age = 2 [(buf.validate.field).int32 = { gte: 0, lte: 150 }];

  // Built-in format validation
  string email = 3 [(buf.validate.field).string.email = true];
}
```

## Resources

- [Protovalidate Documentation](https://protovalidate.com)
- [protovalidate-go](https://github.com/bufbuild/protovalidate-go)
- [buf.validate Rules Definition](https://buf.build/bufbuild/protovalidate)

## License

MIT
