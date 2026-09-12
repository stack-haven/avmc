---
name: agent-decision-boundary
description: 执行 Ark Tech Platform Agent 决策权限分级与协作三模式门禁。当 Agent 准备做出架构/边界/契约/产品决策前调用，或不确定当前动作属于 autonomous / requires-confirmation / forbidden 哪一档时使用。任何会改变公共契约、租户隔离、认证授权、跨产品公共能力、平台-产品边界或破坏性变更的请求都必须先经过本 skill 的边界判定。
---

# Agent Decision Boundary

强制执行 `.agents/AGENTS.md` 中的「Agent 决策权限分级」与「协作模式」门禁。本 skill 是该分级在执行层的可操作版本。

## 0. 启动确认（每次必做）

读取以下事实来源：

1. `.agents/AGENTS.md` §Agent 决策权限分级
2. `.agents/AGENTS.md` §协作模式
3. `.agents/REVIEW.md` 阻断项
4. `docs/architecture/0-4-架构总览-工程治理总纲.md` §五、§六
5. 本次任务的 4-6 / 4-7 清单条目

## 1. 决策档位判定

按以下顺序判定本次动作落入哪一档：

1. 是否命中 `forbidden` 清单？→ 立即停止，告知用户该决策不属于 Agent 范围。
2. 是否命中 `requires-confirmation` 任一条目？→ 暂停执行，向用户说明触发条件与建议确认对象，等待明确批准。
3. 其余按 `autonomous` 处理，但在实施前必须确认当前处于哪个协作模式。

## 2. 协作模式判定

| 当前请求 | 默认模式 | 说明 |
|---|---|---|
| 「先分析一下 / 看看现状 / 评估方案」 | Explore | 仅只读分析，不修改任何文件 |
| 「实现 / 修复 / 添加 / 重构」+ 已有确认方案 | Implement | 进入完整实现与验证工作流 |
| 「review / 审查 / 验收」 | Review | 仅报告缺陷与回归，不修改业务代码 |

**模式门禁**：

- Explore 阶段产出方案后必须等待用户明确批准才能进入 Implement。
- Implement 阶段：先 `4-7` 清单标记 `[~]`，完成实现 → 运行 `make check` / `buf breaking` / `pnpm typecheck & build` → 准备验证证据 → 标注 `[x]`。
- Review 阶段：发现缺陷一律写报告，由用户决定是否回退到 Implement 修复。

## 3. forbidden 触发时的输出模板

```
🚫 触发 Agent 决策权限 forbidden 分级
动作: <动作描述>
命中条目: <forbidden 清单中具体条目>
原因: <为什么属于该档>
建议: <应交给谁/什么角色决定>
当前模式: Explore | Implement | Review
下一步: 停止，等待用户重新确认或转交给对应决策者
```

## 4. requires-confirmation 触发时的输出模板

```
⚠️ 触发 Agent 决策权限 requires-confirmation 分级
动作: <动作描述>
命中条目: <requires-confirmation 清单中具体条目>
确认对象建议: <架构师 / DBA / 安全负责人 / 产品负责人>
影响范围: <受影响的服务/产品/接口>
当前模式: Explore | Implement | Review
下一步: 暂停编码，等待用户确认。Explore 模式下可继续分析但不改文件。
```

## 5. autonomous 动作的执行约束

即便动作落入 autonomous 档，仍需遵守：

- 不修改生成代码（`backend-service/api/`、`ent/gen/`、Swagger bundle、OpenAPI 输出）
- 不重命名 `platform/admin` 为 `platform/service` 之外的旧路径
- 不绕过 4-6 / 4-7 清单门禁
- 不破坏依赖方向硬规则（service → biz → data）
- 不引入 pkg/ 之外的散落工具函数
- 完成后必须更新对应的 4-6 / 4-7 状态

## 6. 与其他 skill 的关系

- 与 `avmc-feature-delivery` 互补：本 skill 关注「能不能做」，`avmc-feature-delivery` 关注「怎么做」。
- 与 `avmc-cross-repo-review` 互补：Review 模式下游必须调用 `avmc-cross-repo-review` 做交付审查。
- 与 `avmc-contract-first-backend` 互补：API 契约变更类 requires-confirmation 项目，使用 `avmc-contract-first-backend` 完成调研。

## 7. 反例（Agent 不得自行决定）

- ❌ 把 Evie 的菜单注册文件改到 GEO 的 seed 目录
- ❌ 为加速功能给 `app/platform/service` 加新业务模块
- ❌ 删 Ent 字段「先注释」不做废弃大版本标记
- ❌ 复制 `app/evie/service` 整目录新建 `app/geo/service` 而不写 ADR
- ❌ 把 buf breaking 失败通过 `--force` 跳过

## 8. 反例（Agent 不得跳过流程）

- ❌ Explore 阶段产出方案后直接开始改代码
- ❌ Implement 阶段未跑 `make check` 就声称完成
- ❌ 拒绝覆盖率达到门禁阈值后悄悄跳过
- ❌ 4-7 清单未更新就声称交付完成
