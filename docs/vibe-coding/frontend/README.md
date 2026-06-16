# 前端 Vibe Coding 实践指南

> Vue 3 + TypeScript + Vben Admin 开发规范与最佳实践

## 📋 文档概述

本指南基于 Vibe Coding 基础规范，针对项目开发底座及其项目服务的前端开发提供详细的实践指导。主要涵盖：

- **Vue 3 + TypeScript 开发规范**
- **Vben Admin 框架使用最佳实践**
- **组件开发与复用策略**
- **状态管理与路由配置**
- **API 调用与错误处理**
- **样式与国际化规范**
- **性能优化与代码质量**

## 当前实现基线

- 当前 `frontend-service/apps/admin-antd-avmc` 暂作为底座管理后台前端，包名仍为 `@vben/admin-antd-avmc`，是否改名另行确认。
- `web-antd`、`web-ele`、`web-naive`、`web-tdesign` 和 `playground` 主要作为 Vben 示例或参考，除非任务明确指定，否则不要作为业务实现目标。
- Node.js 要求 `>=20.19.0`，pnpm 要求 `>=10.0.0`，仓库 packageManager 为 `pnpm@10.28.1`。
- 业务页面优先使用现有 `Page + useVbenVxeGrid + useVbenDrawer + useVbenForm` 模式。

## 🎯 技术栈

- **框架**：Vue 3 + TypeScript
- **构建工具**：Vite
- **UI 框架**：
  - Ant Design Vue（admin-antd-avmc）
  - Element Plus（web-ele）
  - Naive UI（web-naive）
  - TDesign（web-tdesign）
- **状态管理**：Pinia
- **路由**：Vue Router
- **HTTP 客户端**：`@vben/request`（底层请求封装，当前 app 通过 `#/api/request` 使用）
- **样式**：Tailwind CSS / Vben 样式体系，按当前 app 和组件库既有写法使用
- **国际化**：i18n

## 📁 前端项目结构

```
frontend-service/apps/admin-antd-avmc/
├── public/              # 静态资源
├── src/                 # 源代码
│   ├── adapter/         # 适配器
│   │   ├── component/   # 组件适配器
│   │   ├── form.ts      # 表单适配器
│   │   └── vxe-table.ts # 表格适配器
│   ├── api/             # API 调用
│   │   ├── core/        # 核心 API
│   │   ├── system/      # 系统 API
│   │   ├── type/        # 类型定义
│   │   ├── index.ts     # API 入口
│   │   └── request.ts   # 请求配置
│   ├── layouts/         # 布局组件
│   │   ├── auth.vue     # 认证布局
│   │   ├── basic.vue    # 基础布局
│   │   └── index.ts     # 布局导出
│   ├── locales/         # 国际化
│   │   ├── langs/       # 语言包
│   │   ├── README.md    # 国际化说明
│   │   └── index.ts     # 国际化配置
│   ├── router/          # 路由配置
│   │   ├── routes/      # 路由定义
│   │   ├── access.ts    # 权限控制
│   │   ├── guard.ts     # 路由守卫
│   │   └── index.ts     # 路由配置
│   ├── store/           # 状态管理
│   │   ├── auth.ts      # 认证状态
│   │   └── index.ts     # 状态管理配置
│   ├── views/           # 页面组件
│   │   ├── _core/       # 核心页面
│   │   ├── dashboard/   # 仪表盘
│   │   ├── demos/       # 示例
│   │   └── system/      # 系统管理
│   ├── app.vue          # 根组件
│   ├── bootstrap.ts     # 启动配置
│   ├── main.ts          # 入口文件
│   └── preferences.ts   # 偏好设置
├── .env                 # 环境配置
├── .env.development     # 开发环境配置
├── .env.production      # 生产环境配置
├── index.html           # HTML 模板
├── package.json         # 项目配置
├── tsconfig.json        # TypeScript 配置
└── vite.config.mts      # Vite 配置
```

## 🎨 Vue 3 + TypeScript 开发规范

### 1. 组件开发规范

#### 1.1 组件命名

- **组件名**：使用 PascalCase，多单词组合
  ```vue
  <!-- ✅ 推荐 -->
  <template>
    <UserProfile />
    <LoginForm />
  </template>
  
  <!-- ❌ 不推荐 -->
  <template>
    <user-profile />
    <login_form />
  </template>
  ```

