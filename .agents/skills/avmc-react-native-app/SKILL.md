---
description: |
  ⚠️ **待实战验证**：此 skill 是基础版，未经过实际 React Native 项目验证。
  首次使用 RN 在 mobile-desktop-service 开发时，Agent 必须先告知用户：
  1. skill 为基础版，可能缺少真实项目踩坑（Hermes 配置、Metro 缓存、原生模块链接）
  2. 询问是否先花 1-2 小时补充实战经验，再开始开发
  3. 详细说明见 avmc-mobile-desktop-monorepo skill 第九章

  为 Ark Tech Platform 生成基于 React Native 的移动端应用脚手架。当需要新建 RN 项目、与 backend-service 集成、iOS/Android 双端构建发布时触发。

  触发场景：
  - "创建 React Native 移动应用" / "新建 RN 项目脚手架"
  - "RN 项目怎么和后端 API 对接"
  - "iOS 和 Android 同时发布"
  - 任何需要 React Native 项目脚手架的任务

  需要用户提供的输入：产品名、目标平台、API 客户端类型（REST/gRPC-Web）、状态管理选型。
name: avmc-react-native-app
---

# Ark Tech Platform React Native 应用生成

为 Ark Tech Platform 生成标准 React Native 移动应用脚手架（iOS/Android）。

## 输入要求

| 项目 | 说明 | 示例 |
|------|------|------|
| **产品英文名** | 应用的业务归属 | `evie`、`workbench` |
| **目标平台** | iOS / Android / 两者 | `[iOS, Android]` |
| **API 类型** | 后端接口形式 | `REST/HTTP`（默认）、`gRPC-Web`（实验） |
| **状态管理** | 状态管理库选型 | `Zustand`、`Redux Toolkit`、`Jotai`（默认 Zustand） |
| **导航库** | 路由方案 | `React Navigation v6`（默认） |

## 应用脚手架位置

```
apps/
├── workbench-mobile/     # React Native 主项目
└── workbench-shared/     # 共享业务包（可选）
```

**注意：**

- React Native 通常用于纯移动端场景，桌面端用 Tauri/Electron 更合适
- 跨端共享 TypeScript 代码放 `mobile-desktop-service/packages/workbench-core/`

## 项目目录结构

```
apps/workbench-mobile/
├── src/
│   ├── app/                  # 应用入口、根组件
│   │   ├── App.tsx
│   │   └── navigation/       # 导航配置（React Navigation）
│   ├── features/             # 按业务模块组织
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   └── api.ts
│   │   ├── dashboard/
│   │   └── settings/
│   ├── shared/               # 共享 UI 组件、工具
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── theme/
│   │   └── utils/
│   ├── api/                  # API 客户端（基于 packages/api-client）
│   ├── store/                # 状态管理（Zustand stores）
│   ├── types/                # 类型定义
│   └── i18n/                 # 国际化（中英文）
├── android/                  # Android 原生工程
├── ios/                      # iOS 原生工程
├── __tests__/                # 测试
├── assets/                   # 静态资源
├── package.json              # 依赖配置
├── tsconfig.json             # TypeScript 配置
├── metro.config.js           # Metro 配置
├── babel.config.js           # Babel 配置
└── README.md                 # 构建/发布说明
```

## package.json 基线

```json
{
  "name": "workbench-mobile",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "start": "react-native start",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch",
    "build:android": "cd android && ./gradlew assembleRelease",
    "build:ios": "cd ios && xcodebuild -workspace Workbench.xcworkspace -scheme Workbench -configuration Release"
  },
  "dependencies": {
    "react": "18.2.0",
    "react-native": "0.74.x",
    "@react-navigation/native": "^6.1.x",
    "@react-navigation/native-stack": "^6.10.x",
    "@tanstack/react-query": "^5.x",
    "zustand": "^4.x",
    "axios": "^1.x",
    "react-native-keychain": "^8.x",
    "react-native-mmkv": "^2.x",
    "react-i18next": "^14.x",
    "react-native-localize": "^3.x"
  },
  "devDependencies": {
    "typescript": "5.x",
    "@types/react": "^18.x",
    "@types/react-native": "^0.73.x",
    "@types/jest": "^29.x",
    "eslint": "^8.x",
    "prettier": "^3.x",
    "jest": "^29.x",
    "@testing-library/react-native": "^12.x",
    "@testing-library/jest-native": "^5.x"
  },
  "engines": {
    "node": ">=18"
  }
}
```

## TypeScript 严格模式

