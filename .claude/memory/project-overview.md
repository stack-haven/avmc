---
name: project-overview
description: AVMC 项目基本信息和仓库结构
metadata: 
  node_type: memory
  type: project
  originSessionId: dcd0b72e-6b01-4816-8dc2-7219a28fe7f5
---

# AVMC 项目概述

AVMC (App Version Management Center) 是多项目版本控制、灰度发布和用户管理的开源平台。

## 仓库结构
- `backend-service/` — Go + go-kratos 后端（子模块，分支 `codex/ai`）
- `frontend-service/` — Vue Vben Admin pnpm monorepo（子模块，v5.5.9）
- `docs/product/` — 当前产品需求文档
- `docs/vibe-coding/` — 代码规范
- `docs/archive/` — 历史归档

## 核心功能模块
项目管理、版本管理、Release 发布、灰度发布、用户反馈、协议管理、推送通知、用户与权限管理、下载页配置、AI 辅助运营

## 当前迭代
迭代 1（基础权限与项目管理）收尾中。项目管理 MVP 前后端已完成，项目权限配置入口和成员角色待补充。

**Why:** 项目结构复杂（根仓库 + 两个子模块），需要明确活跃开发区域和文档层级。
**How to apply:** 后端改动进 `backend-service`，前端改动进 `frontend-service`，根仓库只提交文档和子模块指针。