- **文件名**：使用 kebab-case，与组件名对应
  ```
  <!-- ✅ 推荐 -->
  user-profile.vue
  login-form.vue
  
  <!-- ❌ 不推荐 -->
  UserProfile.vue
  loginForm.vue
  ```

#### 1.2 组件结构

- **单文件组件结构**：
  ```vue
  <template>
    <!-- 模板内容 -->
  </template>
  
  <script setup lang="ts">
  // 组件逻辑
  </script>
  
  <style scoped>
  /* 组件样式 */
  </style>
  ```

- **组合式 API**：优先使用 `<script setup>`
  ```vue
  <script setup lang="ts">
  import { ref, computed } from 'vue';
  
  // 响应式数据
  const count = ref(0);
  
  // 计算属性
  const doubled = computed(() => count.value * 2);
  
  // 方法
  function increment() {
    count.value++;
  }
  </script>
  ```

#### 1.3 组件 props

- **类型定义**：使用 TypeScript 接口定义 props
  ```vue
  <script setup lang="ts">
  interface Props {
    title: string;
    count?: number;
    disabled: boolean;
  }
  
  const props = withDefaults(defineProps<Props>(), {
    count: 0,
  });
  </script>
  ```

- **props 命名**：使用 camelCase
  ```vue
  <!-- ✅ 推荐 -->
  <UserProfile user-name="John" :user-age="25" />
  
  <!-- ❌ 不推荐 -->
  <UserProfile userName="John" :userAge="25" />
  ```

#### 1.4 组件事件

- **事件命名**：使用 kebab-case，小写字母加短横线
  ```vue
  <!-- ✅ 推荐 -->
  <LoginForm @login-success="handleLoginSuccess" @form-submit="handleFormSubmit" />
  
  <!-- ❌ 不推荐 -->
  <LoginForm @loginSuccess="handleLoginSuccess" @formSubmit="handleFormSubmit" />
  ```

- **事件定义**：使用 `defineEmits`
  ```vue
  <script setup lang="ts">
  const emit = defineEmits<{
    (e: 'login-success', user: User): void;
    (e: 'form-submit', data: FormData): void;
  }>();
  
  function handleSubmit(user: User) {
    emit('login-success', user);
  }
  </script>
  ```

### 2. TypeScript 规范

#### 2.1 类型定义

- **接口命名**：使用 PascalCase，以 `I` 开头（可选）
  ```typescript
  // ✅ 推荐
  interface User {
    id: number;
    name: string;
    age: number;
  }
  
  // 或
  interface IUser {
    id: number;
    name: string;
    age: number;
  }
  ```

- **类型别名**：使用 PascalCase
  ```typescript
  // ✅ 推荐
  type UserId = number;
  type UserList = User[];
  ```

- **枚举命名**：使用 PascalCase，成员使用全大写
  ```typescript
  // ✅ 推荐
  enum UserRole {
    ADMIN = 'admin',
    USER = 'user',
    GUEST = 'guest',
  }
  ```

#### 2.2 类型使用

- **避免 `any`**：尽量使用具体类型，避免使用 `any`
  ```typescript
  // ✅ 推荐
  function processUser(user: User): void {
    // ...
  }
  
  // ❌ 不推荐
  function processUser(user: any): void {
    // ...
  }
  ```

- **可选链**：使用可选链操作符 `?.` 处理可能为 null/undefined 的值
  ```typescript
  // ✅ 推荐
  const userName = user?.name || 'Unknown';
  
  // ❌ 不推荐
  const userName = user && user.name ? user.name : 'Unknown';
  ```

- **空值合并**：使用空值合并操作符 `??` 处理默认值
  ```typescript
  // ✅ 推荐
  const count = user?.count ?? 0;
  
  // ❌ 不推荐
  const count = user?.count || 0; // 注意：0 会被视为 falsy
  ```

### 3. Vben Admin 框架使用规范

#### 3.1 目录结构

- **遵循 Vben Admin 推荐结构**：
  - `src/views/`：页面组件
  - `src/components/`：公共组件
  - `src/stores/`：状态管理
  - `src/router/`：路由配置
  - `src/api/`：API 调用
  - `src/utils/`：工具函数
  - `src/styles/`：全局样式

