---
name: protovalidate-skills
description: Comprehensive knowledge base for buf.validate/protovalidate - Protocol Buffer validation library. Use for adding validation rules to proto fields, writing CEL expressions, custom error messages, and framework integration.
license: MIT
---

# Protovalidate Skills for AI Agents

This skill provides comprehensive knowledge about [protovalidate](https://github.com/bufbuild/protovalidate), the next-generation Protocol Buffer validation library from Buf. It replaces the deprecated [protoc-gen-validate](https://github.com/bufbuild/protoc-gen-validate).

## Target When

Invoke this skill when:
- **Defining proto validation rules**: Adding constraints to `.proto` files
- **Custom validation**: Writing CEL expressions for complex validation logic
- **Error handling**: Implementing custom error messages
- **Framework integration**: Using protovalidate with Kratos, go-zero, or other frameworks
- **Migration**: Upgrading from protoc-gen-validate to protovalidate
- **Debugging**: Troubleshooting validation errors

## Quick Reference

### Basic Syntax

```protobuf
syntax = "proto3";

package my.package;

import "buf/validate/validate.proto";

message User {
  // String validation
  string username = 1 [(buf.validate.field).string = {
    min_len: 3,
    max_len: 32,
    pattern: "^[a-zA-Z0-9_]+$"
  }];

  // Integer validation
  int64 age = 2 [(buf.validate.field).int64 = {gte: 0, lte: 150}];

  // Email validation
  string email = 3 [(buf.validate.field).string.email = true];

  // Custom CEL validation with Chinese error message
  string mobile = 4 [(buf.validate.field).cel = {
    id: "mobile_format",
    message: "手机号格式错误",
    expression: "this.matches('^1[3-9][0-9]{9}$')"
  }];
}
```

### Import Path

```protobuf
// Buf CLI managed mode
import "buf/validate/validate.proto";

// Option extension
option (buf.validate.field) = { ... };
option (buf.validate.message) = { ... };
option (buf.validate.oneof) = { ... };
```

## Knowledge Structure

Load specific guides as needed:

### Field Type Rules

| File | When to Load |
|------|-------------|
| [references/string-rules.md](references/string-rules.md) | String validation (length, pattern, email, IP, UUID, etc.) |
| [references/number-rules.md](references/number-rules.md) | Numeric validation (int32, int64, float, double, etc.) |
| [references/complex-rules.md](references/complex-rules.md) | Complex types (repeated, map, enum, bytes, etc.) |
| [references/message-rules.md](references/message-rules.md) | Message-level validation, oneof rules |

### CEL & Custom Rules

| File | When to Load |
|------|-------------|
| [references/cel-expressions.md](references/cel-expressions.md) | CEL syntax, functions, cross-field validation |
| [references/custom-errors.md](references/custom-errors.md) | Custom error messages, localization |

### Examples

| File | When to Load |
|------|-------------|
| [examples/common-patterns.md](examples/common-patterns.md) | Common validation patterns |
| [examples/chinese-validation.md](examples/chinese-validation.md) | Chinese-specific validation (mobile, ID card, etc.) |

### Framework Integrations

| File | When to Load |
|------|-------------|
| [integrations/kratos.md](integrations/kratos.md) | Go-Kratos framework integration |

> Other framework integrations (go-zero, Spring Boot, etc.) can be added to `integrations/` directory.

## Field Types Overview

### Scalar Types

| Proto Type | Rules Type | Example |
|------------|------------|---------|
| `string` | `StringRules` | `[(buf.validate.field).string.min_len = 1]` |
| `int32` | `Int32Rules` | `[(buf.validate.field).int32.gt = 0]` |
| `int64` | `Int64Rules` | `[(buf.validate.field).int64.gte = 1]` |
| `uint32` | `UInt32Rules` | `[(buf.validate.field).uint32.lte = 100]` |
| `uint64` | `UInt64Rules` | `[(buf.validate.field).uint64.gt = 0]` |
| `float` | `FloatRules` | `[(buf.validate.field).float.gte = 0.0]` |
| `double` | `DoubleRules` | `[(buf.validate.field).double.lt = 100.0]` |
| `bool` | `BoolRules` | `[(buf.validate.field).bool.const = true]` |
| `bytes` | `BytesRules` | `[(buf.validate.field).bytes.min_len = 1]` |

### Complex Types

| Proto Type | Rules Type | Example |
|------------|------------|---------|
| `enum` | `EnumRules` | `[(buf.validate.field).enum.defined_only = true]` |
| `repeated` | `RepeatedRules` | `[(buf.validate.field).repeated.min_items = 1]` |
| `map` | `MapRules` | `[(buf.validate.field).map.min_pairs = 1]` |
| `message` | `MessageRules` | `[(buf.validate.field).required = true]` |

## Common Validation Rules

### String Rules

| Rule | Description | Example |
|------|-------------|---------|
| `min_len` | Minimum character count (Unicode) | `min_len: 3` |
| `max_len` | Maximum character count (Unicode) | `max_len: 32` |
| `len` | Exact character count | `len: 11` |
| `min_bytes` | Minimum byte count | `min_bytes: 1` |
| `max_bytes` | Maximum byte count | `max_bytes: 255` |
| `pattern` | RE2 regex pattern | `pattern: "^[a-z]+$"` |
| `prefix` | Must start with | `prefix: "https://"` |
| `suffix` | Must end with | `suffix: ".com"` |
| `contains` | Must contain substring | `contains: "@"` |
| `not_contains` | Must not contain | `not_contains: "spam"` |
| `in` | Must be one of values | `in: ["a", "b", "c"]` |
| `not_in` | Must not be one of | `not_in: ["admin", "root"]` |
| `email` | Valid email format | `email: true` |
| `hostname` | Valid hostname | `hostname: true` |
| `ip` | Valid IP (v4/v6) | `ip: true` |
| `ipv4` | Valid IPv4 only | `ipv4: true` |
| `ipv6` | Valid IPv6 only | `ipv6: true` |
| `uri` | Valid URI | `uri: true` |
| `uuid` | Valid UUID | `uuid: true` |
| `const` | Must equal exactly | `const: "fixed"` |

### Numeric Rules

| Rule | Description | Example |
|------|-------------|---------|
| `const` | Must equal exactly | `const: 42` |
| `lt` | Less than (exclusive) | `lt: 100` |
| `lte` | Less than or equal | `lte: 100` |
| `gt` | Greater than (exclusive) | `gt: 0` |
| `gte` | Greater than or equal | `gte: 1` |
| `in` | Must be one of values | `in: [1, 2, 3]` |
| `not_in` | Must not be one of | `not_in: [0, -1]` |

### Float/Double Only

| Rule | Description | Example |
|------|-------------|---------|
| `finite` | Must be finite (not NaN/Inf) | `finite: true` |

## Ignore Options

```protobuf
// Ignore if field is unset or zero value
string optional_field = 1 [
  (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
  (buf.validate.field).string.email = true
];

// Always ignore validation (useful for development)
string dev_field = 2 [
  (buf.validate.field).ignore = IGNORE_ALWAYS
];
```

## Required Fields

```protobuf
message Request {
  // For fields with presence tracking (optional, message types)
  optional string name = 1 [(buf.validate.field).required = true];

  // Message type - required means must be set
  User user = 2 [(buf.validate.field).required = true];
}
```

## CEL Expressions

### Basic CEL Syntax

```protobuf
message Example {
  // Field-level CEL
  int32 value = 1 [(buf.validate.field).cel = {
    id: "value_positive",
    message: "value must be positive",
    expression: "this > 0"
  }];

  // Simplified CEL (id and message derived from expression)
  int32 value2 = 2 [(buf.validate.field).cel_expression = "this > 0"];

  // Message-level CEL for cross-field validation
  option (buf.validate.message).cel = {
    id: "password_match",
    message: "passwords must match",
    expression: "this.password == this.confirm_password"
  };

  string password = 1;
  string confirm_password = 2;
}
```

### CEL Functions

| Function | Description | Example |
|----------|-------------|---------|
| `size()` | String/repeated/map size | `size(this) <= 32` |
| `matches()` | Regex match (RE2) | `this.matches('^[a-z]+$')` |
| `startsWith()` | Prefix check | `this.startsWith('http')` |
| `endsWith()` | Suffix check | `this.endsWith('.com')` |
| `contains()` | Substring check | `this.contains('@')` |
| `isEmail()` | Email validation | `this.isEmail()` |
| `isHostname()` | Hostname validation | `this.isHostname()` |
| `isIp()` | IP validation | `this.isIp()` |
| `isIpv4()` | IPv4 validation | `this.isIpv4()` |
| `isIpv6()` | IPv6 validation | `this.isIpv6()` |
| `isUri()` | URI validation | `this.isUri()` |
| `isUuid()` | UUID validation | `this.isUuid()` |
| `has()` | Field presence check | `has(this.field)` |
| `getType()` | Get field type | `getType(this)` |

### CEL for Chinese Validation

```protobuf
// Chinese mobile phone
string mobile = 1 [(buf.validate.field).cel = {
  id: "mobile_format",
  message: "手机号格式错误，必须为11位有效手机号",
  expression: "this.matches('^1[3-9][0-9]{9}$')"
}];

// Chinese ID card (18 digits)
string id_card = 2 [(buf.validate.field).cel = {
  id: "id_card_format",
  message: "身份证号格式错误",
  expression: "this.matches('^[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]$')"
}];
```

## Best Practices

### Always Follow

- Use `buf.validate.field` for field-level rules
- Use `buf.validate.message` for cross-field validation
- Provide meaningful `id` and `message` for CEL rules
- Use `IGNORE_IF_ZERO_VALUE` for optional fields
- Test validation rules with edge cases

### Never Do

- Use `protoc-gen-validate` syntax (deprecated)
- Mix `buf.validate` with `validate` imports
- Use `\d` in regex patterns (use `[0-9]` instead)
- Reference other fields in field-level CEL (use message-level instead)
- Modify generated `.pb.go` files

## Framework Integration

### Kratos Middleware

```go
// pkg/middleware/validate.go
package middleware

import (
    "context"
    stderrors "errors"
    "buf.build/go/protovalidate"
    "github.com/go-kratos/kratos/v2/middleware"
    "google.golang.org/protobuf/proto"
    v1 "your-project/api/v1"
)

var validator protovalidate.Validator

func init() {
    var err error
    validator, err = protovalidate.New()
    if err != nil {
        panic(err)
    }
}

func Validator() middleware.Middleware {
    return func(handler middleware.Handler) middleware.Handler {
        return func(ctx context.Context, req interface{}) (reply interface{}, err error) {
            if msg, ok := req.(proto.Message); ok {
                if err := validator.Validate(msg); err != nil {
                    var valErr *protovalidate.ValidationError
                    if stderrors.As(err, &valErr) {
                        violations := valErr.Violations
                        if len(violations) > 0 && violations[0].Proto.GetMessage() != "" {
                            return nil, v1.ErrorBadRequest(violations[0].Proto.GetMessage())
                        }
                    }
                    return nil, v1.ErrorBadRequest(err.Error())
                }
            }
            return handler(ctx, req)
        }
    }
}
```

### buf.gen.yaml Configuration

```yaml
# v2 format
version: v2
managed:
  enabled: true
  disable:
    - file_option: go_package_prefix
      module: buf.build/bufbuild/protovalidate
plugins:
  - local: protoc-gen-go
    out: .
    opt:
      - paths=source_relative
  - local: protoc-gen-go-grpc
    out: .
    opt:
      - paths=source_relative
  - local: protoc-gen-go-http
    out: .
    opt:
      - paths=source_relative
```

## Resources

| Resource | URL |
|----------|-----|
| Official Documentation | https://protovalidate.com |
| Go Implementation | https://github.com/bufbuild/protovalidate-go |
| Java Implementation | https://github.com/bufbuild/protovalidate-java |
| Python Implementation | https://github.com/bufbuild/protovalidate-python |
| C++ Implementation | https://github.com/bufbuild/protovalidate-cc |
| CEL Specification | https://cel.dev |

---

**Quick invocation**: Use `/protovalidate-skills` or ask "How do I validate [field type] with protovalidate?"
