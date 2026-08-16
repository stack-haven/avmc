# Evie — ASR 语音识别服务

日期：2026-08-04
状态：草案
依赖：[0-架构总览-语音智能引擎](./0-架构总览-语音智能引擎.md)

---

## 一、模块定位

ASR 服务负责完成**语音→文本**的转换，是整个语音智能链路的第一层感知能力。

```
声音识别 ≠ 业务理解
```

ASR 服务输出：**高准确率、低延迟、可供后续纠错增强的原始文本**。

**设计核心原则：ASR 是"供应商"，纠错才是"核心产品"。** ASR 引擎可替换、可组合、租户可自选。

---

## 二、ASR 供应商模式

### 2.1 定位

Evie 不绑定单一 ASR 引擎。用户（租户管理员）可以从后台选择：

```
┌──────────────────────────────────────────────┐
│              ASR Provider Router             │
│                                              │
│  请求 → 查询租户配置 → 路由到目标 Provider     │
│                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────┐ ┌──────┐│
│  │ FunASR   │ │ Whisper  │ │ 讯飞  │ │阿里云││
│  │ 私有部署  │ │ 私有部署  │ │ 云API │ │ 云API││
│  └────┬─────┘ └────┬─────┘ └──┬───┘ └──┬───┘│
│       │            │          │         │     │
│       └────────────┴──────────┴─────────┘     │
│                      │                        │
│              统一 ASRResult 输出               │
└──────────────────────────────────────────────┘
```

### 2.2 处理流水线

```
音频采集 → 转码归一化 → 降噪/增益 → VAD 语音检测
                                          │
                          ┌───────────────┘
                          ▼
                   ASR Provider Router
                   查询租户配置 → 选择引擎
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
           FunASR      Whisper      讯飞/阿里云
              │           │           │
              └───────────┴───────────┘
                          │
                    热词增强（统一后处理）
                          │
                    结构化输出
```

---

## 三、Go 接口定义

### 3.1 ASR Provider 抽象（核心）

```go
// internal/biz/asr.go

// ASRProvider ASR 引擎供应商抽象
// 所有 ASR 实现（私有部署/云API）必须实现此接口
type ASRProvider interface {
    // Name 供应商标识，全局唯一
    Name() string

    // Recognize 同步识别（短音频 ≤60s）
    Recognize(ctx context.Context, audio []byte, opts RecognizeOptions) (*ASRResult, error)

    // StreamRecognize 流式识别，实时返回中间结果
    StreamRecognize(ctx context.Context, audioCh <-chan PCMChunk, resultCh chan<- ASRStreamResult, opts RecognizeOptions) error

    // Capabilities 返回该供应商的能力集
    Capabilities() ProviderCapabilities
}

// ProviderCapabilities 供应商能力声明
type ProviderCapabilities struct {
    Streaming       bool   // 支持流式识别
    MaxDurationMs   int64  // 单次最长音频时长（0=无限制）
    SupportedFormat []string // 支持的音频格式: pcm/wav/mp3/opus
    SampleRates     []int  // 支持的采样率
    HotwordSupport  bool   // 是否支持热词增强
    DeploymentMode  string // self_hosted / cloud_api
}

// RecognizeOptions 识别参数（各 Provider 各自提取需要字段）
type RecognizeOptions struct {
    TenantID   string
    Hotwords   []Hotword
    SampleRate int
    Language   string // zh/en/auto
}
```

### 3.2 Provider 实现矩阵

| Provider | Name() | 部署方式 | 热词 | 流式 | 备注 |
|----------|--------|:---:|:---:|:---:|------|
| `FunASRProvider` | `funasr` | 私有化 | ✅ | ✅ | FunASR Server gRPC |
| `WhisperProvider` | `whisper` | 私有化 | ❌ | ⚠️ | faster-whisper C++/Python 子进程 |
| `XunfeiProvider` | `xunfei` | 云 API | ✅ 自学习 | ✅ | 讯飞实时语音转写 |
| `AliyunProvider` | `aliyun` | 云 API | ✅ 自学习 | ✅ | 阿里云语音识别 |

