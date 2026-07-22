# Common Validation Patterns

Practical examples for common validation scenarios.

## User Management

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

  string mobile = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).cel = {
      id: "mobile_format",
      message: "手机号格式错误",
      expression: "this.matches('^1[3-9][0-9]{9}$')"
    }
  ];

  string email = 5 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.email = true
  ];
}
```

### User Profile Update

```protobuf
message UpdateUserRequest {
  option (buf.validate.message).cel = {
    id: "at_least_one_field",
    message: "至少需要提供一个要更新的字段",
    expression: "has(this.nickname) || has(this.avatar) || has(this.mobile) || has(this.email)"
  };

  int64 id = 1 [(buf.validate.field).int64.gt = 0];

  optional string nickname = 2 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).cel = {
      id: "nickname_length",
      message: "昵称长度不能超过32个字符",
      expression: "size(this) <= 32"
    }
  ];

  optional string avatar = 3 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.uri = true
  ];

  optional string mobile = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).cel = {
      id: "mobile_format",
      message: "手机号格式错误",
      expression: "this.matches('^1[3-9][0-9]{9}$')"
    }
  ];

  optional string email = 5 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.email = true
  ];
}
```

### Login Request

```protobuf
message LoginRequest {
  string username = 1 [(buf.validate.field).cel = {
    id: "login_username_format",
    message: "用户名必须为3-32个字符，只能包含字母、数字和下划线",
    expression: "this.matches('^[a-zA-Z0-9_]{3,32}$')"
  }];

  string password = 2 [(buf.validate.field).cel = {
    id: "login_password_length",
    message: "密码必须为6-32个字符",
    expression: "size(this) >= 6 && size(this) <= 32"
  }];
}
```

## Role & Permission

### Create Role

```protobuf
message CreateRoleRequest {
  string name = 1 [(buf.validate.field).cel = {
    id: "role_name_format",
    message: "角色名称必须为2-50个字符",
    expression: "size(this) >= 2 && size(this) <= 50"
  }];

  string code = 2 [(buf.validate.field).cel = {
    id: "role_code_format",
    message: "角色代码必须为大写字母、数字和下划线，2-32个字符",
    expression: "this.matches('^[A-Z][A-Z0-9_]{1,31}$')"
  }];

  string description = 3 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).cel = {
      id: "role_desc_length",
      message: "描述不能超过200个字符",
      expression: "size(this) <= 200"
    }
  ];

  repeated int64 menu_ids = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).repeated = {
      items: {
        int64: { gt: 0 }
      }
    }
  ];
}
```

## Menu Management

### Create Menu

```protobuf
message CreateMenuRequest {
  int64 parent_id = 1 [(buf.validate.field).int64.gte = 0];

  string name = 2 [(buf.validate.field).cel = {
    id: "menu_name_required",
    message: "菜单名称不能为空",
    expression: "size(this) > 0"
  }];

  string path = 3 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).cel = {
      id: "menu_path_format",
      message: "路径格式错误",
      expression: "this.startsWith('/')"
    }
  ];

  string component = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.max_len = 255
  ];

  string icon = 5 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.max_len = 64
  ];

  int32 sort = 6 [(buf.validate.field).int32.gte = 0];

  enum MenuType {
    MENU_TYPE_UNSPECIFIED = 0;
    MENU_TYPE_DIRECTORY = 1;
    MENU_TYPE_MENU = 2;
    MENU_TYPE_BUTTON = 3;
  }
  MenuType type = 7 [(buf.validate.field).enum.defined_only = true];
}
```

## Pagination

### List Request

```protobuf
message ListRequest {
  int32 page = 1 [(buf.validate.field).int32.gte = 1];

  int32 page_size = 2 [(buf.validate.field).int32 = { gte: 1, lte: 100 }];

  string keyword = 3 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.max_len = 100
  ];

  string order_by = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string = { in: ["created_at", "updated_at", "name", "id"] }
  ];

  bool desc = 5;
}
```

### List with Filters

```protobuf
message ListUsersRequest {
  int32 page = 1 [(buf.validate.field).int32.gte = 1];
  int32 page_size = 2 [(buf.validate.field).int32 = { gte: 1, lte: 100 }];

  string keyword = 3 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.max_len = 50
  ];

  enum Status {
    STATUS_UNSPECIFIED = 0;
    STATUS_ACTIVE = 1;
    STATUS_INACTIVE = 2;
  }
  Status status = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).enum.defined_only = true
  ];

  int64 role_id = 5 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).int64.gt = 0
  ];

  string start_date = 6 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.date = true
  ];

  string end_date = 7 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.date = true
  ];
}
```

## File Operations

### Upload Avatar

```protobuf
message UploadAvatarRequest {
  bytes content = 1 [(buf.validate.field).bytes = {
    min_len: 1,
    max_len: 5242880  // 5MB max
  }];

  string filename = 2 [(buf.validate.field).string = {
    min_len: 1,
    max_len: 255
  }];

  string content_type = 3 [(buf.validate.field).string = {
    in: ["image/jpeg", "image/png", "image/gif", "image/webp"]
  }];
}
```

## Date/Time Validation

### Date Range

```protobuf
message DateRangeRequest {
  option (buf.validate.message).cel = {
    id: "date_range_valid",
    message: "结束日期必须大于等于开始日期",
    expression: "!has(this.start_date) || !has(this.end_date) || this.end_date >= this.start_date"
  };

  int64 start_date = 1 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).int64.gt = 0
  ];

  int64 end_date = 2 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).int64.gt = 0
  ];
}
```

## Batch Operations

### Batch Delete

```protobuf
message BatchDeleteRequest {
  repeated int64 ids = 1 [(buf.validate.field).repeated = {
    min_items: 1,
    max_items: 100,
    unique: true,
    items: {
      int64: { gt: 0 }
    }
  }];
}
```

### Batch Update Status

```protobuf
message BatchUpdateStatusRequest {
  repeated int64 ids = 1 [(buf.validate.field).repeated = {
    min_items: 1,
    max_items: 100,
    unique: true,
    items: {
      int64: { gt: 0 }
    }
  }];

  enum Status {
    STATUS_UNSPECIFIED = 0;
    STATUS_ACTIVE = 1;
    STATUS_INACTIVE = 2;
  }
  Status status = 2 [(buf.validate.field).enum = {
    defined_only: true,
    in: [1, 2]  // Can't set to UNSPECIFIED
  }];
}
```

## ID Validation Patterns

### Single ID

```protobuf
message GetRequest {
  int64 id = 1 [(buf.validate.field).int64.gt = 0];
}

