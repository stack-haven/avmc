# Complex Type Validation Rules

Complete reference for `RepeatedRules`, `MapRules`, `EnumRules`, `BytesRules`, `BoolRules`, `AnyRules`, `DurationRules`, and `TimestampRules`.

## Repeated Rules (Arrays/Lists)

### `min_items` / `max_items` - Array Length

```protobuf
// At least 1 item
repeated string tags = 1 [(buf.validate.field).repeated.min_items = 1];

// At most 10 items
repeated int32 scores = 2 [(buf.validate.field).repeated.max_items = 10];

// Exactly 3 items
repeated string choices = 3 [(buf.validate.field).repeated = { min_items: 3, max_items: 3 }];
```

### `unique` - No Duplicates

```protobuf
// All items must be unique
repeated string categories = 1 [(buf.validate.field).repeated.unique = true];
```

### `items` - Validate Each Item

```protobuf
// Each item must be valid
repeated string emails = 1 [(buf.validate.field).repeated = {
  items: {
    string: {
      email: true
    }
  }
}];

// Each item must be positive
repeated int64 ids = 2 [(buf.validate.field).repeated = {
  items: {
    int64: {
      gt: 0
    }
  }
}];
```

### Combined Example

```protobuf
message BatchRequest {
  repeated int64 user_ids = 1 [(buf.validate.field).repeated = {
    min_items: 1,
    max_items: 100,
    unique: true,
    items: {
      int64: { gt: 0 }
    }
  }];
}
```

## Map Rules

### `min_pairs` / `max_pairs` - Map Size

```protobuf
// At least 1 entry
map<string, string> metadata = 1 [(buf.validate.field).map.min_pairs = 1];

// At most 10 entries
map<string, int32> scores = 2 [(buf.validate.field).map = { min_pairs: 1, max_pairs: 10 }];
```

### `keys` - Validate Keys

```protobuf
// Keys must be lowercase alphanumeric
map<string, string> labels = 1 [(buf.validate.field).map = {
  keys: {
    string: {
      pattern: "^[a-z0-9_]+$"
    }
  }
}];
```

### `values` - Validate Values

```protobuf
// Values must be valid email
map<string, string> user_emails = 1 [(buf.validate.field).map = {
  values: {
    string: {
      email: true
    }
  }
}];
```

### Combined Example

```protobuf
message Config {
  map<string, string> env_vars = 1 [(buf.validate.field).map = {
    min_pairs: 1,
    max_pairs: 50,
    keys: {
      string: {
        pattern: "^[A-Z][A-Z0-9_]*$",
        max_len: 32
      }
    },
    values: {
      string: {
        max_len: 256
      }
    }
  }];
}
```

## Enum Rules

### `defined_only` - Only Defined Values

```protobuf
enum Status {
  STATUS_UNSPECIFIED = 0;
  STATUS_ACTIVE = 1;
  STATUS_INACTIVE = 2;
}

message Item {
  Status status = 1 [(buf.validate.field).enum.defined_only = true];
}
```

### `in` / `not_in` - Specific Values

```protobuf
enum Role {
  ROLE_UNSPECIFIED = 0;
  ROLE_ADMIN = 1;
  ROLE_USER = 2;
  ROLE_GUEST = 3;
}

message Request {
  // Must be ADMIN or USER (not GUEST)
  Role role = 1 [(buf.validate.field).enum = { in: [1, 2] }];
}
```

### `const` - Fixed Value

```protobuf
message AdminOnly {
  Role role = 1 [(buf.validate.field).enum.const = 1];  // Must be ADMIN
}
```

## Bytes Rules

### `min_len` / `max_len` / `len` - Byte Length

```protobuf
// Exactly 32 bytes
bytes hash = 1 [(buf.validate.field).bytes.len = 32];

// 16-64 bytes
bytes data = 2 [(buf.validate.field).bytes = { min_len: 16, max_len: 64 }];
```

### `pattern` - Regex Pattern

```protobuf
// Must match pattern (binary data as string)
bytes content = 1 [(buf.validate.field).bytes.pattern = "^[a-zA-Z0-9]+$"];
```

### `prefix` / `suffix` / `contains`

```protobuf
// Must start with magic bytes
bytes file = 1 [(buf.validate.field).bytes.prefix = "\x89PNG"];

// Must contain specific bytes
bytes data = 2 [(buf.validate.field).bytes.contains = "HEADER"];
```

### `in` / `not_in` / `const`

