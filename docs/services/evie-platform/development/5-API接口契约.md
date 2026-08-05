# Evie — API 接口契约

日期：2026-08-04
状态：草案
依赖：[0-架构总览](./0-架构总览-语音智能引擎.md)

---

## 一、Proto 模块布局

```
backend-service/proto/evie/service/v1/
├── asr.proto              # ASR 识别
├── correction.proto       # 纠错
├── dictionary.proto       # 字典管理
├── entity.proto           # 实体识别
├── hotword.proto          # 热词管理
├── common.proto           # 公共 message
├── error_reason.proto     # 错误码
└── buf.openapi.gen.yaml   # OpenAPI 生成配置
```

---

## 二、公共消息定义

```protobuf
// proto/evie/service/v1/common.proto
syntax = "proto3";
package evie.service.v1;

import "buf/validate/validate.proto";

// 分页
message Pagination {
  int32 page = 1 [(buf.validate.field).int32 = { gte: 1 }];
  int32 page_size = 2 [(buf.validate.field).int32 = { gte: 1, lte: 100 }];
}

message PageInfo {
  int32 page = 1;
  int32 page_size = 2;
  int32 total = 3;
}

// 实体类型
enum EntityType {
  ENTITY_TYPE_UNSPECIFIED = 0;
  ENTITY_TYPE_PERSON = 1;
  ENTITY_TYPE_ORGANIZATION = 2;
  ENTITY_TYPE_PRODUCT = 3;
  ENTITY_TYPE_TERM = 4;
  ENTITY_TYPE_TIME = 5;
  ENTITY_TYPE_QUANTITY = 6;
}

// 字典来源
enum DictSource {
  DICT_SOURCE_UNSPECIFIED = 0;
  DICT_SOURCE_PLATFORM = 1;  // 平台公共
  DICT_SOURCE_SYSTEM = 2;    // 系统业务
  DICT_SOURCE_TENANT = 3;    // 企业租户
  DICT_SOURCE_USER = 4;      // 个人用户
}
```

---

## 三、ASR 识别接口

```protobuf
// proto/evie/service/v1/asr.proto
syntax = "proto3";
package evie.service.v1;

import "buf/validate/validate.proto";
import "evie/service/v1/common.proto";

// ====== Service ======
service ASRService {
  // 同步识别（短音频 ≤60s）
  rpc Recognize(RecognizeRequest) returns (RecognizeResponse);

  // 流式识别（长音频 / 实时）
  rpc StreamRecognize(stream AudioChunk) returns (stream StreamResult);
}

// ====== Request ======
message RecognizeRequest {
  string session_id = 1;
  AudioFormat format = 2 [(buf.validate.field).required = true];
  bytes audio_data = 3 [(buf.validate.field).bytes.max_len = 10485760]; // max 10MB
}

message AudioFormat {
  AudioEncoding encoding = 1;
  int32 sample_rate = 2;
  int32 bit_depth = 3;
  int32 channels = 4;
}

enum AudioEncoding {
  AUDIO_ENCODING_UNSPECIFIED = 0;
  AUDIO_ENCODING_PCM = 1;
  AUDIO_ENCODING_WAV = 2;
  AUDIO_ENCODING_MP3 = 3;
  AUDIO_ENCODING_OPUS = 4;
}

message AudioChunk {
  string session_id = 1;
  bytes data = 2;
  int64 timestamp_ms = 3;
}

// ====== Response ======
message RecognizeResponse {
  string request_id = 1;
  string text = 2;
  repeated Segment segments = 3;
  float confidence = 4;
  int64 duration_ms = 5;
  bool is_final = 6;         // 流式场景：是否为最终结果
}

message Segment {
  int64 start_ms = 1;
  int64 end_ms = 2;
  string text = 3;
  float confidence = 4;
}

message StreamResult {
  string request_id = 1;
  string text = 2;           // 增量文本
  float confidence = 3;
  bool is_final = 4;         // 是否为最终结果
  int64 timestamp_ms = 5;
}
```

---

## 四、纠错接口

