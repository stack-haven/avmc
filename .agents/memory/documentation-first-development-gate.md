---
title: Documentation-First Development Gate
scope: Ark Tech Platform development workflow and current refactor recovery
modified: 2026-08-04
---

# Documentation-First Development Gate

## Durable principle

需求和文档先于开发。开始、继续或扩展任何功能前，必须先明确：

- 用户需求和业务目标
- 可验证的验收标准
- 功能边界与非目标
- 对应架构/产品设计文档
- `4-6-治理-开发功能清单` 中的规划状态
- `4-7-治理-代码功能清单` 中的代码落点和验证状态

需求或文档没有收口时，不进入下一功能开发。

## Completion semantics

- `[ ]`：需求已记录但尚未开发。
- `[~]`：实现或重构进行中，或者代码已存在但自动化验证、人工功能验证、文档同步任一环节尚未完成。
- `[x]`：实现完成，自动化验证通过，人工功能验证通过，文档与源码追溯同步完成。
- `[.]`：明确暂缓，并记录原因。

不得用“代码存在”“能够编译”或“自动化测试通过”单独替代人工功能验证。

## Current recovery context

当前不是下一功能开发阶段，而是人工测试和重构后的文档收口阶段。

本轮重构涉及：

- 租户 CRUD、生命周期和原子开通链路
- 原通用菜单权限组重构并重命名为租户菜单权限组
- 租户与菜单权限组绑定、版本发布/回滚、角色有效菜单
- 登录页通过租户名称查询租户 ID 后登录
- 前端租户页、租户菜单权限组页、路由、API 和中英文文案
- capabilities、资源额度和权限缓存的联动链路

当前风险：

- `resource_quota_usecase.go` 的租户额度解析仍有待重建 TODO，相关测试存在 skip。
- `cache_version.go` 的缓存版本刷新仍有待重建 TODO。
- 旧 `menu_permission_group` 源码路径和前端页面已经删除或重命名，旧代码清单追溯不可继续使用。
- 上述受影响功能在统一人工复验和文档收口前保持 `[~]`。

## Required reading order

1. `.agents/AGENTS.md`
2. `.agents/RULES.md`
3. `docs/architecture/4-6-治理-开发功能清单.md`
4. `docs/architecture/4-7-治理-代码功能清单.md`
5. 对应专题设计文档
6. 当前代码和人工测试结果

只有本轮收口完成并形成下一项明确需求与验收标准后，才选择新的开发功能。
