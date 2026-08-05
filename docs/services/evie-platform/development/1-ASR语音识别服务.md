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

---

## 二、处理流水线

```
音频采集 → 转码归一化 → 降噪/增益 → VAD 语音检测 → ASR 模型推理 → 热词增强 → 结构化输出
```

每个阶段独立可替换，通过接口抽象。

---

## 三、Go 接口定义

### 3.1 音频采集接口

```go
// internal/biz/asr.go

// AudioCapture 音频采集抽象
type AudioCapture interface {
    // Capture 建立音频流连接，返回只读 PCM 通道
    Capture(ctx context.Context, req CaptureRequest) (<-chan PCMChunk, error)
}

type CaptureRequest struct {
    TenantID  string
    UserID    string
    Mode      CaptureMode  // webrtc / websocket / sdk / telephony
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
    Data       []byte  // raw PCM bytes
    Timestamp  int64   // unix millis
    VoiceActive bool   // VAD 中间结果
}
```

### 3.2 预处理接口

```go
// AudioPreprocessor 音频预处理
type AudioPreprocessor interface {
    // Preprocess 对 PCM 帧做降噪、增益归一化
    Preprocess(ctx context.Context, chunk PCMChunk) (PCMChunk, error)
}

// VADDetector 语音活动检测
type VADDetector interface {
    // Detect 判断当前帧是否有人声
    Detect(chunk PCMChunk) (voiceActive bool, confidence float64)
}
```

### 3.3 ASR 模型接口

```go
// ASREngine ASR 模型推理抽象
type ASREngine interface {
    // Recognize 同步识别（短音频）
    Recognize(ctx context.Context, audio []byte) (*ASRResult, error)

    // StreamRecognize 流式识别，实时返回中间结果
    StreamRecognize(ctx context.Context, audioCh <-chan PCMChunk, resultCh chan<- ASRStreamResult) error
}

type ASRResult struct {
    RequestID   string
    Text        string
    Segments    []ASRSegment
    Confidence  float64
    DurationMs  int64
}

type ASRSegment struct {
    StartMs int64
    EndMs   int64
    Text    string
}

type ASRStreamResult struct {
    IsFinal     bool
    Text        string     // 增量或最终文本
    Confidence  float64
    Timestamp   int64
}
```

### 3.4 热词增强接口

```go
// HotwordEnhancer 热词增强
type HotwordEnhancer interface {
    // Enhance 用租户热词修正 ASR 结果
    Enhance(ctx context.Context, tenantID string, result *ASRResult) (*ASRResult, error)

    // GetHotwords 获取租户当前热词列表
    GetHotwords(ctx context.Context, tenantID string) ([]Hotword, error)
}

type Hotword struct {
    Word     string
    Weight   float64 // 0-10
    Category string  // person / org / product / term
}
```

---

## 四、Biz 层编排逻辑

```go
// internal/biz/asr.go

type ASRUsecase struct {
    capture      AudioCapture
    preprocessor AudioPreprocessor
    vad          VADDetector
    engine       ASREngine
    hotword      HotwordEnhancer
    repo         ASRRepo
}

func (uc *ASRUsecase) StreamRecognize(ctx context.Context, req CaptureRequest) (*ASRResult, error) {
    // 1. 建立音频采集
    pcmCh, err := uc.capture.Capture(ctx, req)
    if err != nil {
        return nil, fmt.Errorf("capture: %w", err)
    }

    // 2. 流式处理
    resultCh := make(chan ASRStreamResult, 16)
    go func() {
        defer close(resultCh)
        _ = uc.engine.StreamRecognize(ctx, pcmCh, resultCh)
    }()

    // 3. 预处理 + VAD + 收集结果
    var finalResult *ASRResult
    for r := range resultCh {
        if r.IsFinal {
            // 4. 热词增强
            enhanced, err := uc.hotword.Enhance(ctx, req.TenantID, &ASRResult{
                Text:       r.Text,
                Confidence: r.Confidence,
            })
            if err != nil {
                return nil, fmt.Errorf("hotword enhance: %w", err)
            }
            finalResult = enhanced
            break
        }
    }

    // 5. 持久化识别记录
    _ = uc.repo.SaveRecord(ctx, ASRRecord{
        TenantID:    req.TenantID,
        UserID:      req.UserID,
        SessionID:   req.SessionID,
        RawText:     finalResult.Text,
        Confidence:  finalResult.Confidence,
        DurationMs:  finalResult.DurationMs,
    })

    return finalResult, nil
}
```

---

## 五、ASR 引擎实现方案

### 5.1 推荐路线：FunASR 优先

| 阶段 | 方案 | 说明 |
|------|------|------|
| Phase 1 | FunASR 私有部署 | gRPC 调用 FunASR Server，Go 侧做 client 封装 |
| Phase 2 | FunASR + Whisper Ensemble | 双模型投票提升准确率 |
| Phase 3 | 企业领域微调 | 基于企业数据 Fine-tune |

### 5.2 FunASR Client 实现

