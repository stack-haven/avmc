# Numeric Validation Rules

Complete reference for numeric types in protovalidate: `Int32Rules`, `Int64Rules`, `UInt32Rules`, `UInt64Rules`, `SInt32Rules`, `SInt64Rules`, `Fixed32Rules`, `Fixed64Rules`, `SFixed32Rules`, `SFixed64Rules`, `FloatRules`, `DoubleRules`.

## Common Rules (All Numeric Types)

### `const` - Exact Value

```protobuf
// Must equal 42
int32 magic_number = 1 [(buf.validate.field).int32.const = 42];

// Must equal 1.0
float version = 2 [(buf.validate.field).float.const = 1.0];
```

### `lt` - Less Than (Exclusive)

```protobuf
// Must be less than 100
int32 priority = 1 [(buf.validate.field).int32.lt = 100];

// Must be less than 1.0
float ratio = 2 [(buf.validate.field).float.lt = 1.0];
```

### `lte` - Less Than or Equal

```protobuf
// Maximum 100
int32 count = 1 [(buf.validate.field).int32.lte = 100];
```

### `gt` - Greater Than (Exclusive)

```protobuf
// Must be greater than 0
int64 id = 1 [(buf.validate.field).int64.gt = 0];

// Must be positive
double price = 2 [(buf.validate.field).double.gt = 0.0];
```

### `gte` - Greater Than or Equal

```protobuf
// Minimum 1
int32 quantity = 1 [(buf.validate.field).int32.gte = 1];
```

### Range Combinations

When combining `gt`/`gte` with `lt`/`lte`, you get range validation:

```protobuf
// Exclusive range: 0 < value < 100
int32 percentage = 1 [(buf.validate.field).int32 = { gt: 0, lt: 100 }];

// Inclusive range: 1 <= value <= 100
int32 score = 2 [(buf.validate.field).int32 = { gte: 1, lte: 100 }];

// Float range: 0.0 <= value < 1.0
float probability = 3 [(buf.validate.field).float = { gte: 0.0, lt: 1.0 }];
```

### Inverted Range

When `gt` > `lt`, the range is inverted (value must be outside the range):

```protobuf
// value < 10 OR value > 20
int32 exclusive_zone = 1 [(buf.validate.field).int32 = { gt: 20, lt: 10 }];
```

### `in` - Must Be One Of

```protobuf
// Must be 1, 2, or 3
int32 status = 1 [(buf.validate.field).int32 = { in: [1, 2, 3] }];

// Multiple values
int64 code = 2 [(buf.validate.field).int64 = { in: [100, 200, 300, 400] }];
```

### `not_in` - Must Not Be One Of

```protobuf
// Cannot be 0 or -1
int32 value = 1 [(buf.validate.field).int32 = { not_in: [0, -1] }];
```

## Float/Double Specific Rules

### `finite` - Must Be Finite

Rejects `NaN` and `Infinity`.

```protobuf
// Must be a finite number
float value = 1 [(buf.validate.field).float.finite = true];
double ratio = 2 [(buf.validate.field).double.finite = true];
```

## Signed Integer Rules (Int32, Int64, SInt32, SInt64, SFixed32, SFixed64)

All signed integer types support the same rules:

```protobuf
message SignedIntExamples {
  // Int32 examples
  int32 count = 1 [(buf.validate.field).int32.gte = 0];
  int64 id = 2 [(buf.validate.field).int64.gt = 0];
  sint32 delta = 3 [(buf.validate.field).sint32 = { gte: -100, lte: 100 }];
  sfixed64 timestamp = 4 [(buf.validate.field).sfixed64.gt = 0];
}
```

## Unsigned Integer Rules (UInt32, UInt64, Fixed32, Fixed64)

Unsigned types only accept non-negative values:

```protobuf
message UnsignedIntExamples {
  // Must be >= 0 (implicit for unsigned)
  uint32 count = 1 [(buf.validate.field).uint32.gt = 0];  // > 0
  uint64 id = 2 [(buf.validate.field).uint64.gte = 1];    // >= 1
  fixed32 hash = 3 [(buf.validate.field).fixed32.lte = 100];
}
```

## Examples by Use Case

### ID Fields

```protobuf
// Database ID: positive integer
int64 id = 1 [(buf.validate.field).int64.gt = 0];

// Optional ID: 0 means not set
int64 optional_id = 2 [
  (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
  (buf.validate.field).int64.gt = 0
];
```

### Age

```protobuf
// Human age: 0-150
int32 age = 1 [(buf.validate.field).int32 = { gte: 0, lte: 150 }];
```

### Percentage

```protobuf
// 0-100 inclusive
int32 percentage = 1 [(buf.validate.field).int32 = { gte: 0, lte: 100 }];

// 0.0-1.0 for decimal percentage
float ratio = 2 [(buf.validate.field).float = { gte: 0.0, lte: 1.0 }];
```

### Price/Money

```protobuf
// Positive price with 2 decimal places max
double price = 1 [(buf.validate.field).double = { gt: 0.0, lte: 999999.99 }];
```

### Priority/Level

```protobuf
// Priority 1-5
int32 priority = 1 [(buf.validate.field).int32 = { gte: 1, lte: 5 }];

// Level from enum values
int32 level = 2 [(buf.validate.field).int32 = { in: [1, 2, 3, 4, 5] }];
```

### Timestamp

```protobuf
// Unix timestamp, must be after 2020-01-01
int64 created_at = 1 [(buf.validate.field).int64.gte = 1577836800];
```

### Quantity

```protobuf
// Positive quantity
int32 quantity = 1 [(buf.validate.field).int32.gt = 0];

// Quantity with max
int32 max_100 = 2 [(buf.validate.field).int32 = { gt: 0, lte: 100 }];
```

### Page Number/Size

```protobuf
message Pagination {
  // Page number starts from 1
  int32 page = 1 [(buf.validate.field).int32.gte = 1];

  // Page size: 1-100
  int32 page_size = 2 [(buf.validate.field).int32 = { gte: 1, lte: 100 }];
}
```

### Score/Rating

```protobuf
// 5-star rating
int32 rating = 1 [(buf.validate.field).int32 = { gte: 1, lte: 5 }];

// Score out of 100
int32 score = 2 [(buf.validate.field).int32 = { gte: 0, lte: 100 }];
```

## Quick Reference Table

| Rule | Int32/64 | UInt32/64 | Float/Double | Description |
|------|----------|-----------|--------------|-------------|
| `const` | ✅ | ✅ | ✅ | Must equal exactly |
| `lt` | ✅ | ✅ | ✅ | Less than |
| `lte` | ✅ | ✅ | ✅ | Less than or equal |
| `gt` | ✅ | ✅ | ✅ | Greater than |
| `gte` | ✅ | ✅ | ✅ | Greater than or equal |
| `in` | ✅ | ✅ | ✅ | Must be in list |
| `not_in` | ✅ | ✅ | ✅ | Must not be in list |
| `finite` | ❌ | ❌ | ✅ | Not NaN or Inf |