```protobuf
// proto/evie/service/v1/correction.proto
syntax = "proto3";
package evie.service.v1;

import "buf/validate/validate.proto";
import "google/api/annotations.proto";

service CorrectionService {
  // 文本纠错
  rpc Correct(CorrectRequest) returns (CorrectResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/correction/correct"
      body: "*"
    };
  }

  // 提交纠错反馈
  rpc SubmitFeedback(SubmitFeedbackRequest) returns (SubmitFeedbackResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/correction/feedback"
      body: "*"
    };
  }

  // 确认建议（低置信度场景）
  rpc ConfirmSuggestion(ConfirmSuggestionRequest) returns (ConfirmSuggestionResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/correction/confirm"
      body: "*"
    };
  }
}

message CorrectRequest {
  string text = 1 [(buf.validate.field).string.min_len = 1];
  string session_id = 2;
  string context = 3;              // 前后文，可选
}

message CorrectResponse {
  string original_text = 1;
  string corrected_text = 2;
  repeated CorrectionChange changes = 3;
  float confidence = 4;
  bool need_confirm = 5;           // 是否需要用户确认
}

message CorrectionChange {
  string from = 1;
  string to = 2;
  string type = 3;                 // person/org/product/dictionary
  float confidence = 4;
}

message SubmitFeedbackRequest {
  string session_id = 1;
  string input = 2;                // 用户原始说法
  string system_guess = 3;         // 系统猜测
  string user_choice = 4;          // 用户实际选择
  bool correct = 5;                // 系统是否正确
}

message SubmitFeedbackResponse {
  bool success = 1;
}

message ConfirmSuggestionRequest {
  string session_id = 1;
  string suggestion_id = 2;
  bool accepted = 3;
}

message ConfirmSuggestionResponse {
  string final_text = 1;
}
```

---

## 五、字典管理接口

```protobuf
// proto/evie/service/v1/dictionary.proto
syntax = "proto3";
package evie.service.v1;

import "buf/validate/validate.proto";
import "google/api/annotations.proto";
import "evie/service/v1/common.proto";

service DictionaryService {
  // ====== 标准词 CRUD ======
  rpc CreateWord(CreateWordRequest) returns (CreateWordResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/dictionary/words"
      body: "*"
    };
  }

  rpc UpdateWord(UpdateWordRequest) returns (UpdateWordResponse) {
    option (google.api.http) = {
      put: "/api/v1/evie/dictionary/words/{word_id}"
      body: "*"
    };
  }

  rpc DeleteWord(DeleteWordRequest) returns (DeleteWordResponse) {
    option (google.api.http) = {
      delete: "/api/v1/evie/dictionary/words/{word_id}"
    };
  }

  rpc ListWords(ListWordsRequest) returns (ListWordsResponse) {
    option (google.api.http) = {
      get: "/api/v1/evie/dictionary/words"
    };
  }

  rpc GetWord(GetWordRequest) returns (GetWordResponse) {
    option (google.api.http) = {
      get: "/api/v1/evie/dictionary/words/{word_id}"
    };
  }

  // ====== 别名管理 ======
  rpc AddAlias(AddAliasRequest) returns (AddAliasResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/dictionary/words/{word_id}/aliases"
      body: "*"
    };
  }

  rpc RemoveAlias(RemoveAliasRequest) returns (RemoveAliasResponse) {
    option (google.api.http) = {
      delete: "/api/v1/evie/dictionary/words/{word_id}/aliases/{alias_id}"
    };
  }

  // ====== 批量操作 ======
  rpc BatchImportWords(BatchImportWordsRequest) returns (BatchImportWordsResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/dictionary/words:batchImport"
      body: "*"
    };
  }

  rpc SyncFromOrganization(SyncFromOrganizationRequest) returns (SyncFromOrganizationResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/dictionary:sync"
      body: "*"
    };
  }
}

// ====== 标准词 ======
message DictionaryWord {
  int64 id = 1;
  string word = 2;
  string type = 3;               // platform/system/tenant/user
  string category = 4;           // person/org/product/term
  int32 status = 5;              // 1=启用 0=停用
  int32 priority = 6;
  repeated DictionaryAlias aliases = 7;
  string created_at = 8;
}

message DictionaryAlias {
  int64 id = 1;
  string alias = 2;
  string pinyin = 3;
  float weight = 4;
  string source = 5;
}

message CreateWordRequest {
  string word = 1 [(buf.validate.field).string = { min_len: 1, max_len: 128 }];
  string category = 2 [(buf.validate.field).string = { in: ["person", "org", "product", "term"] }];
  repeated string aliases = 3;
  bool auto_generate_alias = 4;
}

message CreateWordResponse {
  DictionaryWord word = 1;
}

message UpdateWordRequest {
  int64 word_id = 1;
  string word = 2;
  string category = 3;
  int32 status = 4;
}

message UpdateWordResponse {
  DictionaryWord word = 1;
}

message DeleteWordRequest {
  int64 word_id = 1;
}

message DeleteWordResponse {}

message ListWordsRequest {
  Pagination pagination = 1;
  string category = 2;            // 筛选
  string keyword = 3;             // 搜索关键词
  int32 status = 4;               // 筛选状态
}

message ListWordsResponse {
  repeated DictionaryWord words = 1;
  PageInfo page_info = 2;
}

message GetWordRequest {
  int64 word_id = 1;
}

message GetWordResponse {
  DictionaryWord word = 1;
}

message AddAliasRequest {
  int64 word_id = 1;
  string alias = 2 [(buf.validate.field).string = { min_len: 1, max_len: 128 }];
  float weight = 3;
}

message AddAliasResponse {
  DictionaryAlias alias = 1;
}

message RemoveAliasRequest {
  int64 word_id = 1;
  int64 alias_id = 2;
}

message RemoveAliasResponse {}

message BatchImportWordsRequest {
  repeated CreateWordRequest words = 1 [(buf.validate.field).repeated = { min_items: 1, max_items: 1000 }];
}

message BatchImportWordsResponse {
  int32 success_count = 1;
  int32 fail_count = 2;
  repeated string errors = 3;
}

message SyncFromOrganizationRequest {}

message SyncFromOrganizationResponse {
  int32 new_words = 1;
  int32 updated_words = 2;
  int32 deleted_words = 3;
}
```