#### 3.2 布局使用

- **基础布局**：使用 `src/layouts/basic.vue`
  - 包含侧边栏、顶部导航、面包屑等
  - 支持响应式布局

- **认证布局**：使用 `src/layouts/auth.vue`
  - 用于登录、注册等认证页面
  - 简洁的居中布局

#### 3.3 组件使用

- **优先使用 Vben 内置组件**：
  - `VbenForm`：表单组件
  - `VbenTable`：表格组件
  - `VbenModal`：弹窗组件
  - `VbenDrawer`：抽屉组件
  - `VbenAlert`：提示组件

- **组件导入**：
  ```typescript
  // ✅ 推荐
  import { VbenForm, VbenTable } from '@vben/common-ui';
  
  // 或
  import { useVbenForm } from '@vben/hooks';
  ```

### 4. 状态管理规范

#### 4.1 Pinia 配置

- **store 文件命名**：使用 kebab-case
  ```
  // ✅ 推荐
  src/store/auth.ts
  src/store/user.ts
  
  // ❌ 不推荐
  src/store/Auth.ts
  src/store/userStore.ts
  ```

- **store 定义**：
  ```typescript
  // src/store/auth.ts
  import { defineStore } from 'pinia';
  
  export const useAuthStore = defineStore('auth', {
    state: () => ({
      token: '',
      userInfo: null as UserInfo | null,
      isLoggedIn: false,
    }),
    
    getters: {
      getToken(): string {
        return this.token;
      },
      
      getUserInfo(): UserInfo | null {
        return this.userInfo;
      },
    },
    
    actions: {
      setToken(token: string) {
        this.token = token;
        this.isLoggedIn = true;
      },
      
      setUserInfo(userInfo: UserInfo) {
        this.userInfo = userInfo;
      },
      
      logout() {
        this.token = '';
        this.userInfo = null;
        this.isLoggedIn = false;
      },
    },
  });
  ```

#### 4.2 状态管理最佳实践

- **单一数据源**：避免重复状态
- **模块化**：按功能划分 store
- **持久化**：使用 `pinia-plugin-persistedstate` 持久化关键状态
- **异步操作**：在 actions 中处理异步操作
- **状态更新**：使用 actions 更新状态，避免直接修改

### 5. 路由配置规范

#### 5.1 路由文件结构

- **路由模块**：按功能划分路由模块
  ```
  src/router/routes/
  ├── modules/
  │   ├── dashboard.ts     # 仪表盘路由
  │   ├── system.ts        # 系统管理路由
  │   └── vben.ts          # Vben 示例路由
  ├── core.ts              # 核心路由
  └── index.ts             # 路由导出
  ```

#### 5.2 路由定义

- **路由配置**：
  ```typescript
  // src/router/routes/modules/dashboard.ts
  import type { AppRouteRecordRaw } from '@/router/types';
  
  const dashboardRoutes: AppRouteRecordRaw[] = [
    {
      path: '/dashboard',
      name: 'Dashboard',
      component: () => import('@/views/dashboard/analytics/index.vue'),
      meta: {
        title: '仪表盘',
        icon: 'bx:bx-home',
        order: 1,
      },
      children: [
        {
          path: 'analytics',
          name: 'Analytics',
          component: () => import('@/views/dashboard/analytics/index.vue'),
          meta: {
            title: '数据分析',
          },
        },
        {
          path: 'workspace',
          name: 'Workspace',
          component: () => import('@/views/dashboard/workspace/index.vue'),
          meta: {
            title: '工作空间',
          },
        },
      ],
    },
  ];
  
  export default dashboardRoutes;
  ```

#### 5.3 路由守卫

- **全局守卫**：在 `src/router/guard.ts` 中配置
  - 认证守卫：检查用户登录状态
  - 权限守卫：检查用户权限
  - 标题守卫：设置页面标题

- **路由元信息**：
  ```typescript
  meta: {
    title: '用户管理',         // 页面标题
    icon: 'bx:bx-user',       // 菜单图标
    requiresAuth: true,       // 需要认证
    roles: ['admin', 'user'], // 所需角色
    order: 3,                 // 菜单排序
  }
  ```

### 6. API 调用规范

#### 6.1 API 文件结构

