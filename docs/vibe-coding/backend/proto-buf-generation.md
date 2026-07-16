# Buf 与 Protobuf 标准生成流程

> 适用范围：`backend-service/proto` 下的 API 契约、`backend-service/api` 生成代码、平台管理后台 OpenAPI、服务配置 proto 和 Ent 生成物。

## 1. 基本原则

- `backend-service/proto` 是后端接口契约唯一源头。
- `backend-service/api`、`app/*/internal/conf`、`app/platform/admin/internal/data/ent/gen` 是生成产物，不手工修改。
- Protobuf 变更必须先改 `.proto`，再生成，再改 `service -> biz -> data -> ent`。
- 生成器版本必须固定在 Buf 模板中，不使用 `latest`。
- 不再用局部模板绕过全量生成来提交 API 产物；局部生成只允许用于定位问题，不能作为最终提交来源。

## 2. 当前标准工具链

当前后端主生成模板为 `backend-service/proto/buf.gen.yaml`：

- `buf.build/protocolbuffers/go:v1.36.11`
- `buf.build/grpc/go:v1.6.0`
- 本地 `protoc-gen-go-http`
- 本地 `protoc-gen-go-errors`
- `buf.build/bufbuild/validate-go:v1.2.1`
- 本地 `protoc-gen-go-aip`

配置 proto 模板：

- `backend-service/app/platform/admin/buf.gen.yaml`
- `backend-service/app/ai/service/buf.gen.yaml`
- `backend-service/app/version/service/buf.gen.yaml`

这些模板的 `protoc-gen-go` 版本必须与主模板保持一致。

## 3. 标准执行顺序

在 `backend-service` 目录执行：

```bash
GOCACHE=/private/tmp/avmc-go-cache make generate-check
```

该命令执行：

1. `make proto`
2. `go generate ./app/platform/admin/internal/data/ent`
3. `go mod tidy`
4. `make diff-check`

如果只是检查 proto 是否可编译：

```bash
cd backend-service/proto
buf build
```

如果检查 lint 基线：

```bash
cd backend-service
./scripts/check-buf-lint-baseline.sh
```

当前 `buf lint` 仍存在历史基线债务，新增 proto 不得引入新的 lint 违规。接受或消除历史债务时，才允许更新 `backend-service/proto/buf-lint-baseline.txt`。

## 4. 契约变更流程

1. 修改 `backend-service/proto/**/*.proto`。
2. 运行 `cd backend-service/proto && buf build`。
3. 运行 `cd backend-service && ./scripts/check-buf-lint-baseline.sh`。
4. 运行 `cd backend-service && GOCACHE=/private/tmp/avmc-go-cache make generate-check`。
5. 检查生成 diff 是否只包含受影响 API、validate、OpenAPI、Ent、go.mod/go.sum。
6. 修改对应 Kratos service、biz usecase、data repo、Ent schema 和测试。
7. 运行受影响包测试，再运行 `GOCACHE=/private/tmp/avmc-go-cache go test ./...`。

## 5. 禁止事项

- 禁止手工编辑 `backend-service/api/**/*.pb.go`、`*.pb.validate.go`、`*_grpc.pb.go`、`*_http.pb.go`、`*_errors.pb.go`。
- 禁止手工编辑 `app/platform/admin/internal/data/ent/gen`。
- 禁止在主流程中使用 `buf.local.gen.yaml` 作为最终生成来源。
- 禁止在同一提交中混用不同版本的 `protoc-gen-go` 或 `protoc-gen-go-grpc`。
- 禁止新增 `validate/validate.proto` 的 PGV 规则；新规则使用 `buf/validate/validate.proto`。

## 6. 常见问题处理

### 6.1 全量生成产生大量 `.pb.go` diff

优先检查 `proto/buf.gen.yaml` 中的远程插件版本是否与已提交生成物一致。生成器版本漂移会导致 raw descriptor 表达形式、gRPC unimplemented 默认错误、注释拼写等大面积变化。

### 6.2 新增 `.pb.validate.go` 没有提交

`validate-go` 会为带 `buf.validate` 的 proto 生成校验文件。`make diff-check` 会检查未跟踪生成文件，发现后必须纳入同一提交。

### 6.3 `buf lint` 失败

不要直接放宽 `buf.yaml`。先运行 `./scripts/check-buf-lint-baseline.sh` 判断是否新增违规。只有明确要治理或接受历史债务时，才更新基线。

### 6.4 前端不使用 `src/api/gen`

当前后台管理前端不以 proto 生成的 TS API 为主路径。后端 proto 仍是服务契约源头，前端按 `apps/web-antd-admin/src/api/**` 的当前项目方式维护接口类型。

## 7. 提交要求

后端契约相关提交至少包含：

- `.proto` 契约变更。
- `backend-service/api` 生成产物。
- 必要的 `*.pb.validate.go` 新增或变更。
- `go.mod/go.sum` 因生成或依赖整理产生的必要变化。
- 业务分层实现与测试。
- 本文档或架构文档的流程变更记录，若本次调整了生成策略。

