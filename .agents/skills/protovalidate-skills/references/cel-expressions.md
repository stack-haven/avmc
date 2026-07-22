# CEL Expressions Reference

Common Expression Language (CEL) is used in protovalidate for custom validation rules.

## Basic Syntax

### Rule Structure

```protobuf
message Example {
  // Full CEL rule with id and message
  string value = 1 [(buf.validate.field).cel = {
    id: "rule_identifier",
    message: "Error message when validation fails",
    expression: "this > 0"
  }];

  // Simplified CEL (id = expression, message auto-generated)
  int32 count = 2 [(buf.validate.field).cel_expression = "this > 0"];
}
```

### Message-Level CEL

```protobuf
message PasswordChange {
  option (buf.validate.message).cel = {
    id: "password_match",
    message: "Passwords must match",
    expression: "this.new_password == this.confirm_password"
  };

  string new_password = 1;
  string confirm_password = 2;
}
```

## CEL Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `this` | Current field value | `this > 0` |
| `rules` | Current rules object | `rules.min_len` |
| `now` | Current timestamp | `this > now` |

## String Functions

### `size()` - Length

Returns the number of Unicode code points.

```protobuf
// String length check
expression: "size(this) >= 3 && size(this) <= 32"

// Works correctly with Chinese
expression: "size(this) <= 32"  // "中文测试" = 4
```

### `matches(pattern)` - Regex

RE2 regex matching. Use `[0-9]` instead of `\d`.

```protobuf
// Alphanumeric
expression: "this.matches('^[a-zA-Z0-9]+$')"

// Chinese mobile
expression: "this.matches('^1[3-9][0-9]{9}$')"

// Email-like pattern
expression: "this.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+[.][a-zA-Z]{2,}$')"
```

### `startsWith(prefix)` / `endsWith(suffix)`

```protobuf
// URL check
expression: "this.startsWith('https://')"

// File extension
expression: "this.endsWith('.pdf')"
```

### `contains(substring)`

```protobuf
// Must contain @
expression: "this.contains('@')"
```

### String Formatting

```protobuf
// Format error message dynamically
expression: "size(this) < rules.min_len ? 'Length must be at least %s'.format([rules.min_len]) : ''"
```

## Numeric Functions

### Comparison Operators

```protobuf
// Greater than
expression: "this > 0"

// Range
expression: "this >= 0 && this <= 100"

// In list
expression: "this in [1, 2, 3]"
```

### Math Functions

```protobuf
// Absolute value
expression: "abs(this) < 100"

// Type conversion
expression: "int(this) == this"
expression: "double(this) > 0.0"
```

## Boolean Functions

```protobuf
// Negation
expression: "!this"

// Boolean must be true
expression: "this == true"
```

## Collection Functions

### `in` Operator

```protobuf
// Check if in list
expression: "this in ['active', 'pending', 'complete']"

// Numeric in
expression: "this in [1, 2, 3, 4, 5]"
```

### `size()` for Collections

```protobuf
// Array/map length
expression: "size(this) >= 1"
```

## Type Checking Functions

### `has(field)` - Field Presence

Checks if an optional field is set.

```protobuf
// Message-level: check if field is set
option (buf.validate.message).cel = {
  id: "conditional_required",
  message: "end_date is required when status is 'completed'",
  expression: "this.status != 'completed' || has(this.end_date)"
};
```

### Type Functions

```protobuf
// Check type
expression: "type(this) == string"
```

## Well-Known Type Functions

### Email/URL/IP Validation

```protobuf
// Email
expression: "this.isEmail()"

// Hostname
expression: "this.isHostname()"

// IP (v4 or v6)
expression: "this.isIp()"

// IPv4 only
expression: "this.isIpv4()"

// IPv6 only
expression: "this.isIpv6()"

// URI
expression: "this.isUri()"

// UUID
expression: "this.isUuid()"
```

## Cross-Field Validation

Cross-field validation must be done at the **message level**, not field level.