### 3.3 Provider 注册与路由

```go
// internal/biz/provider_registry.go

// ProviderRegistry ASR 供应商注册中心
type ProviderRegistry struct {
    providers map[string]ASRProvider // name → provider
}

func (r *ProviderRegistry) Register(p ASRProvider) {
    r.providers[p.Name()] = p
}

func (r *ProviderRegistry) Get(name string) (ASRProvider, error) {
    p, ok := r.providers[name]
    if !ok {
        return nil, fmt.Errorf("unknown asr provider: %s", name)
    }
    return p, nil
}

func (r *ProviderRegistry) List() []ProviderCapabilities {
    var caps []ProviderCapabilities
    for _, p := range r.providers {
        c := p.Capabilities()
        caps = append(caps, c)
    }
    return caps
}
```

### 3.4 租户级 Provider 选择

```go
// internal/biz/provider_router.go

// ProviderRouter 根据租户配置路由到正确的 ASR Provider
type ProviderRouter struct {
    registry *ProviderRegistry
    repo     ProviderConfigRepo // 读取租户的 ASR 配置
}

func (r *ProviderRouter) Route(ctx context.Context) (ASRProvider, RecognizeOptions, error) {
    tenantID := auth.TenantIDFromContext(ctx)

    // 1. 查租户配置：选择了哪个 Provider
    config, err := r.repo.GetTenantConfig(ctx, tenantID)
    if err != nil {
        return nil, RecognizeOptions{}, fmt.Errorf("get tenant asr config: %w", err)
    }

    // 2. 获取对应的 Provider
    provider, err := r.registry.Get(config.ProviderName)
    if err != nil {
        return nil, RecognizeOptions{}, err
    }

    // 3. 组装识别参数（热词、采样率等从租户配置读取）
    opts := RecognizeOptions{
        TenantID:   tenantID,
        SampleRate: config.SampleRate,
        Language:   config.Language,
        // 热词由后续 hotword 服务填充
    }

    return provider, opts, nil
}
```

### 3.5 音频采集接口（不变）

```go
// AudioCapture 音频采集抽象
type AudioCapture interface {
    Capture(ctx context.Context, req CaptureRequest) (<-chan PCMChunk, error)
}

type CaptureRequest struct {
    TenantID  string
    UserID    string
    Mode      CaptureMode // webrtc / websocket / sdk / telephony
    Format    AudioFormat
    SessionID string
}

type CaptureMode string
const (
    CaptureWebRTC    CaptureMode = "webrtc"
    CaptureWebSocket CaptureMode = "websocket"
    CaptureSDK       CaptureMode = "sdk"
    CaptureTelephony CaptureMode = "telephony"
)

type AudioFormat struct {
    Encoding   string // pcm / wav / mp3 / opus
    SampleRate int    // 16000
    BitDepth   int    // 16
    Channels   int    // 1
}

type PCMChunk struct {
    Data        []byte
    Timestamp   int64
    VoiceActive bool
}
```

---

## 四、Biz 层编排逻辑（集成 ProviderRouter）

