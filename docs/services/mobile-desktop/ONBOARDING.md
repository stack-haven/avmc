# Mobile Desktop Service 子仓库创建引导

> 本文档指导完成 mobile-desktop-service 子仓库的首次创建。
> 完成后即可在子仓库内开发第一个端应用（如 Evie Mobile）。

---

## 前置条件（必读）

- [ ] 已确认命名 `mobile-desktop-service`（见 `docs/services/mobile-desktop/SERVICE.md`）
- [ ] 已有 GitHub `stack-haven` 组织（或个人账户）的写入权限
- [ ] 本地 SSH key 已添加到 GitHub（`git@github.com:...` 协议）
- [ ] 本地有 Flutter / Node.js / Buf CLI（按需）

---

## Step 1：在 GitHub 创建仓库（手动操作）

打开：https://github.com/organizations/stack-haven/repositories/new

填写：

| 字段 | 值 |
|------|-----|
| Owner | `stack-haven` |
| Repository name | `avmc-mobile-desktop-service` |
| Description | `Ark Tech Platform 多端应用承载层（桌面 + 移动 + 小程序）。Flutter / RN / uni-app monorepo。` |
| Visibility | **Private** |
| Add a README | ❌ 不勾选 |
| Add .gitignore | ❌ 不勾选 |
| Choose a license | ❌ 不勾选 |
| Allow squash merging | ✅ 勾选 |

点击 **Create repository** 后，**保留 Quick setup 页面打开**，下面会用到 SSH URL。

---

## Step 2：在根仓库注册子仓库（我执行 / 你确认）

我会在根仓库 `/Users/jayden/Development/Code/Object/stack-haven/avmc/.gitmodules` 末尾追加：

```ini
[submodule "mobile-desktop-service"]
	path = mobile-desktop-service
	url = git@github.com:stack-haven/avmc-mobile-desktop-service.git
```

并同步更新：
- `README.md`（如果存在子仓库列表）
- `CLAUDE.md`（如果存在）

然后在根仓库提交（commit message：`chore: 注册 mobile-desktop-service 子仓库`）。

**这一步需要你确认后再执行。**

---

## Step 3：本地 clone + 初始化骨架（你执行）

创建完 GitHub 仓库后，**一次性执行**以下命令：

```bash
# ==== 1. 在根仓库（avmc）所在父目录创建子仓库 ====

# 假设当前目录在根仓库根
cd ..

# ==== 2. clone 子仓库到 avmc-mobile-desktop-service 目录 ====

git clone git@github.com:stack-haven:stack-haven/avmc-mobile-desktop-service.git
# 注意：实际是 git@github.com:stack-haven/avmc-mobile-desktop-service.git

cd avmc-mobile-desktop-service

# ==== 3. 复制 avmc-mobile-desktop-monorepo skill 的脚本到 tool/ ====

# 从 avmc 仓库的 .agents/skills/ 复制
SKILL_DIR="/path/to/avmc/.agents/skills/avmc-mobile-desktop-monorepo"

mkdir -p tool
cp "$SKILL_DIR/scripts/"*.sh tool/
chmod +x tool/*.sh

# ==== 4. 跑 init_monorepo.sh 初始化 monorepo 骨架 ====

bash tool/init_monorepo.sh

# ==== 5. 验证骨架 ====

ls -la
ls apps/ packages/ tooling/

# ==== 6. 提交到子仓库 ====

git add -A
git commit -m "chore(monorepo): 初始化多端 monorepo 骨架（apps/packages/tooling + CI 配置）"

git push -u origin main
```

---

## Step 4：根仓库更新子仓库指针（我执行 / 你确认）

初始化子仓库骨架后，回到根仓库：

```bash
# 在 avmc 根仓库
git add .gitmodules mobile-desktop-service
git commit -m "chore: 注册 mobile-desktop-service 子仓库并更新指针"
git push
```

---

## Step 5：在子仓库创建首个应用（可选 / 后续）

骨架就绪后，可以开始第一个应用：

### 5.1 Flutter 应用（推荐试点）

```bash
cd mobile-desktop-service/apps

# 用 very_good_cli 创建首个 Flutter 应用
very_good create flutter_app evie_mobile \
  --description "Evie Mobile - Ark Tech Platform (Ark Product Service)" \
  --org com.stackhaven.avmc

# 复制 avmc-flutter-app skill 脚本到 evie_mobile/tool/
cd evie_mobile
mkdir -p tool
SKILL_DIR="/path/to/avmc/.agents/skills/avmc-flutter-app/scripts"
cp "$SKILL_DIR"/*.sh tool/
chmod +x tool/*.sh

# 创建首个 feature（验证脚本）
bash tool/create_feature.sh vocab

# 跑架构检查
bash tool/check_architecture.sh

# 跑 pre-commit（包含 format + analyze + test + coverage + architecture）
bash tool/pre_commit.sh
```

### 5.2 验证 API 客户端生成（可选）

```bash
# 在子仓库根
cd mobile-desktop-service

# 校验 buf CLI 已安装
buf --version

# 跑跨端客户端生成
bash tool/gen_clients.sh

# 验证生成结果
ls packages/api-client/lib/
ls packages/api-client/src/proto/
```

---

## Step 6：在 4-6 清单更新状态

完成后，告诉我，我把 4-6 清单里对应的 `[ ]` 行更新为 `[x]`：

```
| [x] | P0 | 子仓库立项 | ... |
| [x] | P1 | GitHub 仓库创建 + 子仓库注册到 .gitmodules | 已完成 |
| [x] | P1 | monorepo 顶层骨架初始化（apps/packages/tooling 目录） | 已完成 |
```

---

## 故障排查

| 现象 | 排查 |
|------|------|
| `git clone` 失败：`Permission denied (publickey)` | SSH key 未添加到 GitHub；检查 `ssh -T git@github.com` |
| `very_good create` 失败：`Kernel binary format version` | Dart SDK 与 very_good_cli 版本不匹配；`dart pub global activate very_good_cli` 重装 |
| `buf` 命令不存在 | 安装 Buf CLI：https://buf.build/docs/installation |
| `melos` 命令不存在 | `dart pub global activate melos` |
| 根仓库 `git add mobile-desktop-service` 失败 | 确认 Step 2 的 `.gitmodules` 已正确注册 |
| monorepo 子模块在根仓库显示为空目录 | 必须先在子仓库 commit + push，再在根仓库 update |

---

## 完成标志

✅ 完成本引导的全部 Step 后，你应该有：

- [x] GitHub `stack-haven/avmc-mobile-desktop-service` 仓库存在
- [x] 子仓库骨架（apps/packages/tooling/tool/.github/workflows）已 commit + push
- [x] 根仓库 `.gitmodules` 包含 mobile-desktop-service 条目
- [x] 根仓库 `mobile-desktop-service/` 目录有内容（不是空目录）
- [x] 4-6 清单对应行已更新

达到以上所有标志后，可以开始端应用开发。
