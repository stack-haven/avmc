# Chinese-Specific Validation Patterns

Validation patterns for Chinese locale data: mobile phone, ID card, bank card, etc.

## Chinese Mobile Phone (手机号)

### Pattern: 11 digits starting with 1

```protobuf
string mobile = 1 [(buf.validate.field).cel = {
  id: "chinese_mobile",
  message: "手机号格式错误，必须为11位有效手机号",
  expression: "this.matches('^1[3-9][0-9]{9}$')"
}];
```

### With Optional Support

```protobuf
string mobile = 1 [
  (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
  (buf.validate.field).cel = {
    id: "chinese_mobile_optional",
    message: "手机号格式错误",
    expression: "this.matches('^1[3-9][0-9]{9}$')"
  }
];
```

## Chinese ID Card (身份证号)

### 18-Digit ID Card

```protobuf
string id_card = 1 [(buf.validate.field).cel = {
  id: "chinese_id_card_18",
  message: "身份证号格式错误",
  expression: "this.matches('^[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]$')"
}];
```

### 15 or 18 Digit (Legacy Support)

```protobuf
string id_card = 1 [(buf.validate.field).cel = {
  id: "chinese_id_card",
  message: "身份证号格式错误",
  expression: "this.matches('^[1-9][0-9]{5}(?:[0-9]{4}(?:0[1-9]|1[0-2])(?:0[1-9]|[12][0-9]|3[01])[0-9]{3}|[0-9]{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12][0-9]|3[01])[0-9]{3})[0-9Xx]?$')"
}];
```

## Chinese Bank Card (银行卡号)

### 16-19 Digit Card Number

```protobuf
string bank_card = 1 [(buf.validate.field).cel = {
  id: "chinese_bank_card",
  message: "银行卡号格式错误",
  expression: "this.matches('^[1-9][0-9]{15,18}$')"
}];
```

## Chinese Postal Code (邮编)

### 6 Digits

```protobuf
string postal_code = 1 [(buf.validate.field).cel = {
  id: "chinese_postal_code",
  message: "邮编格式错误，必须为6位数字",
  expression: "this.matches('^[1-9][0-9]{5}$')"
}];
```

## Chinese License Plate (车牌号)

### Standard Plate

```protobuf
string plate = 1 [(buf.validate.field).cel = {
  id: "chinese_license_plate",
  message: "车牌号格式错误",
  expression: "this.matches('^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-Z][A-HJ-NP-Z0-9]{4,5}[A-HJ-NP-Z0-9挂学警港澳]$')"
}];
```

### New Energy Vehicle Plate (新能源)

```protobuf
string plate = 1 [(buf.validate.field).cel = {
  id: "chinese_new_energy_plate",
  message: "新能源车牌号格式错误",
  expression: "this.matches('^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-Z][A-HJ-NP-Z0-9]{5,6}$')"
}];
```

## Chinese Name (中文姓名)

### 2-20 Chinese Characters

```protobuf
string name = 1 [(buf.validate.field).cel = {
  id: "chinese_name",
  message: "姓名格式错误，必须为2-20个中文字符",
  expression: "this.matches('^[\\u4e00-\\u9fa5]{2,20}$')"
}];
```

### Chinese or English Name

```protobuf
string name = 1 [(buf.validate.field).cel = {
  id: "mixed_name",
  message: "姓名格式错误",
  expression: "this.matches('^[\\u4e00-\\u9fa5a-zA-Z\\s]{2,32}$')"
}];
```

## Chinese Address (中文地址)

### Basic Pattern

```protobuf
string address = 1 [(buf.validate.field).cel = {
  id: "chinese_address",
  message: "地址格式错误",
  expression: "size(this) >= 5 && size(this) <= 200"
}];
```

## Social Credit Code (统一社会信用代码)

### 18-Digit Code

```protobuf
string credit_code = 1 [(buf.validate.field).cel = {
  id: "social_credit_code",
  message: "统一社会信用代码格式错误",
  expression: "this.matches('^[0-9A-HJ-NPQRTUWXY]{2}[0-9]{6}[0-9A-HJ-NPQRTUWXY]{10}$')"
}];
```

## Complete User Registration Example

```protobuf
message ChineseUserRegistration {
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
    message: "手机号格式错误，必须为11位有效手机号",
    expression: "this.matches('^1[3-9][0-9]{9}$')"
  }];

  string real_name = 5 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).cel = {
      id: "real_name_format",
      message: "真实姓名必须为2-20个中文字符",
      expression: "this.matches('^[\\u4e00-\\u9fa5]{2,20}$')"
    }
  ];

  string id_card = 6 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).cel = {
      id: "id_card_format",
      message: "身份证号格式错误",
      expression: "this.matches('^[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]$')"
    }
  ];

  string email = 7 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.email = true
  ];
}
```

## Regex Reference Table

| Field | Pattern | Description |
|-------|---------|-------------|
| 手机号 | `^1[3-9][0-9]{9}$` | 11位，1开头，第2位3-9 |
| 身份证 | `^[1-9][0-9]{5}(19\|20)[0-9]{2}(0[1-9]\|1[0-2])(0[1-9]\|[12][0-9]\|3[01])[0-9]{3}[0-9Xx]$` | 18位含校验 |
| 银行卡 | `^[1-9][0-9]{15,18}$` | 16-19位 |
| 邮编 | `^[1-9][0-9]{5}$` | 6位 |
| 中文姓名 | `^[\u4e00-\u9fa5]{2,20}$` | 2-20个汉字 |
| 车牌 | `^[京津沪渝...][A-Z][A-HJ-NP-Z0-9]{4,5}[A-HJ-NP-Z0-9挂学警港澳]$` | 省份+字母+数字 |
| 统一社会信用代码 | `^[0-9A-HJ-NPQRTUWXY]{2}[0-9]{6}[0-9A-HJ-NPQRTUWXY]{10}$` | 18位 |

## Unicode Range for Chinese

- **CJK Unified Ideographs**: `\u4e00-\u9fa5` (常用汉字)
- **CJK Extension A**: `\u3400-\u4dbf` (扩展A)
- **CJK Extension B-F**: More rare characters

For most cases, `\u4e00-\u9fa5` is sufficient.
