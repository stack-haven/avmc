---
description: |
  ⚠️ **待实战验证**：此 skill 是基础版，未经过实际 uni-app 项目验证。
  首次使用 uni-app 在 mobile-desktop-service 开发时，Agent 必须先告知用户：
  1. skill 为基础版，可能缺少真实项目踩坑（HBuilderX 与 CLI 冲突、小程序平台差异、App 打包体积优化）
  2. 询问是否先花 1-2 小时补充实战经验，再开始开发
  3. 详细说明见 avmc-mobile-desktop-monorepo skill 第九章

  为 Ark Tech Platform 生成基于 uni-app 的多端应用脚手架。当需要新建 uni-app 项目、App + 小程序双产物构建发布时触发。

  触发场景：
  - "创建 uni-app 项目" / "新建小程序项目"
  - "uni-app 同时发布 App 和微信小程序"
  - "HBuilderX 项目怎么组织"
  - 任何需要 uni-app 项目脚手架的任务

  需要用户提供的输入：产品名、目标平台（App + 小程序矩阵）、UI 框架（uv-ui/uView）、构建方式。
name: avmc-uniapp-app
---

# Ark Tech Platform uni-app 应用生成

为 Ark Tech Platform 生成标准 uni-app 项目脚手架，支持 App（iOS/Android）+ 小程序（微信/支付宝/抖音/百度）多端产物。

## 输入要求

| 项目 | 说明 | 示例 |
|------|------|------|
| **产品英文名** | 应用的业务归属 | `geo`、`evie` |
| **目标平台矩阵** | 要发布的 App + 小程序端 | `App + 微信小程序 + 抖音小程序` |
| **UI 框架** | uni-app UI 库选型 | `uv-ui`、`uView 2.0`、`uni-ui`（默认 uv-ui） |
| **构建方式** | HBuilderX 可视化 / CLI | `Vue 3 + Vite + CLI`（默认） |
| **状态管理** | 状态管理库选型 | `Pinia`（推荐）、Vuex |

## 应用脚手架位置

```
apps/
├── geo-mobile/    # uni-app，iOS/Android App 产物
└── geo-mini/      # uni-app，微信/支付宝/抖音/百度小程序产物
```

**同源码多产物原则：**

- `apps/geo-mobile/` 和 `apps/geo-mini/` 共享同一份 `src/` 业务代码
- 通过 `manifest.json` 配置和条件编译（`#ifdef MP-WEIXIN` 等）区分平台
- 推荐组织方式：单项目 + HBuilderX 多发行，或拆为两个项目共享 `packages/geo-core/`

## 项目目录结构

```
apps/geo-mobile/
├── src/
│   ├── pages/                # 页面（按业务模块组织）
│   │   ├── index/
│   │   │   └── index.vue
│   │   ├── auth/
│   │   │   ├── login.vue
│   │   │   └── register.vue
│   │   ├── content/
│   │   │   ├── list.vue
│   │   │   └── detail.vue
│   │   └── profile/
│   ├── components/           # 公共组件
│   │   ├── empty-state/
│   │   ├── error-boundary/
│   │   └── loading-skeleton/
│   ├── api/                  # API 客户端
│   ├── store/                # 状态管理（Pinia）
│   ├── utils/                # 工具函数
│   ├── static/               # 静态资源（图片、字体）
│   ├── locales/              # 国际化文案
│   │   ├── zh-CN.json
│   │   └── en-US.json
│   ├── App.vue               # 应用配置
│   ├── main.ts               # 入口
│   ├── manifest.json         # 应用配置（AppID、版本、平台）
│   ├── pages.json            # 页面路由
│   └── uni.scss              # 全局样式变量
├── unpackage/                # 编译产物（gitignore）
├── node_modules/
├── package.json
└── README.md
```

## package.json 基线

