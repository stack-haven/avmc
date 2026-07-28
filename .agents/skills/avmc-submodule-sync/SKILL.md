---
description: |
  处理 Ark Tech Platform gitsubmodule 提交工作流，保证根仓库和子仓库提交顺序正确。当涉及跨仓库代码修改、提交、或查看状态时触发。

  触发场景：
  - "提交代码" / "git commit 这次改动"
  - "看看现在的 git 状态" / "有哪些未提交的修改"
  - "帮我提交后端子仓库的改动"
  - "更新子仓库指针"
  - 任何在多仓库项目中涉及 git 操作的任务
name: avmc-submodule-sync
---

# Ark Tech Platform 子模块提交工作流

Ark Tech Platform 有 3 个 git 仓库：**根仓库** + **`backend-service`** + **`frontend-service`**。每个仓库各自的提交不可混淆。

## 1. 诊断当前状态

首先检查所有仓库的 git 状态：

```bash
# 根仓库
git status

# 后端子仓库
cd backend-service && git status && git log --oneline -3 && cd ..

# 前端子仓库
cd frontend-service && git status && git log --oneline -3 && cd ..
```

## 2. 判断修改归属

根据文件路径判断：

| 文件路径前缀 | 归属仓库 |
|---|---|
| `backend-service/` 下除 `.gitmodules` 的改动 | `backend-service` |
| `frontend-service/` 下除 `.gitmodules` 的改动 | `frontend-service` |
| `docs/`、`README.md`、`CLAUDE.md`、`.agents/`、根级配置 | 根仓库 |

**常见错误：** 在根仓库直接 commit 子仓库内的文件改动。❌ 这是错误的。

## 3. 提交顺序

```
子仓库内 commit → 根仓库更新子模块指针 → 根仓库 commit
```

### Step 1: 在子仓库内提交

```bash
cd backend-service   # 或 frontend-service
git add <相关文件>
git commit -m "feat(xxx): 描述改动内容"
```

### Step 2: 回到根仓库更新子模块指针

```bash
cd ..
git add backend-service   # 或 frontend-service
```

### Step 3: 根仓库提交

```bash
git commit -m "chore: 更新 backend-service 子模块指针"
```

## 4. 提交信息规范

遵循 Conventional Commits：

```
<type>(<scope>): <description>

类型: feat / fix / chore / refactor / docs / style / test
scope 示例: admin / proto / project / version / ai / deps
```

后端示例：
```
feat(project): 新增项目成员管理 CRUD 接口
fix(auth): 修复 JWT token 过期未刷新问题
```

前端示例：
```
feat(project): 新增项目管理列表页和创建表单
fix(user): 修复用户角色选择不生效问题
```

根仓库示例：
```
chore: 更新 backend-service 子模块指针
docs: 更新迭代开发规划文档
```

## 5. 多仓库修改协调

如果一次改动同时涉及后端和前端：
1. 先提交 `backend-service` → 根仓库指针更新
2. 再提交 `frontend-service` → 根仓库指针更新
3. 根仓库最后一次 commit 包含两个指针更新 + 文档变更

## 6. 撤销误提交

如果发现把子仓库代码提交到了根仓库：

```bash
# 在根仓库撤销最近一次提交（保留改动文件）
git reset --soft HEAD~1
# 进入子仓库重新 add + commit
cd backend-service && git add . && git commit -m "..."
cd ..
git add backend-service
git commit -m "chore: 更新 backend-service 子模块指针"
```