- **API 模块**：按功能划分 API 模块
  ```
  src/api/
  ├── core/                # 核心 API
  │   ├── auth.ts          # 认证相关
  │   ├── user.ts          # 用户相关
  │   └── menu.ts          # 菜单相关
  ├── system/              # 系统 API
  │   ├── dept.ts          # 部门相关
  │   ├── role.ts          # 角色相关
  │   └── user.ts          # 系统用户相关
  ├── request.ts           # 请求配置
  └── index.ts             # API 导出
  ```

#### 6.2 API 定义

- **API 函数命名**：使用 camelCase，动词 + 名词
  ```typescript
  // src/api/core/auth.ts
  import { request } from '../request';
  
  export const authApi = {
    // 登录
    login: (data: LoginParams) => {
      return request.post<LoginResult>('/auth/login', data);
    },
    
    // 登出
    logout: () => {
      return request.post('/auth/logout');
    },
    
    // 刷新 token
    refreshToken: (data: { refreshToken: string }) => {
      return request.post<{ token: string }>('/auth/refresh', data);
    },
  };
  ```

#### 6.3 请求配置

- **Axios 配置**：在 `src/api/request.ts` 中配置
  - 基础 URL
  - 请求拦截器：添加 token、请求时间等
  - 响应拦截器：统一错误处理、响应格式化等
  - 超时设置
  - 重试机制

- **错误处理**：统一的错误处理函数
  ```typescript
  // src/api/request.ts
  import axios from 'axios';
  import { useAuthStore } from '@/store/auth';
  
  const request = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL,
    timeout: 10000,
  });
  
  // 请求拦截器
  request.interceptors.request.use(
    (config) => {
      const authStore = useAuthStore();
      const token = authStore.getToken;
      
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );
  
  // 响应拦截器
  request.interceptors.response.use(
    (response) => {
      const { data } = response;
      
      if (data.code !== 200) {
        // 处理错误
        ElMessage.error(data.msg || '请求失败');
        return Promise.reject(data);
      }
      
      return data;
    },
    (error) => {
      // 处理网络错误
      ElMessage.error(error.message || '网络错误');
      return Promise.reject(error);
    }
  );
  ```

### 7. 样式规范

#### 7.1 样式文件结构

- **全局样式**：`src/styles/`
  - `index.less`：主样式文件
  - `variables.less`：变量定义
  - `mixins.less`：混合器

- **组件样式**：
  - 使用 `<style scoped>` 或 CSS Modules
  - 避免使用全局样式污染

#### 7.2 命名规范

- **BEM 命名**：使用 BEM 命名规范
  ```css
  /* ✅ 推荐 */
  .user-card {
    /* 块 */
  }
  
  .user-card__header {
    /* 元素 */
  }
  
  .user-card--disabled {
    /* 修饰符 */
  }
  ```

- **Tailwind CSS**：使用 Tailwind CSS 类名
  ```vue
  <!-- ✅ 推荐 -->
  <div class="flex items-center justify-between p-4 bg-white rounded-lg shadow-md">
    <h2 class="text-xl font-bold text-gray-800">用户信息</h2>
    <button class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
      编辑
    </button>
  </div>
  ```

#### 7.3 样式最佳实践

- **响应式设计**：使用 Tailwind 的响应式类或媒体查询
- **主题支持**：使用 Vben 的主题系统
- **避免 !important**：尽量避免使用 `!important`
- **性能优化**：避免过度使用复杂的选择器
- **可读性**：保持样式代码的整洁和可读性

### 8. 国际化规范

#### 8.1 语言包结构

- **语言文件**：
  ```
  src/locales/langs/
  ├── en-US/
  │   ├── base.json        # 基础语言
  │   ├── system.json      # 系统模块
  │   └── page.json        # 页面语言
  └── zh-CN/
      ├── base.json        # 基础语言
      ├── system.json      # 系统模块
      └── page.json        # 页面语言
  ```

#### 8.2 语言包使用

- **JSON 格式**：
  ```json
  {
    "common": {
      "confirm": "确认",
      "cancel": "取消",
      "save": "保存",
      "delete": "删除"
    },
    "system": {
      "user": {
        "name": "用户名",
        "email": "邮箱",
        "phone": "电话"
      }
    }
  }
  ```