```json
{
  "compilerOptions": {
    "target": "esnext",
    "module": "esnext",
    "lib": ["esnext"],
    "jsx": "react-native",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "esModuleInterop": true,
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "baseUrl": "./src",
    "paths": {
      "@/*": ["*"],
      "@app/*": ["app/*"],
      "@features/*": ["features/*"],
      "@shared/*": ["shared/*"],
      "@api/*": ["api/*"]
    }
  }
}
```

## API 集成

### REST/HTTP 客户端

```typescript
// src/api/http.ts
import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import * as Keychain from 'react-native-keychain';

const KEYCHAIN_SERVICE = 'avmc.workbench.auth';

export async function getAccessToken(): Promise<string | null> {
  const credentials = await Keychain.getGenericPassword({ service: KEYCHAIN_SERVICE });
  return credentials ? credentials.password : null;
}

export async function setAccessToken(token: string): Promise<void> {
  await Keychain.setGenericPassword('access_token', token, {
    service: KEYCHAIN_SERVICE,
  });
}

export const http: AxiosInstance = axios.create({
  baseURL: process.env.WORKBENCH_API_BASE_URL || 'https://api.avmc.example.com',
  timeout: 30_000,
});

http.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  const token = await getAccessToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

http.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // 触发 token 刷新或跳转登录
      // await refreshAuth();
      // return retryRequest(error.config);
    }
    return Promise.reject(error);
  },
);
```

### 共享 API 客户端

`apps/workbench-mobile/src/api/` 优先引用 `mobile-desktop-service/packages/api-client/` 生成的 TypeScript 客户端：

```typescript
// packages/api-client/src/evie/v1/dictionary.ts
import { request } from './base';

export namespace DictionaryApi {
  export interface ListWordsRequest {
    pageSize?: number;
    pageToken?: string;
    filter?: string;
  }

  export interface Word {
    id: string;
    name: string;
    level: number;
    createdAt: string;
  }

  export interface ListWordsResponse {
    items: Word[];
    nextPageToken?: string;
  }
}

export const dictionaryApi = {
  list: (req: DictionaryApi.ListWordsRequest) =>
    request.get<DictionaryApi.ListWordsResponse>('/evie/v1/words', { params: req }),
  get: (id: string) =>
    request.get<DictionaryApi.Word>(`/evie/v1/words/${id}`),
};
```

## 状态管理（Zustand 示例）

```typescript
// src/store/auth.ts
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { getAccessToken, setAccessToken as saveToken } from '@/api/http';

interface AuthState {
  user: User | null;
  tenantId: string | null;
  isAuthenticated: boolean;
  login: (token: string, user: User, tenantId: string) => Promise<void>;
  logout: () => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      tenantId: null,
      isAuthenticated: false,
      login: async (token, user, tenantId) => {
        await saveToken(token);
        set({ user, tenantId, isAuthenticated: true });
      },
      logout: async () => {
        await saveToken('');
        set({ user: null, tenantId: null, isAuthenticated: false });
      },
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => require('react-native-mmkv').MMKV),
    },
  ),
);
```

## 认证与多租户

- 推荐使用 `react-native-keychain` 存储 access_token / refresh_token
- JWT token 通过 axios 拦截器自动携带
- 多租户：`tenant_id` 从 token claims 提取，**不接受客户端传入**
- 平台管理员：通过 `is_platform` claim 标识

## 约束

- TypeScript strict 模式必须开启
- ESLint + Prettier 统一代码风格
- 业务逻辑放 `features/<name>/domain/`，UI 组件放 `shared/components/`
- 跨应用共享代码优先放 `mobile-desktop-service/packages/`
- iOS/Android 必须做代码混淆（ProGuard / Hermes）
- 性能：列表用 FlashList 或 RecyclerListView，不用原生 ScrollView
- 状态管理默认 Zustand，复杂场景可用 Redux Toolkit
- 路由默认 React Navigation v6

## 测试

| 类型 | 工具 | 命令 |
|------|------|------|
| 单元测试 | Jest | `npm test` |
| 组件测试 | @testing-library/react-native | `npm test -- --testPathPattern=components` |
| E2E | Detox / Maestro | `npm run e2e:ios` / `npm run e2e:android` |

CI 必跑：`npm run typecheck` + `npm run lint` + `npm test`

## 发布流程

| 平台 | 渠道 | 工具 |
|------|------|------|
| iOS | App Store | Xcode + Transporter / Fastlane |
| Android | Google Play / 国内市场 | Fastlane / 手传 |

CI/CD 配置参考：`mobile-desktop-service/tooling/ci/rn-build.yml`

## 相关文档

- 整体规范：`avmc-mobile-desktop-monorepo`
- Flutter 项目：`avmc-flutter-app`
- uni-app 项目：`avmc-uniapp-app`