```protobuf
// Must be one of specific values
bytes magic = 1 [(buf.validate.field).bytes = { in: ["\x89PNG", "GIF8", "\xFF\xD8\xFF"] }];
```

### `ip / `ipv4` / `ipv6` - IP Address Bytes

```protobuf
// IPv4 address (4 bytes)
bytes ipv4 = 1 [(buf.validate.field).bytes.ipv4 = true];

// IPv6 address (16 bytes)
bytes ipv6 = 2 [(buf.validate.field).bytes.ipv6 = true];
```

## Bool Rules

### `const` - Fixed Value

```protobuf
// Must be true
bool accepted = 1 [(buf.validate.field).bool.const = true];

// Must be false
bool deleted = 2 [(buf.validate.field).bool.const = false];
```

## Any Rules (google.protobuf.Any)

### `required` - Must Be Set

```protobuf
import "google/protobuf/any.proto";

message Request {
  google.protobuf.Any payload = 1 [(buf.validate.field).any.required = true];
}
```

### `in` - Allowed Type URLs

```protobuf
message Request {
  google.protobuf.Any payload = 1 [(buf.validate.field).any = {
    in: ["type.googleapis.com/my.package.Message1", "type.googleapis.com/my.package.Message2"]
  }];
}
```

## Duration Rules (google.protobuf.Duration)

### Comparison

```protobuf
import "google/protobuf/duration.proto";

message Request {
  // Must be greater than 0
  google.protobuf.Duration timeout = 1 [(buf.validate.field).duration.gt = { seconds: 0 }];

  // Must be less than 1 hour
  google.protobuf.Duration max_duration = 2 [(buf.validate.field).duration.lt = { seconds: 3600 }];

  // Range: 1s to 5m
  google.protobuf.Duration interval = 3 [(buf.validate.field).duration = {
    gte: { seconds: 1 },
    lte: { seconds: 300 }
  }];
}
```

### `const` / `in` / `not_in`

```protobuf
// Fixed duration
google.protobuf.Duration fixed = 1 [(buf.validate.field).duration.const = { seconds: 30 }];

// Must be one of
google.protobuf.Duration allowed = 2 [(buf.validate.field).duration = {
  in: [{ seconds: 10 }, { seconds: 30 }, { seconds: 60 }]
}];
```

## Timestamp Rules (google.protobuf.Timestamp)

### Comparison

```protobuf
import "google/protobuf/timestamp.proto";

message Event {
  // Must be in the future
  google.protobuf.Timestamp start_time = 1 [(buf.validate.field).timestamp.gt_now = true];

  // Must be in the past
  google.protobuf.Timestamp end_time = 2 [(buf.validate.field).timestamp.lt_now = true];

  // Within a range
  google.protobuf.Timestamp event_time = 3 [(buf.validate.field).timestamp = {
    gte: { seconds: 1577836800 },  // 2020-01-01
    lte: { seconds: 1893456000 }   // 2030-01-01
  }];
}
```

### `gt_now` / `lt_now` / `within`

```protobuf
// Within next 24 hours
google.protobuf.Timestamp deadline = 1 [(buf.validate.field).timestamp = {
  gt_now: true,
  within: { seconds: 86400 }
}];
```

## Field Mask Rules (google.protobuf.FieldMask)

### `min_paths` / `max_paths`

```protobuf
import "google/protobuf/field_mask.proto";

message Request {
  // At least 1 path, at most 10
  google.protobuf.FieldMask update_mask = 1 [(buf.validate.field).field_mask = {
    min_paths: 1,
    max_paths: 10
  }];
}
```

## Examples

### File Upload Request

```protobuf
message UploadRequest {
  string filename = 1 [(buf.validate.field).string = {
    min_len: 1,
    max_len: 255
  }];

  bytes content = 2 [(buf.validate.field).bytes = {
    min_len: 1,
    max_bytes: 10485760  // 10MB max
  }];

  string content_type = 3 [(buf.validate.field).string = {
    in: ["image/jpeg", "image/png", "application/pdf"]
  }];
}
```

### Batch Operation

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

### Configuration Map

```protobuf
message AppConfig {
  map<string, string> settings = 1 [(buf.validate.field).map = {
    min_pairs: 0,
    max_pairs: 100,
    keys: {
      string: {
        pattern: "^[a-zA-Z][a-zA-Z0-9_.]*$",
        max_len: 64
      }
    },
    values: {
      string: {
        max_bytes: 4096
      }
    }
  }];
}
```
