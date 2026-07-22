# String Validation Rules

Complete reference for `StringRules` in protovalidate.

## Length Rules

### `len` - Exact Length

Specifies the exact number of **Unicode characters** (code points), not bytes.

```protobuf
// Must be exactly 11 characters
string phone = 1 [(buf.validate.field).string.len = 11];

// Chinese characters count as 1 character each
string code = 2 [(buf.validate.field).string.len = 6];  // "中文测试代码" = 6 chars ✅
```

### `min_len` - Minimum Length

```protobuf
// At least 3 characters
string username = 1 [(buf.validate.field).string.min_len = 3];
```

### `max_len` - Maximum Length

```protobuf
// At most 32 characters
string nickname = 1 [(buf.validate.field).string.max_len = 32];
```

### `len_bytes` - Exact Byte Length

```protobuf
// Must be exactly 32 bytes
string hash = 1 [(buf.validate.field).string.len_bytes = 32];
```

### `min_bytes` - Minimum Byte Length

```protobuf
// At least 1 byte
string data = 1 [(buf.validate.field).string.min_bytes = 1];
```

### `max_bytes` - Maximum Byte Length

```protobuf
// At most 255 bytes (useful for database varchar limits)
string description = 1 [(buf.validate.field).string.max_bytes = 255];

// For Chinese: 3 bytes per character, so 32 chars = 96 bytes max
string chinese_name = 2 [(buf.validate.field).string.max_bytes = 96];
```

## Pattern Rules

### `pattern` - Regular Expression (RE2)

Uses RE2 syntax. **Note: Use `[0-9]` instead of `\d`**.

```protobuf
// Alphanumeric with underscore
string username = 1 [(buf.validate.field).string.pattern = "^[a-zA-Z0-9_]+$"];

// Hexadecimal only
string hex = 2 [(buf.validate.field).string.pattern = "^[a-fA-F0-9]+$"];

// Case-insensitive using (?i) prefix
string code = 3 [(buf.validate.field).string.pattern = "(?i)^[a-z]+$"];
```

### `prefix` - Must Start With

```protobuf
// URL must start with https://
string url = 1 [(buf.validate.field).string.prefix = "https://"];
```

### `suffix` - Must End With

```protobuf
// Email must end with .com
string email = 1 [(buf.validate.field).string.suffix = ".com"];
```

### `contains` - Must Contain Substring

```protobuf
// Must contain @ symbol
string email = 1 [(buf.validate.field).string.contains = "@"];
```

### `not_contains` - Must Not Contain

```protobuf
// Must not contain spam
string content = 1 [(buf.validate.field).string.not_contains = "spam"];
```

## Value Rules

### `const` - Exact Value

```protobuf
// Must equal "hello"
string greeting = 1 [(buf.validate.field).string.const = "hello"];
```

### `in` - Must Be One Of

```protobuf
// Single value syntax
string status = 1 [
  (buf.validate.field).string.in = "active",
  (buf.validate.field).string.in = "inactive",
  (buf.validate.field).string.in = "pending"
];

// Array syntax (in proto file)
string role = 2 [(buf.validate.field).string = { in: ["admin", "user", "guest"] }];
```

### `not_in` - Must Not Be One Of

```protobuf
// Cannot be reserved usernames
string username = 1 [(buf.validate.field).string = {
  not_in: ["admin", "root", "system", "administrator"]
}];
```

## Well-Known Format Rules

### `email` - Email Address

Validates against HTML5 email specification.

```protobuf
string email = 1 [(buf.validate.field).string.email = true];
```

### `hostname` - Hostname

Validates domain names like `example.com`.

```protobuf
string hostname = 1 [(buf.validate.field).string.hostname = true];
```

### `ip` - IP Address (v4 or v6)

```protobuf
string ip_address = 1 [(buf.validate.field).string.ip = true];
```

### `ipv4` - IPv4 Only

```protobuf
string ipv4 = 1 [(buf.validate.field).string.ipv4 = true];
```

### `ipv6` - IPv6 Only

```protobuf
string ipv6 = 1 [(buf.validate.field).string.ipv6 = true];
```

### `uri` - URI/URL

```protobuf
string website = 1 [(buf.validate.field).string.uri = true];
```

### `uri_ref` - URI Reference

Allows relative URIs.

```protobuf
string path = 1 [(buf.validate.field).string.uri_ref = true];
```

### `uuid` - UUID

```protobuf
string id = 1 [(buf.validate.field).string.uuid = true];
```

### `datetime` - ISO 8601 DateTime

```protobuf
string created_at = 1 [(buf.validate.field).string.datetime = true];
```

### `date` - ISO 8601 Date

```protobuf
string birth_date = 1 [(buf.validate.field).string.date = true];
```

### `time` - ISO 8601 Time

```protobuf
string event_time = 1 [(buf.validate.field).string.time = true];
```

### `duration` - Duration String

```protobuf
string timeout = 1 [(buf.validate.field).string.duration = true];  // e.g., "1h30m"
```

## Strictness Options

### `strict` - Strict Validation

When used with format rules like `email`, enables stricter validation.

```protobuf
string email = 1 [(buf.validate.field).string = {
  email: true,
  strict: true
}];
```

## Well-Known Regex Patterns

Protovalidate provides predefined regex patterns via `KnownRegex` enum:

| Pattern | Description |
|---------|-------------|
| `KNOWN_REGEX_UNSPECIFIED` | No predefined pattern |
| `KNOWN_REGEX_HTTP_HEADER_NAME` | Valid HTTP header name |
| `KNOWN_REGEX_HTTP_HEADER_VALUE` | Valid HTTP header value |

```protobuf
string header_name = 1 [(buf.validate.field).string = {
  well_known_regex: KNOWN_REGEX_HTTP_HEADER_NAME,
  strict: false
}];
```

## Example: Combined Rules

```protobuf
message User {
  // Username: 3-32 chars, alphanumeric + underscore
  string username = 1 [(buf.validate.field).string = {
    min_len: 3,
    max_len: 32,
    pattern: "^[a-zA-Z0-9_]+$"
  }];

  // Email: valid format, max 255 bytes
  string email = 2 [(buf.validate.field).string = {
    email: true,
    max_bytes: 255
  }];

  // Password: 8-32 chars
  string password = 3 [(buf.validate.field).string = {
    min_len: 8,
    max_len: 32
  }];

  // Nickname: optional, max 32 chars if provided
  string nickname = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.max_len = 32
  ];

  // Phone: exactly 11 digits (Chinese mobile)
  string mobile = 5 [(buf.validate.field).cel = {
    id: "mobile_format",
    message: "手机号格式错误",
    expression: "this.matches('^1[3-9][0-9]{9}$')"
  }];
}
```

## Chinese Character Considerations

- `size()` and `len`/`min_len`/`max_len` count **Unicode code points**, not bytes
- Each Chinese character = 1 code point
- UTF-8 encoding: 1 Chinese character = 3 bytes

```protobuf
// 32 Chinese characters max
string name = 1 [(buf.validate.field).string.max_len = 32];

// If database has byte limit, use max_bytes
// For varchar(96): 32 Chinese chars × 3 bytes = 96 bytes
string name_db = 2 [(buf.validate.field).string.max_bytes = 96];
```
