# kr Taglib1 组件分类与命名规范

## 1. 页面与母版页
- `<kr:page>`：基础页面包裹结构，含布局、标题等
- `<kr:layout>`：支持多栏布局，配置列宽

## 2. 布局相关
- `<kr:container>`：布局容器
- `<kr:region>`：子区域布局，如主区域、侧边栏、顶部栏

## 3. 业务交互组件
- `<kr:user-picker>`：部门/人员选择器（弹窗）
- `<kr:dept-picker>`：仅部门选择
- `<kr:org-selector>`：组织选择器（支持级联）
- `<kr:approve-node-editor>`：审批节点编辑器

## 4. 通用数据组件
- `<kr:datatable>`：支持分页、排序、列配置等功能的数据表格
- `<kr:tree>`：树形结构展示，可支持异步加载
- `<kr:search-bar>`：搜索区域定义
- `<kr:form>`：动态表单渲染

## 5. 基础组件
- `<kr:dialog>`：通用弹窗
- `<kr:tabs>`：页签组件
- `<kr:button>`：按钮组件（支持行为绑定）
- `<kr:input>`：输入框组件（可绑定数据源）