message DeleteRequest {
  int64 id = 1 [(buf.validate.field).int64.gt = 0];
}
```

### Optional ID

```protobuf
message QueryRequest {
  int64 category_id = 1 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).int64.gt = 0
  ];
}
```

## Common Regex Patterns

### Username (Alphanumeric + Underscore)

```protobuf
expression: "this.matches('^[a-zA-Z0-9_]{3,32}$')"
```

### Chinese Mobile Phone

```protobuf
expression: "this.matches('^1[3-9][0-9]{9}$')"
```

### Chinese ID Card (18-digit)

```protobuf
expression: "this.matches('^[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]$')"
```

### Email (Simple)

```protobuf
// Use built-in
string email = 1 [(buf.validate.field).string.email = true];

// Or custom
expression: "this.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+[.][a-zA-Z]{2,}$')"
```

### URL

```protobuf
// Use built-in
string url = 1 [(buf.validate.field).string.uri = true];

// Or HTTPS only
expression: "this.matches('^https://[a-zA-Z0-9.-]+[.][a-zA-Z]{2,}(/.*)?$')"
```

### UUID

```protobuf
// Use built-in
string id = 1 [(buf.validate.field).string.uuid = true];

// Or custom format
expression: "this.matches('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')"
```

### IPv4

```protobuf
expression: "this.matches('^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)[.]){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')"
```

### Password (Alphanumeric + Special)

```protobuf
// At least 8 chars, must include letter and number
expression: "this.matches('^(?=.*[a-zA-Z])(?=.*[0-9]).{8,32}$')"

// Strong: letter + number + special char
expression: "this.matches('^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*]).{8,32}$')"
```

### Hex Color

```protobuf
expression: "this.matches('^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$')"
```

### Slug/URL Path

```protobuf
expression: "this.matches('^[a-z0-9]+(?:-[a-z0-9]+)*$')"
```
