# 树表联动API参考文档

## 目录

1. [kr标签API](#kr标签api)
2. [l标签API](#l标签api)
3. [运行时JavaScript API](#运行时javascript-api)
4. [配置注册系统API](#配置注册系统api)

---

## kr标签API

### kr:tree_table_layout

树表联动布局标签，自动生成完整的树表联动页面。

#### 属性

| 属性名 | 类型 | 必需 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `tree_title` | String | 否 | "分类" | 树标题 |
| `tree_source` | String | 是 | - | 树数据源URL |
| `tree_search` | Boolean | 否 | false | 是否启用搜索 |
| `tree_toolbar` | String | 否 | "" | 工具栏按钮列表（逗号分隔：add,refresh,expand,collapse） |
| `tree_checkbar` | Boolean | 否 | false | 是否显示复选框 |
| `tree_contextmenu` | Boolean | 否 | false | 是否启用右键菜单 |
| `table_title` | String | 否 | "数据列表" | 表格标题 |
| `table_source` | String | 是 | - | 表格数据源URL |
| `table_page` | Boolean | 否 | true | 是否启用分页 |
| `table_frozen_cols` | Number | 否 | 0 | 冻结列数（左侧） |
| `table_action_col` | Boolean | 否 | false | 是否显示操作列 |
| `table_toolbar` | Boolean | 否 | false | 是否显示工具栏 |
| `table_checkbox` | Boolean | 否 | false | 是否显示复选框列 |
| `table_columns` | JSON | 否 | [] | 列配置（JSON格式） |
| `link_param` | String | 否 | "tree_id" | 联动参数名 |
| `link_type` | String | 否 | "click" | 联动类型（click/select/check） |

#### 示例

```erb
<kr:tree_table_layout
  tree_title="组织架构"
  tree_source="/api/org/tree"
  tree_search="true"
  tree_toolbar="add,refresh,expand"
  
  table_title="员工列表"
  table_source="/api/org/employees"
  table_page="true"
  table_frozen_cols="1"
  table_action_col="true"
  table_checkbox="true"
  table_columns='[
    {field: "id", title: "ID", width: 80, sort: true},
    {field: "name", title: "姓名", width: 120},
    {field: "position", title: "职位", width: 150}
  ]'
  
  link_param="org_id"
  link_type="click"
/>
```

### kr:tree

独立树组件标签。

#### 属性

| 属性名 | 类型 | 必需 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `url` | String | 是 | - | 数据源URL |
| `search` | Boolean | 否 | false | 是否启用搜索 |
| `toolbar` | String | 否 | "" | 工具栏按钮列表 |
| `checkbar` | Boolean | 否 | false | 是否显示复选框 |
| `contextmenu` | Boolean | 否 | false | 是否启用右键菜单 |
| `width` | String | 否 | "100%" | 宽度 |
| `height` | String | 否 | "100%" | 高度 |

#### 示例

```erb
<kr:tree 
  url="/api/categories" 
  search="true" 
  toolbar="add,refresh" 
  checkbar="true"
/>
```

### kr:datatable

独立表格组件标签。

#### 属性

| 属性名 | 类型 | 必需 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `url` | String | 是 | - | 数据源URL |
| `page` | Boolean | 否 | true | 是否启用分页 |
| `limit` | Number | 否 | 10 | 每页显示数量 |
| `frozen-cols` | Number | 否 | 0 | 冻结列数 |
| `action-col` | Boolean | 否 | false | 是否显示操作列 |
| `toolbar` | Boolean/String | 否 | false | 工具栏配置 |
| `checkbox` | Boolean | 否 | false | 是否显示复选框 |
| `sort` | Boolean | 否 | false | 是否启用排序 |
| `even` | Boolean | 否 | false | 是否显示斑马纹 |

#### 示例

```erb
<kr:datatable 
  url="/api/users" 
  page="true" 
  limit="20"
  frozen-cols="1"
  action-col="true"
  toolbar="true"
  checkbox="true"
/>
```

---

## l标签API

### l:tree

Layui树组件标签（1:1映射Layui dtree API）。

#### 核心属性

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `id` | String | 树ID |
| `url` | String | 数据源URL |
| `method` | String | 请求方法（get/post） |
| `skin` | String | 皮肤（laySimple/layui） |
| `iconStyle` | String | 图标风格（dtreefont/layui） |
| `initLevel` | Number | 初始展开层级 |
| `dataFormat` | String | 数据格式（list/tree） |
| `dataStyle` | String | 数据风格（layuiStyle/defaultStyle） |
| `width` | String | 宽度 |
| `height` | String | 高度 |

#### 工具栏属性

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `toolbar` | Boolean | 是否显示工具栏 |
| `toolbarWay` | String | 工具栏方式（contextmenu/follow/fixed） |
| `toolbarShow` | JSON | 显示的工具栏项 |
| `toolbarExt` | JSON | 扩展工具栏配置 |

#### 复选框属性

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `checkbar` | Boolean | 是否显示复选框 |
| `checkbarType` | String | 复选框类型（all/only/no） |

#### 右键菜单属性

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `contextmenu` | Boolean | 是否启用右键菜单 |
| `menubar` | Boolean | 是否显示菜单栏 |
| `menuItems` | JSON | 菜单项配置 |

### l:table

Layui表格组件标签（1:1映射Layui table API）。

#### 核心属性

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `id` | String | 表格ID |
| `url` | String | 数据源URL |
| `method` | String | 请求方法 |
| `cellMinWidth` | Number | 单元格最小宽度 |
| `skin` | String | 皮肤（line/row/nob） |
| `size` | String | 尺寸（空/sm/lg） |
| `even` | Boolean | 是否斑马纹 |
| `cols` | JSON | 列配置 |

#### 分页属性

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `page` | Boolean | 是否分页 |
| `limit` | Number | 每页数量 |
| `limits` | JSON | 分页选项 |

#### 工具栏属性

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `toolbar` | String | 工具栏选择器 |
| `defaultToolbar` | JSON | 默认工具栏 |

---

## 运行时JavaScript API

### KR.UI.Tree

树组件运行时类。

#### 构造函数

```typescript
new Tree(treeId: string, options: TreeOptions)
```

#### 方法

##### reload(data: any[]): void
重载树数据。

```javascript
tree.reload(newData);
```

##### getChecked(): any[]
获取选中节点。

```javascript
const checkedNodes = tree.getChecked();
```

##### setChecked(id: string | number, checked: boolean): void
设置节点选中状态。

```javascript
tree.setChecked('node-1', true);
```

##### expand(id: string | number): void
展开节点。

```javascript
tree.expand('node-1');
```

##### collapse(id: string | number): void
收起节点。

```javascript
tree.collapse('node-1');
```

##### expandAll(): void
展开所有节点。

```javascript
tree.expandAll();
```

##### collapseAll(): void
收起所有节点。

```javascript
tree.collapseAll();
```

##### search(keyword: string): void
搜索节点。

```javascript
tree.search('关键词');
```

##### clearSearch(): void
清除搜索。

```javascript
tree.clearSearch();
```

##### selectNode(nodeId: string | number): void
选中指定节点。

```javascript
tree.selectNode('node-1');
```

##### getSelectedNode(): any
获取当前选中节点。

```javascript
const selectedNode = tree.getSelectedNode();
```

#### 事件

##### onNodeClick(callback: Function): void
节点点击事件。

```javascript
tree.onNodeClick((data) => {
  console.log('点击节点:', data);
});
```

##### onCheckChange(callback: Function): void
复选框变化事件。

```javascript
tree.onCheckChange((checkedData) => {
  console.log('选中的节点:', checkedData);
});
```

##### onToolbarClick(callback: Function): void
工具栏点击事件。

```javascript
tree.onToolbarClick((obj) => {
  console.log('工具栏按钮:', obj.toolId);
});
```

### KR.UI.DataTable

表格组件运行时类。

#### 构造函数

```typescript
new DataTable(tableId: string, options: DataTableOptions)
```

#### 方法

##### reload(url?: string, where?: object): void
重载表格数据。

```javascript
dataTable.reload('/api/newdata', { status: 'active' });
```

##### getCheckStatus(): any
获取选中行数据。

```javascript
const checkStatus = dataTable.getCheckStatus();
```

##### freezeCols(count: number): void
冻结左侧列。

```javascript
dataTable.freezeCols(2);
```

##### freezeColsRight(count: number): void
冻结右侧列。

```javascript
dataTable.freezeColsRight(1);
```

##### setHeight(height: string | number): void
设置表格高度。

```javascript
dataTable.setHeight('full-200');
```

##### setColumnVisible(field: string, visible: boolean): void
显示/隐藏列。

```javascript
dataTable.setColumnVisible('email', false);
```

##### exportData(type: 'csv' | 'excel', filename?: string): void
导出数据。

```javascript
dataTable.exportData('excel', 'employees.csv');
```

##### print(): void
打印表格。

```javascript
dataTable.print();
```

##### search(keyword: string, fields?: string[]): void
搜索表格数据。

```javascript
dataTable.search('张三', ['name', 'email']);
```

##### clearSearch(): void
清除搜索。

```javascript
dataTable.clearSearch();
```

#### 事件

##### onToolbarEvent(callback: Function): void
工具栏事件。

```javascript
dataTable.onToolbarEvent((obj) => {
  const { event, data } = obj;
  if (event === 'add') {
    // 添加逻辑
  }
});
```

##### onToolEvent(callback: Function): void
行工具条事件。

```javascript
dataTable.onToolEvent((obj) => {
  const { event, data } = obj;
  if (event === 'edit') {
    // 编辑逻辑
  }
});
```

##### onRowEvent(callback: Function): void
行点击事件。

```javascript
dataTable.onRowEvent((obj) => {
  console.log('点击行:', obj.data);
});
```

### KR.UI.LinkedLayout

联动布局管理器。

#### 构造函数

```typescript
new LinkedLayout(options: LinkedLayoutOptions)
```

#### 选项

```typescript
interface LinkedLayoutOptions {
  sourceComponent: Tree | DataTable;     // 源组件
  targetComponents: (Tree | DataTable)[]; // 目标组件列表
  linkParam: string;                     // 联动参数名
  linkType?: 'click' | 'select' | 'check' | 'reload'; // 联动类型
  autoLink?: boolean;                    // 是否自动联动
}
```

#### 方法

##### setupLinks(): void
设置联动关系。

```javascript
linkedLayout.setupLinks();
```

##### addTarget(component: Tree | DataTable): void
添加目标组件。

```javascript
linkedLayout.addTarget(anotherTable);
```

##### removeTarget(component: Tree | DataTable): void
移除目标组件。

```javascript
linkedLayout.removeTarget(someTable);
```

##### triggerLink(data: any): void
手动触发联动。

```javascript
linkedLayout.triggerLink({ id: 123 });
```

##### on(event: string, handler: Function): void
添加事件监听器。

```javascript
linkedLayout.on('link', (data) => {
  console.log('联动触发:', data);
});
```

##### off(event: string, handler?: Function): void
移除事件监听器。

```javascript
linkedLayout.off('link');
```

##### destroy(): void
销毁联动关系。

```javascript
linkedLayout.destroy();
```

#### 示例

```javascript
// 创建树和表格
const tree = KR.UI.createTree('tree_org', {
  url: '/api/org/tree'
});

const dataTable = KR.UI.createDataTable('table_employees', {
  url: '/api/org/employees'
});

// 创建联动
const linkedLayout = KR.UI.createLinkedLayout({
  sourceComponent: tree,
  targetComponents: [dataTable],
  linkParam: 'org_id',
  linkType: 'click',
  autoLink: true
});

// 监听联动事件
linkedLayout.on('link', (eventData) => {
  console.log('联动数据:', eventData);
});
```

---

## 配置注册系统API

### ComponentConfigRegistry

组件配置注册表。

#### 类方法

##### register_mapper(component_type, mapper_class)
注册配置映射器。

```ruby
ComponentConfigRegistry.register_mapper('tree', TreeConfigMapper)
```

##### register_processor(component_type, processor)
注册AI处理器。

```ruby
ComponentConfigRegistry.register_processor('tree', AIConfigEnhancer)
```

##### transform(component_type, kr_attrs, context = {})
转换kr配置到l配置。

```ruby
l_attrs = ComponentConfigRegistry.transform('tree', kr_attrs, context)
```

### 配置映射器接口

每个配置映射器需要实现以下方法：

#### map_defaults(kr_attrs)
基础默认值映射。

```ruby
def self.map_defaults(kr_attrs)
  {
    url: kr_attrs['url'],
    method: 'post',
    skin: 'laySimple'
  }
end
```

#### map_conditional(kr_attrs, base_config)
条件规则映射。

```ruby
def self.map_conditional(kr_attrs, base_config)
  config = base_config.dup
  
  if kr_attrs['search'] == 'true'
    config[:toolbar] = true
    config[:toolbarShow] = "['searchIcon']"
  end
  
  config
end
```

#### infer_from_context(config, context)
上下文推断。

```ruby
def self.infer_from_context(config, context)
  if context[:scenario] == 'tree_table_layout'
    config[:width] = '300px'
    config[:height] = '500px'
  end
  
  config
end
```

---

## 完整使用示例

```erb
<!-- ERB模板 -->
<kr:tree_table_layout
  tree_title="部门架构"
  tree_source="/api/departments"
  tree_search="true"
  tree_toolbar="add,refresh"
  
  table_title="员工名单"
  table_source="/api/employees"
  table_page="true"
  table_frozen_cols="1"
  table_action_col="true"
  
  link_param="dept_id"
/>

<!-- 自定义JavaScript（可选） -->
<script>
layui.use(['jquery'], function(){
  var $ = layui.jquery;
  
  // 获取自动创建的组件实例
  var tree = window.KR_TREE_dept_tree;
  var table = window.KR_TABLE_employee_table;
  
  // 添加自定义逻辑
  tree.onNodeClick(function(data) {
    console.log('部门切换:', data);
    // 可以添加额外的业务逻辑
  });
});
</script>
```

---

## 参考资料

- [组件配置系统文档](./component_config_system.md)
- [Layui官方文档](https://www.layui.com/doc/)
- [TypeScript运行时源码](../assets/ts/layui/)