```json
{
  "name": "geo-mobile",
  "version": "1.0.0",
  "description": "GEO Engine 多端应用（Ark Tech Platform）",
  "scripts": {
    "dev:h5": "uni",
    "dev:mp-weixin": "uni -p mp-weixin",
    "dev:app": "uni -p app",
    "build:h5": "uni build",
    "build:mp-weixin": "uni build -p mp-weixin",
    "build:mp-toutiao": "uni build -p mp-toutiao",
    "build:app": "uni build -p app",
    "typecheck": "vue-tsc --noEmit",
    "lint": "eslint . --ext .vue,.ts,.js",
    "test": "vitest"
  },
  "dependencies": {
    "@dcloudio/uni-app": "3.0.0-4000020241225001",
    "@dcloudio/uni-app-plus": "3.0.0-4000020241225001",
    "@dcloudio/uni-components": "3.0.0-4000020241225001",
    "vue": "^3.4.0",
    "pinia": "^2.1.7",
    "vue-i18n": "^9.1.9",
    "uv-ui": "^1.0.0"
  },
  "devDependencies": {
    "@dcloudio/types": "^3.4.8",
    "@dcloudio/uni-automator": "3.0.0-4000020241225001",
    "@dcloudio/vite-plugin-uni": "3.0.0-4000020241225001",
    "typescript": "^5.3.0",
    "vue-tsc": "^1.8.27",
    "eslint": "^8.57.0",
    "prettier": "^3.2.0",
    "vitest": "^1.6.0",
    "@vue/test-utils": "^2.4.0"
  }
}
```

## manifest.json 平台配置

```json
{
  "name": "GEO Engine",
  "appid": "__UNI__XXXXXXX",
  "description": "GEO 内容工程平台",
  "versionName": "1.0.0",
  "versionCode": "100",
  "transformPx": false,
  "app-plus": {
    "usingComponents": true,
    "nvueStyleCompiler": "uni-app",
    "compilerVersion": 3,
    "splashscreen": {
      "alwaysShowBeforeRender": true,
      "waiting": true,
      "autoclose": true,
      "delay": 0
    },
    "modules": {},
    "distribute": {
      "android": {
        "permissions": [
          "<uses-permission android:name=\"android.permission.INTERNET\"/>"
        ],
        "abiFilters": ["armeabi-v7a", "arm64-v8a"]
      },
      "ios": {
        "dSYMs": false,
        "privacyDescription": {
          "NSPhotoLibraryUsageDescription": "需要访问相册以上传图片",
          "NSMicrophoneUsageDescription": "需要访问麦克风以录制语音"
        }
      }
    }
  },
  "quickapp": {},
  "mp-weixin": {
    "appid": "wxXXXXXXXXXXXXXXXX",
    "setting": {
      "urlCheck": false,
      "es6": true,
      "postcss": true,
      "minified": true
    },
    "usingComponents": true,
    "permission": {
      "scope.userLocation": { "desc": "用于显示附近的内容" }
    }
  },
  "mp-toutiao": {
    "appid": "ttXXXXXXXXXXXXXXXX",
    "setting": { "urlCheck": false }
  },
  "mp-alipay": {
    "usingComponents": true
  },
  "mp-baidu": {
    "usingComponents": true
  },
  "h5": {
    "title": "GEO Engine",
    "router": { "mode": "history", "base": "/" },
    "devServer": {
      "https": false,
      "port": 8080
    }
  },
  "vueVersion": "3"
}
```

## 条件编译模式

uni-app 通过 `#ifdef` / `#endif` 注释区分平台代码：

```vue
<template>
  <view class="container">
    <!-- #ifdef MP-WEIXIN -->
    <button open-type="getUserInfo" @click="onWeixinLogin">微信登录</button>
    <!-- #endif -->

    <!-- #ifdef APP-PLUS -->
    <button @click="onNativeLogin">一键登录</button>
    <!-- #endif -->

    <!-- #ifdef H5 -->
    <navigator url="/web/login">H5 登录</navigator>
    <!-- #endif -->
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const userInfo = ref(null);

async function onWeixinLogin() {
  // #ifdef MP-WEIXIN
  const res = await uni.login({ provider: 'weixin' });
  await authApi.loginByCode(res.code);
  // #endif
}

async function onNativeLogin() {
  // #ifdef APP-PLUS
  uni.login({
    provider: 'univerify',
    univerifyStyle: { fullScreen: true },
    success: async (res) => {
      await authApi.loginByPhone(res.authResult.phone);
    },
  });
  // #endif
}
</script>
```

支持的平台标识：

| 标识 | 平台 |
|------|------|
| `APP-PLUS` | App（iOS/Android） |
| `MP-WEIXIN` | 微信小程序 |
| `MP-TOUTIAO` | 抖音小程序 |
| `MP-ALIPAY` | 支付宝小程序 |
| `MP-BAIDU` | 百度小程序 |
| `H5` | H5 |
| `MP` | 所有小程序 |