```protobuf
message DateRange {
  option (buf.validate.message).cel = {
    id: "end_after_start",
    message: "End date must be after start date",
    expression: "this.end_date >= this.start_date"
  };

  int64 start_date = 1;
  int64 end_date = 2;
}

message Order {
  option (buf.validate.message).cel = {
    id: "discount_logic",
    message: "Discount cannot exceed 50% for orders under $100",
    expression: "this.total < 100 ? this.discount <= 0.5 : true"
  };

  double total = 1;
  double discount = 2;
}
```

## Conditional Validation

### Required Based on Another Field

```protobuf
message Shipping {
  option (buf.validate.message).cel = {
    id: "address_required_for_delivery",
    message: "Address is required for delivery orders",
    expression: "this.type != 'delivery' || size(this.address) > 0"
  };

  string type = 1;
  string address = 2;
}
```

### Mutual Exclusivity

```protobuf
message Payment {
  option (buf.validate.message).cel = {
    id: "single_payment_method",
    message: "Only one payment method allowed",
    expression: "!(has(this.credit_card) && has(this.bank_account))"
  };

  optional CreditCard credit_card = 1;
  optional BankAccount bank_account = 2;
}
```

## Error Message Best Practices

### Custom Messages

```protobuf
// Chinese error message
string mobile = 1 [(buf.validate.field).cel = {
  id: "mobile_format",
  message: "手机号格式错误，必须为11位有效手机号",
  expression: "this.matches('^1[3-9][0-9]{9}$')"
}];

// Dynamic message using format
string username = 2 [(buf.validate.field).cel = {
  id: "username_length",
  expression: "size(this) < 3 ? '用户名至少需要3个字符，当前%d个'.format([size(this)]) : ''"
}];
```

### Multiple Rules with Different Messages

```protobuf
string password = 1 [(buf.validate.field).cel = {
  id: "password_min_length",
  message: "密码至少需要8个字符",
  expression: "size(this) >= 8"
}];

// Or use multiple cel rules
string password2 = 2 [
  (buf.validate.field).cel = {
    id: "password_min",
    message: "密码至少需要8个字符",
    expression: "size(this) >= 8"
  },
  (buf.validate.field).cel = {
    id: "password_max",
    message: "密码不能超过32个字符",
    expression: "size(this) <= 32"
  }
];
```

## Common Patterns

### Chinese Mobile Phone

```protobuf
string mobile = 1 [(buf.validate.field).cel = {
  id: "chinese_mobile",
  message: "手机号格式错误",
  expression: "this.matches('^1[3-9][0-9]{9}$')"
}];
```

### Chinese ID Card (18-digit)

```protobuf
string id_card = 1 [(buf.validate.field).cel = {
  id: "chinese_id_card",
  message: "身份证号格式错误",
  expression: "this.matches('^[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]$')"
}];
```

### Password Strength

```protobuf
string password = 1 [(buf.validate.field).cel = {
  id: "password_strength",
  message: "密码必须包含字母和数字，长度8-32",
  expression: "this.matches('^(?=.*[a-zA-Z])(?=.*[0-9]).{8,32}$')"
}];
```

### Username Format

```protobuf
string username = 1 [(buf.validate.field).cel = {
  id: "username_format",
  message: "用户名必须为3-32个字符，只能包含字母、数字和下划线",
  expression: "this.matches('^[a-zA-Z0-9_]{3,32}$')"
}];
```

## Gotchas

### Don't Use `\d`

CEL uses RE2 which doesn't support `\d` escape. Use `[0-9]` instead.

```protobuf
// ❌ Wrong
expression: "this.matches('^\\d{11}$')"

// ✅ Correct
expression: "this.matches('^[0-9]{11}$')"
```

### No Cross-Field in Field-Level CEL

```protobuf
// ❌ Wrong - can't reference other fields in field-level CEL
string field1 = 1 [(buf.validate.field).cel = {
  expression: "this != field2"  // Error!
}];

// ✅ Correct - use message-level CEL
message Example {
  option (buf.validate.message).cel = {
    expression: "this.field1 != this.field2"
  };
  string field1 = 1;
  string field2 = 2;
}
```

### String Length vs Bytes

```protobuf
// size() = characters (Unicode code points)
expression: "size(this) <= 32"  // 32 chars, even for Chinese

// For byte limit, use bytes() conversion
expression: "size(bytes(this)) <= 96"  // 96 bytes = ~32 Chinese chars
```