```go
// internal/biz/asr.go

type ASRUsecase struct {
    capture      AudioCapture
    preprocessor AudioPreprocessor
    vad          VADDetector
    router       ProviderRouter     // ← 替换原来的单一 engine
    hotword      HotwordEnhancer
    repo         ASRRepo
}

func (uc *ASRUsecase) Recognize(ctx context.Context, req CaptureRequest) (*ASRResult, error) {
    // 1. 建立音频采集
    pcmCh, err := uc.capture.Capture(ctx, req)
    if err != nil {
        return nil, fmt.Errorf("capture: %w", err)
    }

    // 2. 路由到租户选择的 ASR Provider
    provider, opts, err := uc.router.Route(ctx)
    if err != nil {
        return nil, fmt.Errorf("route asr provider: %w", err)
    }

    // 3. 加载热词（如果该 Provider 支持）
    if provider.Capabilities().HotwordSupport {
        hotwords, _ := uc.hotword.GetHotwords(ctx, req.TenantID)
        opts.Hotwords = hotwords
    }

    // 4. 流式识别
    resultCh := make(chan ASRStreamResult, 16)
    go func() {
        defer close(resultCh)
        _ = provider.StreamRecognize(ctx, pcmCh, resultCh, opts)
    }()

    // 5. 收集最终结果
    var finalResult *ASRResult
    for r := range resultCh {
        if r.IsFinal {
            // 6. 热词后处理增强（如果 Provider 不支持原生热词）
            if !provider.Capabilities().HotwordSupport {
                enhanced, _ := uc.hotword.Enhance(ctx, req.TenantID, &ASRResult{
                    Text:       r.Text,
                    Confidence: r.Confidence,
                })
                finalResult = enhanced
            } else {
                finalResult = &ASRResult{
                    Text:       r.Text,
                    Confidence: r.Confidence,
                }
            }
            break
        }
    }

    // 7. 持久化识别记录（含 provider 信息）
    _ = uc.repo.SaveRecord(ctx, ASRRecord{
        TenantID:     req.TenantID,
        UserID:       req.UserID,
        SessionID:    req.SessionID,
        RawText:      finalResult.Text,
        Confidence:   finalResult.Confidence,
        DurationMs:   finalResult.DurationMs,
        ProviderName: provider.Name(),
    })

    return finalResult, nil
}
```

---

## 五、各 Provider 实现（pkg/asr/）

Provider 客户端作为公共库抽离到 `pkg/asr/`，供所有需要语音识别的服务复用。

### 5.1 目录结构

```
pkg/asr/
├── provider.go           # ASRProvider 接口 + RecognizeOptions + ProviderCapabilities
├── funasr/
│   └── funasr.go         # FunASR gRPC 客户端
├── whisper/
│   └── whisper.go        # faster-whisper 子进程客户端
├── xunfei/
│   └── xunfei.go         # 讯飞实时语音转写 WebSocket 客户端
└── aliyun/
    └── aliyun.go         # 阿里云语音识别 HTTP/WebSocket 客户端
```

### 5.2 FunASR（私有化，gRPC）

```go
// pkg/asr/funasr/funasr.go

type FunASRProvider struct {
    client funasr.Client
    cfg    FunASRConfig
}

func (p *FunASRProvider) Name() string { return "funasr" }

func (p *FunASRProvider) Capabilities() ProviderCapabilities {
    return ProviderCapabilities{
        Streaming:       true,
        MaxDurationMs:   0,
        SupportedFormat: []string{"pcm", "wav"},
        SampleRates:     []int{8000, 16000},
        HotwordSupport:  true,
        DeploymentMode:  "self_hosted",
    }
}

func (p *FunASRProvider) Recognize(ctx context.Context, audio []byte, opts RecognizeOptions) (*ASRResult, error) {
    resp, err := p.client.Recognize(ctx, &funasr.RecognizeRequest{
        Audio:      audio,
        Hotwords:   toFunASRHotwords(opts.Hotwords), // 热词传给引擎
        SampleRate: int32(opts.SampleRate),
    })
    // ... convert to ASRResult
}
```

### 5.3 Whisper（私有化，faster-whisper 子进程）

```go
// pkg/asr/whisper/whisper.go

type WhisperProvider struct {
    modelPath string
    device    string
}

func (p *WhisperProvider) Name() string { return "whisper" }

func (p *WhisperProvider) Capabilities() ProviderCapabilities {
    return ProviderCapabilities{
        Streaming:       false, // Whisper 不支持原生流式
        MaxDurationMs:   0,
        SupportedFormat: []string{"wav", "mp3"},
        SampleRates:     []int{16000},
        HotwordSupport:  false, // 不支持，由后处理补充
        DeploymentMode:  "self_hosted",
    }
}
```

