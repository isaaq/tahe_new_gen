
# 📘 kr taglib1 标签定义文档（Admin Dashboard 专用）

> 所有标签均以 `kr:` 前缀命名，标签风格统一为 `kebab-case`，适用于 Ruby taglib 渲染器、erb 语法嵌入、AI patch 支持。

---

## 1. 通用数据组件

### `<kr:datatable>`

| 属性名        | 类型     | 是否必填 | 说明                       |
|---------------|----------|----------|----------------------------|
| `source`      | String   | 是       | 数据源标识（后端接口名）    |
| `columns`     | Array    | 是       | 表格列定义（可嵌套子节点）  |
| `pagination`  | Boolean  | 否       | 是否开启分页                |
| `row-actions` | Array    | 否       | 每行操作按钮列表            |
| `checkbox`    | Boolean  | 否       | 是否开启多选框              |

**示例：**
```erb
<kr:datatable source="user.list" pagination="true">
  <kr:column field="name" title="姓名" />
  <kr:column field="email" title="邮箱" />
  <kr:column field="dept" title="部门" />
  <kr:row-actions>
    <kr:action name="edit" label="编辑" />
    <kr:action name="delete" label="删除" confirm="确认删除？" />
  </kr:row-actions>
</kr:datatable>
```

---

### `<kr:form>`

| 属性名      | 类型     | 是否必填 | 说明               |
|-------------|----------|----------|--------------------|
| `model`     | String   | 是       | 数据模型/对象 ID   |
| `layout`    | String   | 否       | `horizontal` / `vertical` |
| `action`    | String   | 是       | 表单提交地址        |

**示例：**
```erb
<kr:form model="user" action="/users/create">
  <kr:input name="name" label="用户名" required="true" />
  <kr:select name="role" label="角色" source="role.options" />
  <kr:date-picker name="birth" label="出生日期" />
</kr:form>
```

---

## 2. 业务交互组件

### `<kr:user-selector>`

| 属性名        | 类型     | 是否必填 | 说明                      |
|---------------|----------|----------|---------------------------|
| `name`        | String   | 是       | 绑定字段名                 |
| `multiple`    | Boolean  | 否       | 是否支持多选               |
| `dialog-title`| String   | 否       | 弹窗标题                   |
| `placeholder` | String   | 否       | 输入框占位符               |

**示例：**
```erb
<kr:user-selector name="owner" multiple="true" dialog-title="选择使用人" />
```

---

### `<kr:approval-editor>`

| 属性名     | 类型     | 是否必填 | 说明                   |
|------------|----------|----------|------------------------|
| `flow-key` | String   | 是       | 审批流标识              |
| `value`    | Object   | 否       | 当前审批配置（json）    |

**示例：**
```erb
<kr:approval-editor flow-key="leave_process" />
```

---

## 3. 页面与布局组件

### `<kr:list-page>`

组合页面结构：搜索 + 表格 + 分页

**示例：**
```erb
<kr:list-page title="用户管理">
  <kr:search-panel>
    <kr:input name="keyword" label="关键词" />
    <kr:select name="dept_id" label="部门" source="dept.list" />
  </kr:search-panel>

  <kr:datatable source="user.list" pagination="true">
    <kr:column field="name" title="姓名" />
    <kr:column field="email" title="邮箱" />
  </kr:datatable>
</kr:list-page>
```

---

### `<kr:layout-master>`

母版页布局：可定义侧边栏、导航栏、主体区等插槽。

**示例：**
```erb
<kr:layout-master>
  <kr:slot name="header">系统管理平台</kr:slot>
  <kr:slot name="sidebar">菜单结构</kr:slot>
  <kr:slot name="content">
    <kr:list-page title="用户管理">...</kr:list-page>
  </kr:slot>
</kr:layout-master>
```

---

## 4. 附：基础字段组件（常用表单字段）

| 标签名               | 说明             |
|----------------------|------------------|
| `<kr:input>`         | 文本输入框       |
| `<kr:select>`        | 下拉选择         |
| `<kr:switch>`        | 开关切换         |
| `<kr:date-picker>`   | 日期选择器       |
| `<kr:number-input>`  | 数字输入框       |
| `<kr:textarea>`      | 多行文本框       |

---

## ✅ 补充说明

- 所有标签都建议实现到 taglib1，并在编译为 taglib2（实现级）时适配 Layui/Element/Turbo 等。
- 支持 `AI patch` 注释格式，例如：
  ```erb
  <%# @ai: component = "datatable", source = "user.list" %>
  ```
