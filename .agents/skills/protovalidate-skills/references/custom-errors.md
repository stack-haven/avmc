# Custom Error Messages

Guide for implementing custom error messages in protovalidate.

## CEL Rule with Custom Message

### Basic Structure

```protobuf
message Example {
  string field = 1 [(buf.validate.field).cel = {
    id: "rule_identifier",
    message: "Your custom error message here",
    expression: "this > 0"
  }];
}
```

### Chinese Error Messages

```protobuf
message User {
  string username = 1 [(buf.validate.field).cel = {
    id: "username_format",
    message: "用户名必须为3-32个字符，只能包含字母、数字和下划线",
    expression: "this.matches('^[a-zA-Z0-9_]{3,32}$')"
  }];

  string mobile = 2 [(buf.validate.field).cel = {
    id: "mobile_format",
    message: "手机号格式错误，必须为11位有效手机号",
    expression: "this.matches('^1[3-9][0-9]{9}$')"
  }];
}
```

## Error Message Extraction (Go)

### Middleware Implementation

```go
func Validator() middleware.Middleware {
	return func(handler middleware.Handler) middleware.Handler {
		return func(ctx context.Context, req interface{}) (reply interface{}, err error) {
			if msg, ok := req.(proto.Message); ok {
				if err := validator.Validate(msg); err != nil {
					var valErr *protovalidate.ValidationError
					if stderrors.As(err, &valErr) {
						violations := valErr.Violations
						if len(violations) > 0 && violations[0].Proto.GetMessage() != "" {
							// Return custom message from proto
							return nil, v1.ErrorBadRequest(violations[0].Proto.GetMessage())
						}
					}
					// Fallback to default error
					return nil, v1.ErrorBadRequest(err.Error())
				}
			}
			return handler(ctx, req)
		}
	}
}
```

### Violation Structure

```go
type ValidationError struct {
    Violations []*Violation
}

type Violation struct {
    Proto *ViolationProto
    // ...
}

type ViolationProto struct {
    Id          string
    Message     string
    Expression  string
    // ...
}
```

## Multiple Rules with Different Messages

```protobuf
message Password {
  string value = 1 [
    (buf.validate.field).cel = {
      id: "password_min_length",
      message: "密码至少需要8个字符",
      expression: "size(this) >= 8"
    },
    (buf.validate.field).cel = {
      id: "password_max_length",
      message: "密码不能超过32个字符",
      expression: "size(this) <= 32"
    },
    (buf.validate.field).cel = {
      id: "password_complexity",
      message: "密码必须包含字母和数字",
      expression: "this.matches('^(?=.*[a-zA-Z])(?=.*[0-9]).*$')"
    }
  ];
}
```

## Dynamic Error Messages

Using CEL `format()` function for dynamic messages:

```protobuf
message Example {
  string name = 1 [(buf.validate.field).cel = {
    id: "name_length",
    expression: "size(this) < 3 ? '名称长度至少需要3个字符，当前只有%d个'.format([size(this)]) : ''"
  }];
}
```

## Standard Rules vs CEL

### Standard Rules (English Default)

```protobuf
string email = 1 [(buf.validate.field).string.email = true];
// Error: "value must be a valid email address"
```

### CEL with Custom Message

```protobuf
string email = 1 [(buf.validate.field).cel = {
  id: "email_format",
  message: "请输入有效的邮箱地址",
  expression: "this.isEmail()"
}];
```

## Best Practices

1. **Always provide `id`**: Unique identifier for debugging
2. **Use meaningful messages**: Clear, actionable error descriptions
3. **Consistent language**: Use same language throughout the API
4. **Include constraints**: Show what values are allowed
5. **Localization**: Consider i18n for multi-language support

## Error Response Format

```json
{
  "code": 400,
  "reason": "BAD_REQUEST",
  "message": "用户名必须为3-32个字符，只能包含字母、数字和下划线",
  "metadata": {
    "field": "username",
    "rule_id": "username_format"
  }
}
```