## API 集成

```typescript
// src/api/http.ts
import { getAccessToken } from '@/utils/auth';

const BASE_URL = 'https://api.avmc.example.com';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export async function request<T>(options: UniApp.RequestOptions): Promise<T> {
  const token = getAccessToken();
  return new Promise<T>((resolve, reject) => {
    uni.request({
      ...options,
      url: options.url.startsWith('http') ? options.url : `${BASE_URL}${options.url}`,
      header: {
        ...options.header,
        Authorization: token ? `Bearer ${token}` : '',
      },
      success: (res) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(res.data as T);
        } else if (res.statusCode === 401) {
          uni.showToast({ title: '请重新登录', icon: 'none' });
          uni.reLaunch({ url: '/pages/auth/login' });
          reject(res);
        } else {
          uni.showToast({ title: (res.data as any)?.message ?? '请求失败', icon: 'none' });
          reject(res);
        }
      },
      fail: (err) => {
        uni.showToast({ title: '网络异常', icon: 'none' });
        reject(err);
      },
    });
  });
}
```

## 状态管理（Pinia 示例）

```typescript
// src/store/auth.ts
import { defineStore } from 'pinia';

interface UserInfo {
  id: string;
  name: string;
  tenantId: string;
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null as UserInfo | null,
    accessToken: '' as string,
    tenantId: '' as string,
  }),

  getters: {
    isAuthenticated: (state) => !!state.accessToken,
    isPlatformAdmin: (state) => state.user?.isPlatform === true,
  },

  actions: {
    setAuth(user: UserInfo, token: string) {
      this.user = user;
      this.accessToken = token;
      this.tenantId = user.tenantId;
      uni.setStorageSync('access_token', token);
    },

    clearAuth() {
      this.user = null;
      this.accessToken = '';
      this.tenantId = '';
      uni.removeStorageSync('access_token');
    },
  },
});
```

## 认证与多租户

- token 存储：`uni.setStorageSync('access_token', token)`
- 多租户：`tenant_id` 从 token claims 提取，**不接受客户端传入**
- 小程序登录：调用 `uni.login` + 后端 `/platform/v1/auth/login-by-code` 换取 JWT
- App 登录：使用 `uni.login({ provider: 'univerify' })` 一键登录或手机号验证码

## 约束

- 页面文件名使用 kebab-case（如 `word-detail.vue`）
- 业务逻辑放 `src/store/` 或 `src/composables/`，不在页面内直接写业务
- 跨应用共享代码优先放 `mobile-desktop-service/packages/`
- **小程序包体积限制**：主包 ≤ 2MB，单包 ≤ 2MB；超出必须分包
- App 端必须做代码混淆（manifest.json 配置 + 原生工程 ProGuard）
- UI 风格统一：参考 Ark Design System（如有）
- 文案必须 i18n（`zh-CN.json` + `en-US.json`），禁止硬编码中文
- 状态管理默认 Pinia

## 测试

| 类型 | 工具 | 命令 |
|------|------|------|
| 单元测试 | Vitest | `npm test` |
| 组件测试 | @vue/test-utils | `npm test -- --testPathPattern=components` |
| 真机调试 | HBuilderX | 运行 → 真机/模拟器 |
| 多端调试 | 各小程序开发者工具 | 同步运行 |

CI 必跑：`npm run typecheck` + `npm run lint` + `npm test`

## 发布流程

| 平台 | 渠道 | 工具 |
|------|------|------|
| iOS App | App Store | HBuilderX → 云打包 / Xcode 本地打包 |
| Android App | Google Play / 国内市场 | HBuilderX → 云打包 / 本地打包 |
| 微信小程序 | 微信开放平台 | 微信开发者工具上传 |
| 抖音小程序 | 抖音开放平台 | 抖音开发者工具上传 |
| 支付宝小程序 | 支付宝开放平台 | 小程序开发者工具 |
| 百度小程序 | 百度开放平台 | 百度开发者工具 |
| H5 | 部署到 CDN | `npm run build:h5` |

CI/CD 配置参考：`mobile-desktop-service/tooling/ci/uniapp-build.yml`

## 相关文档

- 整体规范：`avmc-mobile-desktop-monorepo`
- Flutter 项目：`avmc-flutter-app`
- React Native 项目：`avmc-react-native-app`
