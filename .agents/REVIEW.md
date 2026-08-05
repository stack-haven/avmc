# Code Review Checklist

> agent 在执行 code review、代码生成、跨仓库审查时自动加载。
> 每一项都可被自动化 lint 覆盖的规则不在此列（见 `backend-service/.golangci.yml`）。

---

## 一、安全（阻断项）

- [ ] **S01** — `data/` 层所有数据面方法第一行调用 `RequireTenantID(ctx)` 或等效检查
- [ ] **S02** — 跨租户查询显式切换 `entviewer.NewTenantContext(ctx, tenantID)`，不得复用当前 ctx 的 tenant
- [ ] **S03** — 删除操作使用 `DeleteOneID`（依赖 `SoftDeleteMixin` hook），不手动 `SetDeletedAt`
- [ ] **S04** — 无 `SoftDeleteMixin` 的实体如需软删除，先在 schema 添加 Mixin
- [ ] **S05** — 敏感字段（password/token/secret/key/captcha）不写入 Info 级别日志
- [ ] **S06** — 认证失败、无权限、资源不存在返回可区分的错误码，不混用
- [ ] **S07** — 平台控制面操作经过四重校验（`is_platform` + JWT `platform_operator` + Casbin + 中间件）

## 二、分层与架构

- [ ] **A01** — Repository interface 定义在 `internal/biz/`，实现在 `internal/data/`
- [ ] **A02** — Service 层不直接调用 data 层，必须通过 biz usecase
- [ ] **A03** — biz usecase 不 import `ent/gen`，不直接操作 Ent Client
- [ ] **A04** — 新增 usecase/repo/service 依赖已在 Wire ProviderSet 注册
- [ ] **A05** — 新产品业务不写入 `app/platform/admin`，先确认 `docs/services` 落点
- [ ] **A06** — 不因为新增模块默认创建新的 Kratos service（参见拆分条件）

## 三、API 契约

- [ ] **C01** — Proto 变更通过 `buf lint` + `buf breaking` 检查
- [ ] **C02** — `backend-service/api/` 下生成文件不手工修改
- [ ] **C03** — 新增 RPC 遵循 `List/Get/Create/Update/Delete` 命名 + 路径规范
- [ ] **C04** — 分页使用 `pagination.PagingRequest/PagingResponse`，默认 `page_size=20`
- [ ] **C05** — 枚举首个值必须 `_UNSPECIFIED = 0`
- [ ] **C06** — 公共消息优先复用 `proto/common/` 下定义

## 四、数据与持久化

- [ ] **D01** — Schema 修改先改 `ent/schema/*.go`，再 `make generate`，再 Atlas 迁移
- [ ] **D02** — 删除字段先标记废弃一个大版本，再物理删除
- [ ] **D03** — 修改字段类型走：新增 → 数据迁移 → 切换 → 删除旧字段
- [ ] **D04** — `ent/gen/` 下生成代码不手工修改
- [ ] **D05** — ID/status/timestamps/soft delete 等通用字段复用现有 Mixin

## 五、错误与日志

- [ ] **E01** — biz/data 层错误使用 `kratos errors` API：`errors.BadRequest("CODE", "中文消息")`
- [ ] **E02** — 不使用 Proto 生成的 `pb.ErrorXxx` 辅助函数
- [ ] **E03** — data 层错误映射使用 `r.MapNotFound` / `r.MapConstraint`（`base_repo.go`）
- [ ] **E04** — Service/Biz/Data 三层均包含 `log *log.Helper`
- [ ] **E05** — biz logger 用 `log.With(logger, "module", "biz/xxx")` 结构化标识

## 六、风格与一致性

- [ ] **F01** — 构造函数参数顺序：业务依赖在前，`log.Logger` 在最后
- [ ] **F02** — Service 结构体 usecase 字段统一命名 `uc`，不用匈牙利前缀
- [ ] **F03** — 类型/函数级注释用英文，业务逻辑说明可用中文
- [ ] **F04** — 分页使用 `listing.NormalizePageSize` + `listing.PageOffset`（`pkg/aip/listing`）
- [ ] **F05** — Proto 转换使用 `convert.SliceToAny` / `convert.TimeValueToString` / `convert.ToPointer` 等公共函数
- [ ] **F06** — data 层使用 `BaseRepo` 提供的方法，不在子 repo 重复定义

## 七、测试

- [ ] **T01** — 每个 biz usecase 有对应的 `_test.go`
- [ ] **T02** — 新增 data repo 有对应的 `_test.go`
- [ ] **T03** — Mock 使用 `testify/mock`，放在 `_test.go` 同目录
- [ ] **T04** — 租户隔离测试覆盖跨租户外键拒绝场景
- [ ] **T05** — 破坏性 API（删除/发布/撤回/回滚）有集成测试

## 八、前端联动

- [ ] **FE01** — 新增可见 UI 文案同时添加中文和英文 locale key
- [ ] **FE02** — 破坏性操作必须二次确认
- [ ] **FE03** — 菜单标题使用 i18n key，不硬编码字符串
- [ ] **FE04** — 权限控制在后端执行，不只依赖 UI 隐藏
- [ ] **FE05** — Feature Flag 用于灰度，不替代权限校验

## 九、交付检查

- [ ] **R01** — `make check` 通过（fmt-check + lint + vet + test）
- [ ] **R02** — `make contract-check` 通过（proto-lint + generate-check）
- [ ] **R03** — 后端变更在 `backend-service` 内提交，前端在 `frontend-service` 内提交
- [ ] **R04** — 根仓库提交子仓库指针更新（非代码变更）
- [ ] **R05** — 涉及架构变更时同步检查 `docs/architecture/` 对应文档
- [ ] **R06** — 功能完成后更新 `docs/architecture/4-6-治理-开发功能清单.md`

---

## 微服务拆分条件（供参考）

仅当满足以下条件之一时才考虑新建独立 Kratos service：

| 条件 | 示例 |
|------|------|
| 需要独立部署 | 独立发版节奏、独立灰度策略 |
| 需要独立扩缩容 | 某模块 QPS 远高于其他模块 |
| 独立公共 API 或外部接入 | 对外提供 SDK 或第三方可调用 API |
| 独立数据生命周期或合规边界 | 数据独立存储、独立备份、独立合规审计 |
| 清晰业务域和团队 ownership | 独立团队全权负责该模块 |