- **在组件中使用**：
  ```vue
  <template>
    <div>
      <h1>{{ $t('system.user.name') }}</h1>
      <button>{{ $t('common.save') }}</button>
    </div>
  </template>
  
  <script setup lang="ts">
  import { useI18n } from 'vue-i18n';
  
  const { t } = useI18n();
  
  function handleClick() {
    console.log(t('common.confirm'));
  }
  </script>
  ```

### 9. 性能优化建议

#### 9.1 代码优化

- **组件懒加载**：
  ```typescript
  // ✅ 推荐
  const UserList = () => import('@/views/system/user/list.vue');
  ```

- **路由懒加载**：
  ```typescript
  // ✅ 推荐
  {
    path: '/user',
    name: 'User',
    component: () => import('@/views/system/user/list.vue'),
  }
  ```

- **图片懒加载**：使用 `v-lazy` 指令
  ```vue
  <img v-lazy="user.avatar" alt="用户头像" />
  ```

#### 9.2 渲染优化

- **虚拟滚动**：使用 `VbenTable` 的虚拟滚动功能
  ```typescript
  const tableProps = {
    useVirtual: true,
    virtualConfig: {
      itemHeight: 50,
    },
  };
  ```

- **计算属性缓存**：使用 `computed` 缓存计算结果
  ```typescript
  const userList = computed(() => {
    return users.value.filter(user => user.status === 'active');
  });
  ```

- **避免不必要的重渲染**：
  - 使用 `shallowRef` 和 `shallowReactive` 处理大对象
  - 使用 `memo` 缓存组件
  - 合理使用 `v-memo` 指令

#### 9.3 网络优化

- **请求缓存**：缓存频繁请求的数据
- **批量请求**：合并多个请求
- **防抖和节流**：
  ```typescript
  import { useDebounceFn, useThrottleFn } from '@vueuse/core';
  
  const handleSearch = useDebounceFn((keyword: string) => {
    // 搜索逻辑
  }, 300);
  
  const handleScroll = useThrottleFn(() => {
    // 滚动逻辑
  }, 100);
  ```

### 10. 代码示例

#### 10.1 基础组件示例

```vue
<!-- src/views/system/user/modules/form.vue -->
<template>
  <VbenForm
    :schema="schema"
    :model="formModel"
    :disabled="disabled"
    @submit="handleSubmit"
  >
    <template #footer>
      <div class="flex justify-end gap-2">
        <VbenButton @click="handleCancel">
          {{ $t('common.cancel') }}
        </VbenButton>
        <VbenButton type="primary" @click="handleSubmit">
          {{ $t('common.save') }}
        </VbenButton>
      </div>
    </template>
  </VbenForm>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { VbenForm, VbenButton } from '@vben/common-ui';
import type { FormSchema } from '@vben/types';

interface Props {
  modelValue?: any;
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => ({}),
  disabled: false,
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: any): void;
  (e: 'submit', value: any): void;
  (e: 'cancel'): void;
}>();

const formModel = ref({ ...props.modelValue });

const schema = computed<FormSchema[]>(() => [
  {
    field: 'username',
    component: 'Input',
    label: '用户名',
    rules: [
      { required: true, message: '请输入用户名' },
      { min: 3, max: 20, message: '用户名长度在 3-20 之间' },
    ],
  },
  {
    field: 'email',
    component: 'Input',
    label: '邮箱',
    rules: [
      { required: true, message: '请输入邮箱' },
      { type: 'email', message: '请输入正确的邮箱格式' },
    ],
  },
  {
    field: 'phone',
    component: 'Input',
    label: '电话',
    rules: [
      { required: true, message: '请输入电话' },
      { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号' },
    ],
  },
  {
    field: 'status',
    component: 'Switch',
    label: '状态',
    defaultValue: true,
  },
]);

function handleSubmit() {
  emit('submit', formModel.value);
}

function handleCancel() {
  emit('cancel');
}
</script>
```

#### 10.2 API 调用示例