```go
// internal/data/asr_funasr.go

type FunASRClient struct {
    client funasr.Client  // 假设 proto 生成的 client
}

func (c *FunASRClient) Recognize(ctx context.Context, audio []byte) (*ASRResult, error) {
    resp, err := c.client.Recognize(ctx, &funasr.RecognizeRequest{
        Audio:     audio,
        Hotwords:  "",  // 热词通过 FunASR hotword 机制传入
        Format:    "pcm",
        SampleRate: 16000,
    })
    if err != nil {
        return nil, fmt.Errorf("funasr recognize: %w", err)
    }
    return &ASRResult{
        RequestID:  resp.RequestId,
        Text:       resp.Text,
        Confidence: resp.Confidence,
        Segments:   toSegments(resp.Segments),
    }, nil
}
```

---

## 六、音频预处理实现

```go
// internal/biz/preprocessor.go

// 降噪：调用 DeepFilterNet / RNNoise（通过 cgo 或子进程）
// 增益：RMS-based 归一化
func (p *DefaultPreprocessor) Preprocess(ctx context.Context, chunk PCMChunk) (PCMChunk, error) {
    // 1. 降噪（调用外部库）
    denoised, err := p.denoiser.Process(chunk.Data)
    if err != nil {
        return PCMChunk{}, fmt.Errorf("denoise: %w", err)
    }

    // 2. 自动增益
    normalized := p.normalizeVolume(denoised, targetRMS)

    return PCMChunk{
        Data:       normalized,
        Timestamp:  chunk.Timestamp,
        VoiceActive: chunk.VoiceActive,
    }, nil
}

// normalizeVolume 基于 RMS 归一化到目标电平
func (p *DefaultPreprocessor) normalizeVolume(samples []byte, targetRMS float64) []byte {
    rms := calcRMS(samples)
    if rms < 1e-6 {
        return samples
    }
    gain := targetRMS / rms
    return applyGain(samples, gain)
}
```

---

## 七、VAD 实现

```go
// internal/biz/vad.go

// 使用 WebRTC VAD（通过 CGo 或 Go 移植版）
// 简化方案：基于能量阈值 + 过零率
type SimpleVAD struct {
    energyThreshold float64
    silenceFrames   int
    maxSilence      int // 连续静音超过此帧认为语音结束
}

func (v *SimpleVAD) Detect(chunk PCMChunk) (bool, float64) {
    energy := v.calcEnergy(chunk.Data)
    if energy > v.energyThreshold {
        v.silenceFrames = 0
        return true, energy / v.energyThreshold
    }
    v.silenceFrames++
    return v.silenceFrames <= v.maxSilence, 0
}
```

---

## 八、热词加载与管理

### 8.1 租户隔离加载

```go
// internal/biz/hotword.go

func (h *HotwordService) GetHotwords(ctx context.Context, tenantID string) ([]Hotword, error) {
    // 三级热词合并
    // 1. 系统热词（业务系统自动提供，如金种籽的产品词）
    sys, _ := h.repo.FindSystemHotwords(ctx)

    // 2. 企业热词（租户自定义）
    tenant, _ := h.repo.FindTenantHotwords(ctx, tenantID)

    // 3. 加载到 ASR 引擎的热词表
    merged := mergeHotwords(sys, tenant)
    return merged, nil
}
```

### 8.2 热词库结构

```go
// internal/data/ent/schema/hotword.go

type Hotword struct {
    ID        int64
    TenantID  int64     // 0 = 系统级
    Word      string    // 热词原文
    Target    string    // 期望识别结果（可选，为空则用 Word）
    Weight    float64   // 0-10
    Category  string    // person / org / product / term
    Status    int       // 1=启用 0=停用
}
```

---

## 九、ASR 结构化输出（Proto）

```protobuf
// proto/evie/service/v1/asr.proto

message RecognizeRequest {
  string tenant_id = 1;
  string session_id = 2;
  AudioFormat format = 3;
  oneof input {
    bytes audio_data = 4;     // 同步：完整音频
    string stream_url = 5;    // 流式：WebSocket URL
  }
}

message AudioFormat {
  string encoding = 1;      // pcm / wav / mp3 / opus
  int32 sample_rate = 2;    // 16000
  int32 bit_depth = 3;      // 16
  int32 channels = 4;       // 1
}

message RecognizeResponse {
  string request_id = 1;
  string text = 2;
  repeated Segment segments = 3;
  float confidence = 4;
  int64 duration_ms = 5;
}

message Segment {
  int64 start_ms = 1;
  int64 end_ms = 2;
  string text = 3;
  float confidence = 4;
}
```

### Service 层

```go
// internal/service/asr.go

func (s *ASRService) Recognize(ctx context.Context, req *pb.RecognizeRequest) (*pb.RecognizeResponse, error) {
    tenantID := auth.TenantIDFromContext(ctx) // 从 JWT 提取，不信任客户端传入

    result, err := s.uc.StreamRecognize(ctx, biz.CaptureRequest{
        TenantID:  tenantID,
        UserID:    auth.UserIDFromContext(ctx),
        SessionID: req.SessionId,
        Format:    toAudioFormat(req.Format),
    })
    if err != nil {
        return nil, err
    }

    return toRecognizeResponse(result), nil
}
```

---

## 十、ASR 配置项

```yaml
# configs/config.yaml
asr:
  engine: funasr          # funasr / whisper / sensevoice
  funasr:
    addr: localhost:10095
  whisper:
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

> 下一份：[2-智能纠错引擎](./2-智能纠错引擎.md)
