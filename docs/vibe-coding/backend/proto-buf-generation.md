# Buf 与 Protobuf 标准生成流程

> 适用范围：`backend-service/proto` 下的 API 契约、`backend-service/api` 生成代码，以及各项目服务目录下的 OpenAPI、配置 proto 和 Ent 生成物。

## 1. 基本原则

- `backend-service/proto` 是后端接口契约唯一源头。
- `backend-service/api`、`app/*/internal/conf`、`app/platform/admin/internal/data/ent/gen` 是生成产物，不手工修改。
- Protobuf 变更必须先改 `.proto`，再生成，再改 `service -> biz -> data -> ent`。
- 生成器版本必须固定在 Buf 模板中，不使用 `latest`。
- 不再用局部模板绕过全量生成来提交 API 产物；局部生成只允许用于定位问题，不能作为最终提交来源。
- 根 `backend-service/Makefile` 只维护全局后端命令；服务相关命令必须放在对应服务目录，例如 `app/platform/admin/Makefile`。

## 2. 当前标准工具链

当前后端主生成模板为 `backend-service/proto/buf.gen.yaml`：

- `buf.build/protocolbuffers/go:v1.36.11`
- `buf.build/grpc/go:v1.6.0`
- 本地 `protoc-gen-go-http`
- 本地 `protoc-gen-go-errors`
- `buf.build/bufbuild/validate-go:v1.2.1`
- 本地 `protoc-gen-go-aip`

主模板必须覆盖当前后端统一 proto 契约入口：

- `core/service/v1`
- `platform/admin/v1`
- `ai/service/v1`
- `version/service/v1`

配置 proto 模板：

- `backend-service/app/platform/admin/buf.gen.yaml`
- `backend-service/app/ai/service/buf.gen.yaml`
- `backend-service/app/version/service/buf.gen.yaml`

这些模板的 `protoc-gen-go` 版本必须与主模板保持一致。

## 3. 标准执行顺序

### 3.1 全局 API 契约生成

在 `backend-service` 目录执行：

```bash
GOCACHE=/private/tmp/avmc-go-cache make generate-check
```

该命令执行：

1. `make proto`
2. `go mod tidy`
3. `make diff-check`

根目录 `generate-check` 只检查全局 API 生成产物：`go.mod`、`go.sum`、`api`。它不生成任何项目服务的 OpenAPI、配置文件或 Ent 代码。

### 3.2 Platform Admin 服务生成

在 `backend-service/app/platform/admin` 目录执行：

```bash
GOCACHE=/private/tmp/avmc-go-cache make generate-check
```

该命令执行：

1. `make api`
2. `make ent`
3. `make config`
4. `make doc`
5. `go mod tidy`
6. `make diff-check`

服务目录 `generate-check` 负责检查本服务生成产物：全局 `api`、`app/platform/admin/cmd/server/assets/openapi.yaml`、`app/platform/admin/internal/conf`、`app/platform/admin/internal/data/ent/gen`、`go.mod`、`go.sum`。

服务 Ent 生成统一走 `app.mk` 的 `make ent`，其内部调用服务本地 `go generate ./internal/data/ent`。每个服务必须通过自己的 `internal/data/ent/generate.go` 和 `entc.go` 固化 Ent 特性，不能在共享 `app.mk` 中硬编码某个服务的 Ent feature。

常用服务命令：

```bash
cd backend-service/app/platform/admin
make doc      # 生成 platform/admin OpenAPI 文档
make config   # 生成 platform/admin internal/conf
make ent      # 生成 platform/admin Ent 代码
make migrate  # 执行 platform/admin 数据库迁移
make policy   # 初始化 platform/admin 授权策略
make mock     # 生成 platform/admin 演示数据
```

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
4. 如果只影响全局 API，运行 `cd backend-service && GOCACHE=/private/tmp/avmc-go-cache make generate-check`。
5. 如果影响 `platform/admin` 服务，运行 `cd backend-service/app/platform/admin && GOCACHE=/private/tmp/avmc-go-cache make generate-check`。
6. 检查生成 diff 是否只包含受影响 API、validate、OpenAPI、Ent、go.mod/go.sum。
7. 修改对应 Kratos service、biz usecase、data repo、Ent schema 和测试。
8. 运行受影响包测试，再运行 `GOCACHE=/private/tmp/avmc-go-cache go test ./...`。

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