### 5.4 讯飞（云 API）

```go
// pkg/asr/xunfei/xunfei.go

type XunfeiProvider struct {
    appID     string
    apiKey    string
    apiSecret string
}

func (p *XunfeiProvider) Name() string { return "xunfei" }

func (p *XunfeiProvider) Capabilities() ProviderCapabilities {
    return ProviderCapabilities{
        Streaming:       true,
        MaxDurationMs:   3600000, // 1小时
        SupportedFormat: []string{"pcm", "wav"},
        SampleRates:     []int{8000, 16000},
        HotwordSupport:  true, // 讯飞自学习平台
        DeploymentMode:  "cloud_api",
    }
}
```

### 5.5 阿里云（云 API）

```go
// pkg/asr/aliyun/aliyun.go

func (p *AliyunProvider) Name() string { return "aliyun" }

func (p *AliyunProvider) Capabilities() ProviderCapabilities {
    return ProviderCapabilities{
        Streaming:       true,
        MaxDurationMs:   0,
        SupportedFormat: []string{"pcm", "wav", "opus"},
        SampleRates:     []int{8000, 16000},
        HotwordSupport:  true, // 阿里云自学习平台
        DeploymentMode:  "cloud_api",
    }
}
```

---

## 六、供应商配置管理

### 6.1 平台级配置（平台管理员）

```yaml
# configs/config.yaml
asr:
  providers:
    funasr:
      enabled: true
      addr: localhost:10095
    whisper:
      enabled: false
      model_path: /models/whisper-large-v3
      device: cuda
    xunfei:
      enabled: false
    aliyun:
      enabled: false
```

### 6.2 租户级配置（租户管理员在后台自管理）

租户可以：
- 选择启用哪个 Provider
- 配置该 Provider 的连接参数（私有部署地址 or 云 API 密钥）
- 切换 Provider 后立即生效

```go
// ent/schema/asr_provider_config.go
type AsrProviderConfig struct {
    ID           int64
    TenantID     int64
    ProviderName string // funasr / whisper / xunfei / aliyun
    IsActive     bool   // 是否启用
    ConfigJSON   string // Provider 配置参数 JSON
    SampleRate   int    // 采样率，默认 16000
    Language     string // 语言，默认 zh
}
```

---

## 七、音频预处理（各 Provider 共享）

```go
// internal/biz/preprocessor.go

// 降噪 + 增益归一化，所有 Provider 共用
func (p *DefaultPreprocessor) Preprocess(ctx context.Context, chunk PCMChunk) (PCMChunk, error) {
    denoised, err := p.denoiser.Process(chunk.Data)
    if err != nil {
        return PCMChunk{}, fmt.Errorf("denoise: %w", err)
    }
    normalized := p.normalizeVolume(denoised, targetRMS)
    return PCMChunk{
        Data:        normalized,
        Timestamp:   chunk.Timestamp,
        VoiceActive: chunk.VoiceActive,
    }, nil
}
```

---

## 八、ASR 结构化输出（Proto，不变）

```protobuf
// proto/evie/service/v1/asr.proto

message RecognizeRequest {
  string session_id = 1;
  AudioFormat format = 2;
  oneof input {
    bytes audio_data = 4;
    string stream_url = 5;
  }
}

message RecognizeResponse {
  string request_id = 1;
  string text = 2;
  repeated Segment segments = 3;
  float confidence = 4;
  int64 duration_ms = 5;
  string provider_name = 6;  // ← 新增：使用的 ASR 引擎
}
```

### Service 层

