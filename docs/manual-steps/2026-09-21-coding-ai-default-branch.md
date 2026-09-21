# 将所有仓库默认分支改为 `coding/ai` — 手动操作步骤

> 创建于 2026-09-21
> 背景：已完成所有仓库 `codex/ai`/`main`/`ark-tech` → `coding/ai` 重命名 + 推送。
> 剩余：GitHub 端默认分支设置（需要人工或 API）。

## 一、为什么不能完全自动

GitHub 不允许通过 `git push` 修改仓库的默认分支（default branch）。需要：
- **方式 A**：在 GitHub 网页设置（推荐，无需 token）
- **方式 B**：通过 GitHub API（需要 `GITHUB_TOKEN`，自动化场景）

## 二、需要操作的 4 个仓库

| # | 仓库 | 当前远端默认 | 目标默认 | coding/ai 状态 |
|---|------|-------------|---------|---------------|
| 1 | stack-haven/avmc | `main` | `coding/ai` | ✅ 已推送 |
| 2 | stack-haven/avmc-backend-service | `main` | `coding/ai` | ✅ 已推送 |
| 3 | stack-haven/avmc-frontend-service | `avmc/main` | `coding/ai` | ✅ 已推送 |
| 4 | stack-haven/avmc-mobile-desktop-service | `main` | `coding/ai` | ✅ 已推送 |

## 三、方式 A：GitHub 网页操作（推荐）

对每个仓库，重复以下步骤：

### 步骤 1：打开仓库设置
- 仓库 1：https://github.com/stack-haven/avmc/settings/branches
- 仓库 2：https://github.com/stack-haven/avmc-backend-service/settings/branches
- 仓库 3：https://github.com/stack-haven/avmc-frontend-service/settings/branches
- 仓库 4：https://github.com/stack-haven/avmc-mobile-desktop-service/settings/branches

### 步骤 2：修改默认分支
1. 找到 "Default branch" 区域
2. 点击分支名右侧的 **切换图标**（双向箭头）
3. 在弹出框中选择 `coding/ai`
4. 点击 "Update"
5. 弹出确认框，勾选 "I understand, update the default branch."
6. 点击 "I understand, update the default branch." 确认

### 步骤 3：（可选）删除旧分支
- 仓库 1：删除 `main` 分支
  - https://github.com/stack-haven/avmc/branches
  - 找到 `main` → 点击垃圾桶图标 → 确认
- 仓库 2：删除 `main` 分支
  - https://github.com/stack-haven/avmc-backend-service/branches
- 仓库 3：删除 `avmc/main` 分支
  - https://github.com/stack-haven/avmc-frontend-service/branches
- 仓库 4：删除 `main` 分支
  - https://github.com/stack-haven/avmc-mobile-desktop-service/branches

> ⚠️ 删除默认分支前必须先把默认分支改为 `coding/ai`，否则 GitHub 会拒绝删除。

## 四、方式 B：API 自动化（需要 `GITHUB_TOKEN`）

如果想脚本化，需要 Personal Access Token（fine-grained, `Administration: Write` 权限）。

```bash
# 1. 在 https://github.com/settings/tokens 创建 token
# 2. 设为环境变量
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

# 3. 对 4 个仓库执行
for repo in avmc avmc-backend-service avmc-frontend-service avmc-mobile-desktop-service; do
  curl -X PATCH \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d '{"default_branch": "coding/ai"}' \
    "https://api.github.com/repos/stack-haven/$repo"
done

# 4. 验证
for repo in avmc avmc-backend-service avmc-frontend-service avmc-mobile-desktop-service; do
  echo "=== $repo ==="
  curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/stack-haven/$repo" | grep '"default_branch"'
done
```

## 五、操作验证清单

完成所有 4 个仓库设置后，可通过以下方式验证：

```bash
# 在本地检查（已自动设置 origin HEAD）
for repo in . backend-service frontend-service mobile-desktop-service; do
  cd /Users/jayden/Development/Code/Object/stack-haven/avmc/$repo
  echo "$repo: 远端 HEAD = $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"
done

# 期望输出：
# .: 远端 HEAD = refs/remotes/origin/coding/ai
# backend-service: 远端 HEAD = refs/remotes/origin/coding/ai
# frontend-service: 远端 HEAD = refs/remotes/origin/coding/ai
# mobile-desktop-service: 远端 HEAD = refs/remotes/origin/coding/ai
```

## 六、影响面

### 对协作的影响
- 所有新 clone 默认检出 `coding/ai` 分支
- PR 默认目标从 `main` 改为 `coding/ai`
- 旧链接（`/tree/main`、`/blob/main`）需要更新到 `/tree/coding/ai`

### 对 CI/CD 的影响
- CI 触发分支过滤需要更新（之前是 `ark-tech`、`codex/ai`，现统一为 `coding/ai`）
- 根仓库 4-6 治理清单需要更新相关文档
- 子仓库的子模块指针需要指向 `coding/ai` 分支

### 对其他文档的影响
- `mobile-desktop-service/AGENTS.md` 中如有 `git@github.com:.../main` 字样需要更新
- 各子仓库的 README 中如引用 `main` 分支需要更新
