---
description: |
  为 Ark Tech Platform 管理后台前端生成标准管理后台页面骨架。当需要新增管理页 CRUD、或基于 Vben Admin 模式创建列表/表单/抽屉页面时触发。

  触发场景：
  - "给 XXX 创建前端管理页面" / "新增 XXX 列表页"
  - "做 XXX 的 CRUD 页面"
  - "创建版本的页面和表单"
  - 任何需要生成 list.vue + data.ts + modules/ + api/ + locales/ 模式的任务

  需要用户提供的输入：模块中文名、英文名、页面字段列表、路由位置。
name: avmc-frontend-page
---

# Ark Tech Platform 前端管理页面生成

生成标准 Vben Admin CRUD 页面骨架。管理后台页面默认生成在 `frontend-service/apps/web-antd-admin` 下；业务模块页面需先确认前端服务边界后再确定落点。

## 输入要求

| 项目 | 说明 | 示例 |
|------|------|------|
| **模块中文名** | 中文展示名称 | 版本管理 |
| **模块英文名** | 英文 kebab-case 目录名 | version |
| **字段列表** | 表格列、搜索筛选项、表单字段 | 见下方 |
| **路由位置** | 放在哪个菜单下 | system / project / 新建模块 |
| **是否项目级** | 是否关联项目 | 是，按项目筛选 |

字段列表的每项包含：`key`(字段名), `label`(中文标签), `type`(text/number/select/switch/date/upload), `inTable`(是否表格列), `inSearch`(是否可搜索), `inForm`(是否出现在表单), `required`(是否必填), `options`(下拉选项)。

**功能清单确认（必须）：**

生成页面代码前，读取 `docs/architecture/4-7-治理-代码功能清单.md`。在"四、前端管理后台页面"对应模块下追加新的功能行（状态 `[~]`、对应优先级），或在已有行上确认范围。代码生成完成后，将功能行状态更新为 `[x]` 并填写生成的 views/api/router/locales 文件路径。

## 生成文件结构

```
views/<module>/
├── list.vue              # 页面壳 + useVbenVxeGrid
├── data.ts               # table columns、filter shema、form schema
├── modules/
│   └── form.vue          # useVbenDrawer + useVbenForm
├── api/
│   └── index.ts          # 类型安全 API wrapper
└── locales/
    ├── zh-CN.json        # 中文文案
    └── en-US.json        # 英文文案
```

此外更新路由文件 `router/routes/modules/` 添加新模块路由。

## 代码模式

### list.vue 骨架

```vue
<script setup lang="ts">
import { onMounted, h } from 'vue'
import { useVbenVxeGrid } from '#/adapter/vxe-table'
import { useVbenDrawer } from '#/adapter/vben-drawer'
import { columns, searchFormSchemas } from './data'
import { api } from './api'
import FormDrawer from './modules/form.vue'

defineOptions({ name: 'XxxManage' })

const [Grid, gridApi] = useVbenVxeGrid({
  columns,
  pagerConfig: { enabled: true },
  proxyConfig: {
    ajax: {
      query: async ({ page, formValues }) => {
        const res = await api.list({ ...formValues, page: page.currentPage, pageSize: page.pageSize })
        return { result: res.items, total: res.total }
      }
    }
  },
  toolbarConfig: {
    slots: { tools: 'toolbar' }
  }
})

const [FormDrawer, drawerApi] = useVbenDrawer({
  onConfirm: async () => { /* refresh grid */ }
})

function handleAdd() { drawerApi.open() }
function handleEdit(row) { drawerApi.setData(row); drawerApi.open() }
async function handleDelete(id) { /* confirm then api.delete then refresh */ }
</script>
```

### data.ts 模式

```ts
import type { VxeGridProps } from '#/adapter/vxe-table'

export const columns: VxeGridProps['columns'] = [
  { type: 'checkbox', width: 50 },
  { field: 'name', title: '名称', minWidth: 150 },
  { field: 'status', title: '状态', width: 100, slots: { default: 'status' } },
  { field: 'createdAt', title: '创建时间', width: 180 },
  { field: 'action', title: '操作', width: 200, slots: { default: 'action' }, fixed: 'right' },
]

export const searchFormSchemas = [
  { field: 'name', label: '名称', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'Select', colProps: { span: 6 },
    componentProps: { options: [{ label: '启用', value: 1 }, { label: '禁用', value: 0 }] }
  },
]
```

### API 模式

```ts
import { request } from '#/api/request'

export interface XxxItem {
  id: number
  name: string
  status: number
  createdAt: string
}

export const api = {
  list: (params: Record<string, any>) => request.get<{ items: XxxItem[]; total: number }>('/platform/v1/xxx', { params }),
  create: (data: Partial<XxxItem>) => request.post('/platform/v1/xxx', data),
  update: (id: number, data: Partial<XxxItem>) => request.put(`/platform/v1/xxx/${id}`, data),
  delete: (id: number) => request.delete(`/platform/v1/xxx/${id}`),
  get: (id: number) => request.get<XxxItem>(`/platform/v1/xxx/${id}`),
}
```

## 约束
- 表格优先使用 `useVbenVxeGrid`
- drawer/表单优先使用 `useVbenDrawer` + `useVbenForm`
- 状态标签使用 `CellTag` / `CellSwitch` 等已有渲染器
- 新增文案同时补 `zh-CN` 和 `en-US`
- 破坏性操作必须确认（`Modal.confirm` 或 ant-design-vue 的 `message`）
- 图标使用与现有路由一致的 Iconify/lucide 风格
- 菜单标题使用 i18n key，不硬编码字符串
