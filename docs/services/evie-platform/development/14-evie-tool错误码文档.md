# evie/tool 错误码文档

> 服务：`evie/tool`（独立轻量语音识别增强工具）
> gRPC 状态码映射：`proto/evie/tool/v1/error_reason.proto`
> 适用版本：M0–M9（v0.1.0+）

---

## 一、错误码设计原则

| 原则 | 说明 |
|------|------|
| **薄映射** | gRPC code ↔ 业务 reason 一对一；reason 不重叠 |
| **HTTP 状态码自动派生** | Kratos gateway 按 gRPC code 自动转 401/403/404/500 等 |
| **可观测** | 每个错误携带 reason + details（结构化） |
| **本地化** | reason 常量在 proto；message 由 service 层注入（中文） |

---

## 二、错误码清单

### 通用错误（所有 service 共享）

| Reason | gRPC Code | HTTP | 含义 | 触发场景 |
|--------|-----------|------|------|----------|
| `UNAUTHENTICATED` | `Unauthenticated` (16) | 401 | 缺 / 失效 Bearer token | 无 `Authorization: Bearer` 头 / token 不在 Redis |
| `PERMISSION_DENIED` | `PermissionDenied` (7) | 403 | 权限不足 | （预留，M10 接入） |
| `INVALID_ARGUMENT` | `InvalidArgument` (3) | 400 | 请求参数无效 | 字段为空 / 范围越界 |
| `NOT_FOUND` | `NotFound` (5) | 404 | 资源不存在 | record_id 不存在 |
| `INTERNAL` | `Internal` (13) | 500 | 内部错误 | 数据库 / Redis 崩溃 |
| `DEADLINE_EXCEEDED` | `DeadlineExceeded` (4) | 504 | 超时 | 流式识别客户端断流超过 30s |
| `UNAVAILABLE` | `Unavailable` (14) | 503 | 依赖不可用 | qua / Redis / ASR provider 全挂 |

### ASR 服务特有

| Reason | gRPC Code | HTTP | 含义 | 触发场景 |
|--------|-----------|------|------|----------|
| `ASR_PROVIDER_NOT_FOUND` | `Failed` | 500 | provider 未注册 | conf.Asr.providers.<name>.enabled = false |
| `ASR_RECOGNIZE_FAILED` | `Failed` | 500 | 识别引擎返回错误 | funasr / xunfei 返回 4xx/5xx |
| `ASR_AUDIO_INVALID` | `InvalidArgument` | 400 | 音频数据无效 | audioData 为空 / 非 WAV 非 MP3 |
| `ASR_SESSION_CONFLICT` | `Aborted` | 409 | session_id 冲突 | （M10 阶段实现） |
| `ASR_STREAM_INTERRUPTED` | `Canceled` | 499 | 流被客户端中断 | client ctx 取消 |

### Enhancement 服务特有

| Reason | gRPC Code | HTTP | 含义 | 触发场景 |
|--------|-----------|------|------|----------|
| `TEXT_EMPTY` | `InvalidArgument` | 400 | 待增强文本为空 | raw_text = "" |
| `TEXT_TOO_LONG` | `InvalidArgument` | 400 | 文本超长（>5000 字） | 输入超 5000 字符 |
| `ENHANCEMENT_FAILED` | `Internal` | 500 | Pipeline 全部失败 | 9 层 processor 全 error |
| `VOCAB_NOT_LOADED` | `Unavailable` | 503 | 租户词库未加载 | tenant_id 不在 TenantRegistry |

---

## 三、降级语义

某些错误**不视为失败**，仅在响应中标记状态：

| Status | 含义 | HTTP | 调用方行为 |
|--------|------|------|----------|
| `SUCCESS` (1) | 正常增强成功 | 200 | 直接展示 enhanced_text |
| `DEGRADED` (2) | 增强失败，保留原文 | 200 | 展示 raw_text，warn 日志告警 |
| `NOOP` (3) | 无需增强 | 200 | 展示 raw_text |

> **关键**：DEGRADED 状态**仍返回 HTTP 200**，仅在 body 中通过 `status` 字段标记。

---

## 四、客户端处理建议

### 1. HTTP 调用

```go
resp, err := http.Post(url, ...)
if err != nil {
    // 网络层错误
}
if resp.StatusCode == 401 {
    // 重新登录拿新 token
}
if resp.StatusCode >= 500 {
    // 服务端错误，记录日志 + 报警
}
if resp.StatusCode == 200 {
    // 业务可能成功（status=1）或降级（status=2），看 body.status
}
```

### 2. gRPC 调用

```go
resp, err := client.Recognize(ctx, req)
if err != nil {
    st, _ := status.FromError(err)
    switch st.Code() {
    case codes.Unauthenticated:
        // 重新登录
    case codes.FailedPrecondition:
        // 检查 reason + message
    }
}
```

---

## 五、监控建议

| 错误 | 报警阈值 | 备注 |
|------|----------|------|
| `UNAUTHENTICATED` | > 100/分钟 | 可能是 token 失效或攻击 |
| `ASR_PROVIDER_NOT_FOUND` | > 0/小时 | 配置错误，必须修复 |
| `ASR_RECOGNIZE_FAILED` | > 5% 成功率 | provider 故障 |
| `VOCAB_NOT_LOADED` | > 10/小时 | 词库同步失败 |
| `ENHANCEMENT_FAILED` | > 1% 比例 | Pipeline 异常 |

---

## 六、相关文档

- proto：`backend-service/proto/evie/tool/v1/error_reason.proto`
- 实现：`backend-service/app/evie/tool/internal/server/errors.go`
- 业务映射：`pkg/health/health.go`（健康检查）

---

**变更记录**

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-09 | 0.1.0 | M9 收口：建立错误码框架 |