```go
// internal/service/asr.go

func (s *ASRService) Recognize(ctx context.Context, req *pb.RecognizeRequest) (*pb.RecognizeResponse, error) {
    tenantID := auth.TenantIDFromContext(ctx)

    result, err := s.uc.Recognize(ctx, biz.CaptureRequest{
        TenantID:  tenantID,
        UserID:    auth.UserIDFromContext(ctx),
        SessionID: req.SessionId,
        Format:    toAudioFormat(req.Format),
    })
    if err != nil {
        return nil, err
    }

    return &pb.RecognizeResponse{
        RequestId:    result.RequestID,
        Text:         result.Text,
        Segments:     toPbSegments(result.Segments),
        Confidence:   result.Confidence,
        DurationMs:   result.DurationMs,
        ProviderName: result.ProviderName,
    }, nil
}
```

---

## 九、配置项汇总

```yaml
# configs/config.yaml
asr:
  default_provider: funasr      # 新租户默认 Provider
  providers:
    funasr:
      enabled: true
      addr: localhost:10095
    whisper:
      enabled: false
      model_path: /models/whisper-large-v3
      device: cuda
  vad:
    engine: webrtc
    energy_threshold: 0.02
    max_silence_frames: 30
  preprocess:
    denoise: true
    denoise_model: deepfilternet
    target_rms: 0.1
  hotword:
    max_per_tenant: 500
    default_weight: 5.0
```

---

## 十、实现现状（截至 2026-08）

> 本章记录实际实现与设计文档的差异，作为开发过程中的同步。

### 10.1 供应商抽象（pkg/asr 开源包）

`ASRProvider` 抽象已落地为**独立开源包 `pkg/asr/`**（非 internal/biz）：

```
pkg/asr/
├── provider.go     # ASRProvider 接口 + 公共类型（结果/参数/能力声明）
├── registry.go     # 并发安全的供应商注册中心（ErrProviderNotFound）
├── audio/          # PCM/WAV 互转工具（各实现与业务层复用）
├── funasr/         # FunASR 实现（HTTP，本地部署）
└── xunfei/         # 讯飞 IAT 实现（WebSocket，云 API）
```

关键调整：
- `ProviderCapabilities` 增加 `Name` 字段（能力声明自包含名称）。
- `RecognizeOptions` 移除 `TenantID`/`UserID`（业务身份经 context 传递，不污染开源抽象）。
- `ProviderRegistry` 并发安全（sync.RWMutex）。

### 10.2 FunASR 实现（HTTP，非 gRPC）

FunASR 对接方式由 gRPC 改为**自建 Python HTTP 服务**（独立服务，可单独开源）：

| 端口 | 模型 | 用途 |
|------|------|------|
| 18000 | SenseVoice-Small | 批量识别（带标点） |
| 18001 | paraformer-zh-streaming | 流式识别 |

服务工程化于 `backend-service/app/funasr/service/`（Python 包 + Dockerfile + deploy，支持 Docker/K8s，离线模型挂载）。

### 10.3 整段 / 流式分场景路由

`route(ctx, stream)` 按识别场景路由：
- 整段批量（`stream=false`）：优先 **funasr**（本地 SenseVoice，约 0.5s/5s 音频，带标点）。
- 流式（`stream=true`）：active 供应商（讯飞 IAT，实时增量）。

> 原因：讯飞 IAT 是「实时流式转写」API，强制按实时节奏逐帧发送，不适合整段批量；
> 本地 funasr 批量推理快 20 倍以上。

### 10.4 流式识别（WebSocket）

- 后端：`/evie/v1/asr/stream`（JWT 鉴权 + 音频转发 + 增量回传，记录保存）。
- 前端：语音识别弹窗双入口（「实时识别」流式 / 「整段识别」批量）。
- 讯飞 IAT 增量需 `dwa:"wpgs"` 参数 + 处理 `pgs`（rpl=替换/apd=追加）字段。

### 10.5 音频上传文件中心

整段/流式识别后，音频统一转 **WAV** 上传文件中心并保存记录（`audio_url`），
供后续预览/重试（ReRecognize）复用，避免重复上传。

---

> 下一份：[2-智能纠错引擎](./2-智能纠错引擎.md)
