---
name: tech-stack
description: AVMC 技术栈和工具链
metadata: 
  node_type: memory
  type: reference
  originSessionId: dcd0b72e-6b01-4816-8dc2-7219a28fe7f5
---

# 技术栈

**后端:** Go + go-kratos v2 + Protobuf + gRPC + HTTP + Buf + Ent + Wire
**前端:** Vue 3 + TypeScript + Vben Admin + Ant Design Vue + Pinia + Vite + pnpm
**数据库:** MySQL / PostgreSQL
**缓存:** Redis（可选）
**认证:** JWT + Casbin

## 关键版本
- Go 1.18+
- Node.js >=20.19.0
- pnpm >=10.0.0（packageManager: pnpm@10.28.1）
- 后端模块路径: `backend-service`
- 前端主应用包名: `@vben/admin-antd-avmc`

## 开发语言
- 项目中英文混用，说明优先中文，路径/代码保持英文
- 前端新增文案同时补 `zh-CN` 和 `en-US` locale
