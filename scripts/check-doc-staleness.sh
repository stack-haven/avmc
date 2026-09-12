#!/usr/bin/env bash
# check-doc-staleness.sh
# 监控仓库文档漂移（聚焦"项目自有规范层"，不扫 skills 内部虚构示例）。
# 失败时 exit 1，CI 可选接入。
#
# 规则：
#   1. 活跃文档中不得出现已知过时包名/路径（platform/admin、entgo/paging、utils/pagination 等）
#   2. 活跃文档中不得再次引入 docs/vibe-coding 引用
#   3. 项目自有规范层（docs/{architecture,services,product,README,GLOSSARY,GETTING_STARTED}
#      + .agents/{AGENTS,RULES,DESIGN,REVIEW,memory,skills}）的本地 Markdown 链接必须可解析
#   4. .md 之外的文件链接（LICENSE 等）豁免
#
# 用法：./scripts/check-doc-staleness.sh （在根仓库根目录下执行）

set -euo pipefail

cd "$(dirname "$0")/.."

FAIL=0

# 1) 过时字符串扫描
echo "==> Check 1: 活跃文档不得出现已知过时路径/包名 ..."

FORBIDDEN_PATTERNS=(
  'platform/admin/cmd/server'   # 旧 CI 路径
  'app/platform/admin'           # 旧后端目录
  'pkg/entgo/paging'             # 已删除包
  'pkg/utils/pagination'         # 已删除包
  'app/avmc/admin'               # 旧目录
  'admin-antd-avmc'              # 旧 app 名
  'saas-base'                    # 旧仓库名
  '`platform/admin`'             # 旧文档术语
)

# 范围：项目自有规范层（不含 skills 内部、不含 evie/lexnorm 的开发说明）
ACTIVE_DOCS=(
  $(find docs/architecture docs/services -maxdepth 2 -name '*.md' 2>/dev/null \
    | grep -v 'docs/services/.*/development/' \
    | grep -v 'docs/services/.*/development')
  $(find docs/product -name '*.md' 2>/dev/null)
  docs/GETTING_STARTED.md docs/README.md docs/GLOSSARY.md
  .agents/AGENTS.md .agents/RULES.md .agents/DESIGN.md .agents/REVIEW.md
  $(find .agents/memory -name '*.md' 2>/dev/null)
  README.md CLAUDE.md CONTRIBUTING.md
)

for pat in "${FORBIDDEN_PATTERNS[@]}"; do
  # 豁免：4-7（机器扫描产物含历史代码追溯）+ ADR 索引（“原 platform/admin”专属标记）+
  #        含“已废弃/已于”提示符的说明性行
  hits=$(grep -rEn "$pat" "${ACTIVE_DOCS[@]}" 2>/dev/null \
    | grep -v '/archive/' \
    | grep -v 'docs/architecture/4-6-治理-开发功能清单.md' \
    | grep -v 'docs/architecture/4-7-治理-代码功能清单.md' \
    | grep -vE '原 `?platform/admin`?|已废弃|已于' \
    || true)
  if [ -n "$hits" ]; then
    echo "❌ forbidden pattern '$pat' found:"
    echo "$hits"
    FAIL=1
  fi
done
echo "   ok"

# 2) 活跃文档不得再次引入 vibe-coding 引用
echo "==> Check 2: 活跃文档不得引入 docs/vibe-coding 引用 ..."
# 豁免 4-6 变更记录：事件描述中出现历史名称是设计预期
hits=$(grep -rEn 'docs/vibe-coding/' "${ACTIVE_DOCS[@]}" 2>/dev/null \
  | grep -v '/archive/' \
  | grep -v 'docs/architecture/4-6-治理-开发功能清单.md' \
  | grep -vE '已于|已删除' \
  || true)
if [ -n "$hits" ]; then
  echo "❌ 'docs/vibe-coding/' referenced in active docs:"
  echo "$hits"
  FAIL=1
else
  echo "   ok"
fi

# 3) 本地 Markdown 链接完整性
echo "==> Check 3: 项目自有规范层本地 Markdown 链接必须存在 ..."

# 真实解析相对路径
resolve_link() {
  local f="$1" link="$2"
  # 去掉锚点 + query
  local pure="${link%%#*}"
  pure="${pure%%\?*}"
  [ -z "$pure" ] && return
  # 跳过协议链接
  case "$pure" in
    http*|https*|mailto:*) return ;;
  esac
  # 跳过非 .md 文件（LICENSE、PNG 等资源文件）
  case "$pure" in
    *.md) ;;
    *) return ;;
  esac
  local base dir target
  base="$(cd "$(dirname "$f")" && pwd)"
  dir="$(dirname "$base/$pure")"
  target="$(cd "$dir" 2>/dev/null && pwd)/$(basename "$pure")"
  if [ ! -e "$target" ]; then
    echo "  ❌ $f → $link"
  fi
}

link_fail=0
for f in "${ACTIVE_DOCS[@]}"; do
  [ -f "$f" ] || continue
  while IFS= read -r link; do
    out=$(resolve_link "$f" "$link")
    if [ -n "$out" ]; then
      echo "$out"
      link_fail=1
      FAIL=1
    fi
  done < <(grep -oE '\]\(([^)]+)\)' "$f" 2>/dev/null \
    | sed -E 's/^\]\(//; s/\)$//')
done
if [ $link_fail -eq 0 ]; then
  echo "   ok"
fi

if [ $FAIL -eq 1 ]; then
  echo
  echo "❌ Doc staleness check failed."
  exit 1
fi
echo
echo "✅ Doc staleness check passed."