---

## 六、实体识别接口

```protobuf
// proto/evie/service/v1/entity.proto
syntax = "proto3";
package evie.service.v1;

import "google/api/annotations.proto";
import "evie/service/v1/common.proto";

service EntityService {
  // 从文本中提取实体
  rpc Extract(ExtractEntitiesRequest) returns (ExtractEntitiesResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/entity/extract"
      body: "*"
    };
  }
}

message ExtractEntitiesRequest {
  string text = 1;
  repeated EntityType types = 2;   // 限定实体类型，空=全部
}

message ExtractEntitiesResponse {
  string text = 1;                 // 原文
  repeated Entity entities = 2;
}

message Entity {
  string text = 1;                 // 实体文本
  EntityType type = 2;
  string normalized = 3;           // 标准化后（如"小田"→"田华"）
  int32 start_offset = 4;          // 在原文中的偏移
  int32 end_offset = 5;
  float confidence = 6;
}
```

---

## 七、热词管理接口

```protobuf
// proto/evie/service/v1/hotword.proto
syntax = "proto3";
package evie.service.v1;

import "buf/validate/validate.proto";
import "google/api/annotations.proto";

service HotwordService {
  rpc ListHotwords(ListHotwordsRequest) returns (ListHotwordsResponse) {
    option (google.api.http) = {
      get: "/api/v1/evie/hotwords"
    };
  }

  rpc UpsertHotword(UpsertHotwordRequest) returns (UpsertHotwordResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/hotwords"
      body: "*"
    };
  }

  rpc DeleteHotword(DeleteHotwordRequest) returns (DeleteHotwordResponse) {
    option (google.api.http) = {
      delete: "/api/v1/evie/hotwords/{id}"
    };
  }

  rpc BatchSetHotwords(BatchSetHotwordsRequest) returns (BatchSetHotwordsResponse) {
    option (google.api.http) = {
      post: "/api/v1/evie/hotwords:batchSet"
      body: "*"
    };
  }
}

message Hotword {
  int64 id = 1;
  string word = 2;
  string target = 3;              // 期望识别结果，空=用 word
  float weight = 4;               // 0-10
  string category = 5;            // person/org/product/term
}

message ListHotwordsRequest {
  string category = 1;
}

message ListHotwordsResponse {
  repeated Hotword hotwords = 1;
}

message UpsertHotwordRequest {
  int64 id = 1;                   // 0=新建，>0=更新
  string word = 2 [(buf.validate.field).string = { min_len: 1, max_len: 64 }];
  string target = 3;
  float weight = 4;
  string category = 5;
}

message UpsertHotwordResponse {
  Hotword hotword = 1;
}

message DeleteHotwordRequest {
  int64 id = 1;
}

message DeleteHotwordResponse {}

message BatchSetHotwordsRequest {
  repeated UpsertHotwordRequest hotwords = 1 [(buf.validate.field).repeated = { max_items: 500 }];
}

message BatchSetHotwordsResponse {
  int32 success_count = 1;
}
```

---

## 八、权限码声明

```go
// internal/authzpolicy/permissions.go

const (
    // 字典管理
    PermDictionaryRead   = "evie.dictionary.read"
    PermDictionaryWrite  = "evie.dictionary.write"
    PermDictionaryImport = "evie.dictionary.import"

    // 热词管理
    PermHotwordRead  = "evie.hotword.read"
    PermHotwordWrite = "evie.hotword.write"

    // 纠错
    PermCorrectionExecute = "evie.correction.execute"
    PermCorrectionConfirm = "evie.correction.confirm"

    // ASR
    PermASRExecute = "evie.asr.execute"

    // 平台管理
    PermAdminCrossTenant = "evie.admin.cross_tenant"
)
```

---

> 下一份：[6-数据模型设计](./6-数据模型设计.md)
