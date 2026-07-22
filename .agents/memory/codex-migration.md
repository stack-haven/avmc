---
name: codex-migration
description: 从 Codex 迁移到 Claude Code 的注意事项
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dcd0b72e-6b01-4816-8dc2-7219a28fe7f5
---

# Codex → Claude Code 迁移记录

## 背景
项目最初通过 Codex 开发，`.codex/` 目录下保留了完整的 Codex 规则集（RULES.md、DESIGN.md、AGENTS.md 和 3 个 Skills）。

## 已完成的迁移
2026-06-05：将 `.codex/RULES.md`、`.codex/AGENTS.md`、`.codex/DESIGN.md` 核心规则合并为 `CLAUDE.md`
Codex Skills（avmc-contract-first-backend、avmc-feature-delivery、avmc-cross-repo-review）的交付工作流逻辑已整合进 `CLAUDE.md`

## 后续参考
- Codex Skills 的详细分层逻辑在 `.codex/skills/` 中，可翻阅
- Claude Code 不读取 `.codex/`，只读取 `CLAUDE.md` 和 `.claude/` 下的配置

**Why:** 项目之前用 Codex 开发，切换 Claude Code 后 `.codex/` 格式不兼容。
**How to apply:** 遇到 Codex 遗留问题时优先查阅 `CLAUDE.md`，需要查阅 Skill 细节时翻阅 `.codex/skills/`。