```typescript
// src/api/system/user.ts
import { request } from '../request';
import type { User, UserListParams, UserListResult } from './type';

export const userApi = {
  // 获取用户列表
  getUserList: (params: UserListParams) => {
    return request.get<UserListResult>('/system/user/list', { params });
  },
  
  // 获取用户详情
  getUserInfo: (id: number) => {
    return request.get<User>(`/system/user/${id}`);
  },
  
  // 创建用户
  createUser: (data: Omit<User, 'id'>) => {
    return request.post<User>('/system/user', data);
  },
  
  // 更新用户
  updateUser: (id: number, data: Partial<User>) => {
    return request.put<User>(`/system/user/${id}`, data);
  },
  
  // 删除用户
  deleteUser: (id: number) => {
    return request.delete(`/system/user/${id}`);
  },
};
```

#### 10.3 状态管理示例

```typescript
// src/store/user.ts
import { defineStore } from 'pinia';
import { userApi } from '@/api/system/user';
import type { User, UserListParams } from '@/api/system/type';

export const useUserStore = defineStore('user', {
  state: () => ({
    userList: [] as User[],
    total: 0,
    loading: false,
    currentUser: null as User | null,
  }),
  
  getters: {
    getUserById: (state) => {
      return (id: number) => state.userList.find(user => user.id === id);
    },
  },
  
  actions: {
    async fetchUserList(params: UserListParams) {
      this.loading = true;
      try {
        const response = await userApi.getUserList(params);
        this.userList = response.items;
        this.total = response.total;
      } finally {
        this.loading = false;
      }
    },
    
    async fetchUserInfo(id: number) {
      this.loading = true;
      try {
        const user = await userApi.getUserInfo(id);
        this.currentUser = user;
        return user;
      } finally {
        this.loading = false;
      }
    },
    
    async createUser(user: Omit<User, 'id'>) {
      this.loading = true;
      try {
        const newUser = await userApi.createUser(user);
        this.userList.unshift(newUser);
        this.total++;
        return newUser;
      } finally {
        this.loading = false;
      }
    },
    
    async updateUser(id: number, user: Partial<User>) {
      this.loading = true;
      try {
        const updatedUser = await userApi.updateUser(id, user);
        const index = this.userList.findIndex(u => u.id === id);
        if (index !== -1) {
          this.userList[index] = updatedUser;
        }
        if (this.currentUser && this.currentUser.id === id) {
          this.currentUser = updatedUser;
        }
        return updatedUser;
      } finally {
        this.loading = false;
      }
    },
    
    async deleteUser(id: number) {
      this.loading = true;
      try {
        await userApi.deleteUser(id);
        this.userList = this.userList.filter(user => user.id !== id);
        this.total--;
        if (this.currentUser && this.currentUser.id === id) {
          this.currentUser = null;
        }
      } finally {
        this.loading = false;
      }
    },
  },
});
```

## 🎯 最佳实践总结

1. **遵循 Vibe Coding 基础规范**：统一的代码风格和命名规范
2. **使用 TypeScript 严格模式**：提高代码类型安全性
3. **优先使用组合式 API**：`setup script` 语法简洁高效
4. **模块化开发**：按功能划分代码模块，提高可维护性
5. **组件复用**：封装可复用的业务组件
6. **状态管理优化**：合理使用 Pinia，避免过度状态管理
7. **路由配置清晰**：按功能划分路由，使用元信息配置权限
8. **API 调用规范**：统一的 API 调用方式和错误处理
9. **样式一致性**：使用 Tailwind CSS 或 BEM 命名规范
10. **国际化支持**：所有用户可见文本支持多语言
11. **性能优化**：组件懒加载、虚拟滚动、防抖节流等
12. **测试覆盖**：核心功能编写单元测试

## 📚 参考资料

- [Vue 3 官方文档](https://vuejs.org/)
- [TypeScript 官方文档](https://www.typescriptlang.org/)
- [Vben Admin 官方文档](https://doc.vben.pro/)
- [Ant Design Vue 官方文档](https://antdv.com/)
- [Tailwind CSS 官方文档](https://tailwindcss.com/)
- [Pinia 官方文档](https://pinia.vuejs.org/)
- [Vue Router 官方文档](https://router.vuejs.org/)

## 🤝 贡献指南

欢迎对前端 Vibe Coding 实践指南提出改进建议：

1. 创建 Issue 描述问题或建议
2. 提交 PR 包含具体的改进内容
3. 参与讨论，完善指南内容

---

**前端 Vibe Coding 实践指南** | 持续更新中 🚀
