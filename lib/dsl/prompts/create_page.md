# AI Prompt Template: Create Page

## System Context

You are generating code for the **Tahe Framework**, a Ruby-based low-code business application platform.

**Framework UI Capabilities:**
- Component-based DSL (tree_table_layout, search_table, crud_panel, form)
- Grid-based DSL (GridStack.js style with KR tags)
- Layui UI framework
- Automatic data binding to models

## Project Context

{{PROJECT_CONTEXT}}

**Existing Models:**
{{EXISTING_MODELS}}

**Existing Pages:**
{{EXISTING_PAGES}}

**Available Components:**
{{AVAILABLE_COMPONENTS}}

## Task

{{USER_REQUIREMENT}}

## Schema Constraints

Your output MUST conform to one of these schemas:

**Component DSL:**
```json
{{COMPONENT_DSL_SCHEMA}}
```

**Grid DSL:**
```json
{{GRID_DSL_SCHEMA}}
```

## Conventions

Follow these conventions strictly:

1. **File Naming:**
   - Page file: `pages/{{page_name_snake}}.krdsl`
   - Route: `/{{page_name_kebab}}`

2. **Component DSL vs Grid DSL:**
   - Use **Component DSL** for: CRUD pages, list pages, search pages
   - Use **Grid DSL** for: complex forms, dashboards, custom layouts

3. **Component Types:**
   - `crud_panel` - Full CRUD with table + form
   - `search_table` - Table with search filters
   - `tree_table_layout` - Tree on left, table on right
   - `form` - Standalone form
   - `table` - Simple table
   - `chart` - Data visualization

4. **API Endpoints:**
   - List: `GET /api/{{model_plural}}`
   - Create: `POST /api/{{model_plural}}`
   - Update: `PUT /api/{{model_plural}}/:id`
   - Delete: `DELETE /api/{{model_plural}}/:id`
   - Search: `GET /api/{{model_plural}}/search`

5. **Field Mapping:**
   - Model field type → UI component type
   - `text` → `input`
   - `textarea` → `textarea`
   - `number`/`amount` → `input` with `input_type: "number"`
   - `date` → `date`
   - `enum` → `select`
   - `single_relation` → `select` with API source
   - `boolean` → `switch`

## Examples

### Example 1: CRUD Page (Component DSL)

**User Request:** "Create a product management page with CRUD operations"

**Model Reference:**
```json
{
  "model": "Product",
  "fields": [
    {"name": "name", "type": "text", "label": "产品名称"},
    {"name": "price", "type": "amount", "label": "价格"},
    {"name": "category", "type": "single_relation", "label": "分类", "options": {"target": "Category"}},
    {"name": "status", "type": "enum", "label": "状态"}
  ]
}
```

**Output:**
```ruby
# pages/product_management.krdsl
page "产品管理"
layout admin
theme default
model Product

# CRUD 管理面板
component crud_panel
  title: "产品管理"
  api_base: "/api/products"
  columns: [
    {type: "checkbox", fixed: "left"},
    {field: "id", title: "ID", width: 80, sort: true},
    {field: "name", title: "产品名称", width: 200, edit: "text"},
    {field: "price", title: "价格", width: 120},
    {field: "category", title: "分类", width: 120},
    {field: "status", title: "状态", width: 100},
    {field: "created_at", title: "创建时间", width: 180},
    {fixed: "right", title: "操作", width: 150, toolbar: "#rowTools"}
  ]

# 产品表单
component form
  title: "产品信息"
  action: "/api/products/save"
  fields: [
    {type: "input", name: "name", label: "产品名称", required: true, placeholder: "请输入产品名称"},
    {type: "input", name: "price", label: "价格", input_type: "number", required: true, placeholder: "请输入价格"},
    {type: "select", name: "category", label: "产品分类", required: true, options: []},
    {type: "select", name: "status", label: "状态", options: [
      {value: "draft", text: "草稿"},
      {value: "published", text: "已发布"},
      {value: "archived", text: "已归档"}
    ]}
  ]
```

### Example 2: Search Page (Component DSL)

**User Request:** "Create a product search page with filters for name, category, and price range"

**Output:**
```ruby
# pages/product_search.krdsl
page "产品搜索"
layout admin
theme default
model Product

# 搜索表格
component search_table
  table_title: "搜索结果"
  table_source: "/api/products/search"
  search_fields: [
    {type: "input", name: "keyword", label: "关键词", placeholder: "请输入产品名称"},
    {type: "select", name: "category", label: "分类", options: []},
    {type: "number_range", name: "price_range", label: "价格区间", placeholder: "请选择价格范围"},
    {type: "date_range", name: "date_range", label: "创建时间", placeholder: "请选择时间范围"}
  ]
  columns: [
    {field: "id", title: "ID", width: 80},
    {field: "name", title: "产品名称", width: 200},
    {field: "category", title: "分类", width: 120},
    {field: "price", title: "价格", width: 120},
    {field: "status", title: "状态", width: 100},
    {field: "created_at", title: "创建时间", width: 180}
  ]
```

