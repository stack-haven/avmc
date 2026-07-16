# Message-Level Validation Rules

Complete reference for `MessageRules`, `OneofRules`, and message-level CEL validation.

## Message-Level Rules

### `required` - Field Must Be Set

For fields that track presence (message types, `optional` fields, oneof members).

```protobuf
message Request {
  // Message field must be set
  User user = 1 [(buf.validate.field).required = true];

  // Optional string must be set (can be empty string)
  optional string name = 2 [(buf.validate.field).required = true];

  // Optional bool must be set (can be false)
  optional bool enabled = 3 [(buf.validate.field).required = true];
}
```

### `cel` - Message-Level CEL

For cross-field validation and complex rules.

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
```

### Multiple CEL Rules

```protobuf
message Registration {
  // Multiple message-level rules
  option (buf.validate.message).cel = {
    id: "password_match",
    message: "Passwords must match",
    expression: "this.password == this.confirm_password"
  };

  option (buf.validate.message).cel = {
    id: "terms_accepted",
    message: "Terms must be accepted for registration",
    expression: "this.accept_terms == true"
  };

  string password = 1;
  string confirm_password = 2;
  bool accept_terms = 3;
}
```

### `cel_expression` - Simplified CEL

```protobuf
message Example {
  // Simple expression without id/message
  option (buf.validate.message).cel_expression = "this.start < this.end";
  option (buf.validate.message).cel_expression = "this.count >= 0";

  int64 start = 1;
  int64 end = 2;
  int32 count = 3;
}
```

## Oneof Rules

### `required` - Oneof Must Have Value

```protobuf
message Payment {
  oneof method {
    // Exactly one must be set
    option (buf.validate.oneof).required = true;

    string credit_card = 1;
    string bank_account = 2;
    string paypal = 3;
  }
}
```

### Combined with Field Rules

```protobuf
message Contact {
  oneof contact_method {
    option (buf.validate.oneof).required = true;

    // Email must be valid format
    string email = 1 [(buf.validate.field).string.email = true];

    // Phone must be 11 digits
    string phone = 2 [(buf.validate.field).string.len = 11];
  }
}
```

## Virtual Oneof (Message-Level)

Use `oneof` rule at message level for more flexibility than proto oneof:

```protobuf
message UpdateRequest {
  // At most one of these fields can be set
  option (buf.validate.message).oneof = {
    fields: ["email", "phone"]
  };

  // Exactly one must be set
  option (buf.validate.message).oneof = {
    fields: ["username", "user_id"],
    required: true
  };

  string email = 1;
  string phone = 2;
  string username = 3;
  int64 user_id = 4;
}
```

### Multiple Virtual Oneofs

```protobuf
message SearchRequest {
  // Either query OR filters (not both)
  option (buf.validate.message).oneof = {
    fields: ["query", "filters"]
  };

  // At least one of these must be set
  option (buf.validate.message).oneof = {
    fields: ["page", "cursor"],
    required: true
  };

  string query = 1;
  Filters filters = 2;
  int32 page = 3;
  string cursor = 4;
}
```

## Cross-Field Validation Patterns

### Conditional Required

```protobuf
message Order {
  option (buf.validate.message).cel = {
    id: "shipping_address_required",
    message: "Shipping address required for delivery orders",
    expression: "this.type != 'delivery' || has(this.shipping_address)"
  };

  string type = 1;  // "delivery", "pickup", etc.
  Address shipping_address = 2;
}
```

### Conditional Forbidden

```protobuf
message Discount {
  option (buf.validate.message).cel = {
    id: "no_loyalty_points_for_guests",
    message: "Guest users cannot use loyalty points",
    expression: "!this.is_guest || !has(this.loyalty_points)"
  };

  bool is_guest = 1;
  int32 loyalty_points = 2;
}
```

### Value Dependency

```protobuf
message Pricing {
  option (buf.validate.message).cel = {
    id: "discount_validation",
    message: "Discount cannot exceed 50% of original price",
    expression: "this.discount <= this.original_price * 0.5"
  };

  option (buf.validate.message).cel = {
    id: "final_price_positive",
    message: "Final price must be positive",
    expression: "this.original_price - this.discount > 0"
  };

  double original_price = 1;
  double discount = 2;
}
```

### Date/Time Validation

```protobuf
message Event {
  option (buf.validate.message).cel = {
    id: "end_after_start",
    message: "End time must be after start time",
    expression: "this.end_time > this.start_time"
  };

  option (buf.validate.message).cel = {
    id: "start_future",
    message: "Start time must be in the future",
    expression: "this.start_time > now"
  };

  int64 start_time = 1;
  int64 end_time = 2;
}
```

### Array/Map Size Relationship

```protobuf
message Batch {
  option (buf.validate.message).cel = {
    id: "counts_match",
    message: "Item count must match IDs count",
    expression: "size(this.items) == size(this.item_ids)"
  };

  repeated Item items = 1;
  repeated int64 item_ids = 2;
}
```

## Ignore Options

### `IGNORE_UNSPECIFIED` (Default)

Ignore rules if field tracks presence and is unset.

```protobuf
// Default behavior
string optional_field = 1 [(buf.validate.field).string.email = true];
```

### `IGNORE_IF_ZERO_VALUE`

Ignore if field is unset OR is zero value (empty string, 0, false, etc.).

```protobuf
// Email only validated if not empty
string email = 1 [
  (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
  (buf.validate.field).string.email = true
];

// ID only validated if not 0
int64 optional_id = 2 [
  (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
  (buf.validate.field).int64.gt = 0
];
```

### `IGNORE_ALWAYS`

Skip all validation (useful for development/debugging).

```protobuf
// Skip validation temporarily
string debug_field = 1 [
  (buf.validate.field).ignore = IGNORE_ALWAYS
];
```

## Common Patterns

### User Registration

```protobuf
message RegisterRequest {
  option (buf.validate.message).cel = {
    id: "password_match",
    message: "两次输入的密码不一致",
    expression: "this.password == this.confirm_password"
  };

  string username = 1 [(buf.validate.field).cel = {
    id: "username_format",
    message: "用户名必须为3-32个字符，只能包含字母、数字和下划线",
    expression: "this.matches('^[a-zA-Z0-9_]{3,32}$')"
  }];

  string password = 2 [(buf.validate.field).cel = {
    id: "password_length",
    message: "密码必须为6-32个字符",
    expression: "size(this) >= 6 && size(this) <= 32"
  }];

  string confirm_password = 3;

  string mobile = 4 [(buf.validate.field).cel = {
    id: "mobile_format",
    message: "手机号格式错误",
    expression: "this.matches('^1[3-9][0-9]{9}$')"
  }];
}
```

### Update Request (Partial Updates)

```protobuf
message UpdateUserRequest {
  // At least one field must be set
  option (buf.validate.message).cel = {
    id: "at_least_one_field",
    message: "至少需要提供一个要更新的字段",
    expression: "has(this.nickname) || has(this.avatar) || has(this.mobile)"
  };

  int64 id = 1 [(buf.validate.field).int64.gt = 0];

  optional string nickname = 2 [
    (buf.validate.field).cel = {
      id: "nickname_length",
      message: "昵称长度不能超过32个字符",
      expression: "size(this) <= 32"
    }
  ];

  optional string avatar = 3 [(buf.validate.field).string.uri = true];

  optional string mobile = 4 [(buf.validate.field).cel = {
    id: "mobile_format",
    message: "手机号格式错误",
    expression: "this.matches('^1[3-9][0-9]{9}$')"
  }];
}
```

### Search with Pagination

```protobuf
message SearchRequest {
  option (buf.validate.message).cel = {
    id: "valid_pagination",
    message: "分页参数无效",
    expression: "this.page >= 1 && this.page_size >= 1 && this.page_size <= 100"
  };

  string keyword = 1 [(buf.validate.field).string.min_len = 1];
  int32 page = 2 [(buf.validate.field).int32.gte = 1];
  int32 page_size = 3 [(buf.validate.field).int32 = { gte: 1, lte: 100 }];
}
```