### Example 3: Tree-Table Layout (Component DSL)

**User Request:** "Create a category management page with tree on left and products on right"

**Output:**
```ruby
# pages/category_product_management.krdsl
page "分类产品管理"
layout admin
theme default

# 左树右表布局
component tree_table_layout
  tree_title: "产品分类"
  table_title: "产品列表"
  tree_source: "/api/categories/tree"
  table_source: "/api/products"
  columns: [
    {field: "id", title: "ID", width: 80, sort: true},
    {field: "name", title: "产品名称", width: 200},
    {field: "price", title: "价格", width: 120},
    {field: "status", title: "状态", width: 100},
    {field: "created_at", title: "创建时间", width: 180}
  ]
```

### Example 4: Complex Form (Grid DSL)

**User Request:** "Create a project registration form with sections for basic info, client info, and attachments"

**Output:**
```ruby
# pages/project_registration_form.krdsl
title "项目立项信息登记"
description "项目立项信息登记表单"
grid 12
cell_height 80
margin 10
static_grid true

# 顶部工具栏
section "顶部工具栏"

item id="toolbar" x=0 y=0 w=12 h=2 {
  <kr:toolbar>
    <kr:button text="保存" icon="save" theme="primary" />
    <kr:button text="保存并提交" icon="submit" theme="primary" />
    <kr:button text="返回" icon="back" />
  </kr:toolbar>
}

# 基本信息区域
section "基本信息区域"

item id="basic_info_title" x=0 y=2 w=12 h=1 {
  <kr:section title="基本信息" />
}

item id="form_row1" x=0 y=3 w=12 h=2 {
  <kr:form_row>
    <kr:form_field name="date" label="日期" type="date" required="true" width="33%" />
    <kr:form_field name="project_number" label="项目编号" type="text" placeholder="保存后自动生成" width="33%" />
    <kr:form_field name="project_name" label="项目名称" type="text" required="true" width="33%" />
  </kr:form_row>
}

item id="form_row2" x=0 y=5 w=12 h=2 {
  <kr:form_row>
    <kr:form_field name="start_date" label="开始日期" type="date" required="true" width="50%" />
    <kr:form_field name="end_date" label="结束日期" type="date" required="true" width="50%" />
  </kr:form_row>
}

# 甲方信息区域
section "甲方信息区域"

item id="client_info_title" x=0 y=7 w=12 h=1 {
  <kr:section title="甲方信息" />
}

item id="client_info_form" x=0 y=8 w=12 h=2 {
  <kr:form_row>
    <kr:form_field name="client_name" label="甲方名称" type="text" width="33%" />
    <kr:form_field name="client_contact" label="联系人" type="text" width="33%" />
    <kr:form_field name="client_phone" label="联系电话" type="text" width="33%" />
  </kr:form_row>
}

# 附件区域
section "附件区域"

item id="attachments_title" x=0 y=10 w=12 h=1 {
  <kr:section title="附件" />
}

item id="attachments_upload" x=0 y=11 w=12 h=1 {
  <kr:file_upload id="attachments" multiple="true" />
}

item id="attachments_list" x=0 y=12 w=12 h=3 {
  <kr:file_list>
    <kr:table_column field="name" title="文件名称" />
    <kr:table_column field="size" title="文件大小" />
    <kr:table_column field="uploader" title="上传人" />
    <kr:table_column field="upload_time" title="上传时间" />
  </kr:file_list>
}
```

## Output Format

Generate a valid `.krdsl` file in the appropriate DSL format (Component or Grid).

**File to create:** `pages/{{page_name_snake}}.krdsl`

**Important:**
- Choose the right DSL format based on the use case
- Reference the model if available (using `model ModelName`)
- Use correct API endpoints following REST conventions
- Map model fields to appropriate UI components
- Include all necessary form validations
- Add appropriate table columns for list views

## Validation Checklist

Before outputting, verify:
- [ ] Page title is descriptive
- [ ] Layout is appropriate (admin/default/blank)
- [ ] Model reference is correct (if used)
- [ ] API endpoints follow REST conventions
- [ ] Form fields match model fields
- [ ] Table columns are appropriate
- [ ] Search fields are useful
- [ ] Required fields are marked
- [ ] Component types are valid
- [ ] Syntax is correct (Ruby DSL or Grid DSL)
