# 模板和模板实现体现说明

## 🎯 概述

系统中存在**三个层次的模板体系**，各有不同的用途和实现方式：

1. **LayUI 前端渲染模板** - 用于表格单元格的动态渲染
2. **业务模板系统** - 预定义的完整页面配置模板  
3. **ERB 视图模板** - 服务器端页面渲染

---

## 📱 层次1: LayUI 前端渲染模板

### 用途
用于表格中**FK字段**和**枚举字段**的前端动态显示

### 模板定义位置
在生成的HTML中以 `<script type="text/html" id="template_id">` 形式存在

### 模板生成类
- **`TableColItem#generate_fk_template`** - 生成FK字段模板
- **`TableColItem#generate_enum_template`** - 生成枚举字段模板

### 实现示例

#### FK字段模板生成（`table_col_item.rb:77-92`）
```ruby
def generate_fk_template
  return nil unless @fk_config
  
  template_id = @templet
  result_field = @fk_config[:result_field]
  
  <<~HTML
    <script type="text/html" id="#{template_id}">
      {{# if (d.#{result_field}) { }}
        {{ d.#{result_field} }}
      {{# } else { }}
        <span style="color: #ccc;">-</span>
      {{# } }}
    </script>
  HTML
end
```

#### 枚举字段模板生成（`table_col_item.rb:95-113`）
```ruby
def generate_enum_template
  return nil unless @enum_values
  
  template_id = @templet
  enum_map = @enum_values.map { |e| "#{e[:value]}: '#{e[:label]}'" }.join(', ')
  
  %Q{
    <script type="text/html" id="#{template_id}">
      {{# 
        var enumMap = { #{enum_map} };
        var label = enumMap[d.#{@field}] || '未知';
        var colorMap = ['orange', 'green', 'blue', 'red', 'gray', 'cyan', 'purple'];
        var color = colorMap[d.#{@field}] || 'gray';
      }}
      <span class="layui-badge layui-bg-{{color}}">{{label}}</span>
    </script>
  }
end
```

### 模板收集和注入（`table_item.rb:145-174`）
```ruby
def collect_column_metadata
  return unless @children
  
  children_array = @children.is_a?(Array) ? @children : [@children]
  
  children_array.each do |child|
    next unless child.respond_to?(:pre_process)
    
    child.pre_process
    
    if child.is_a?(TableColItem)
      fk_config = child.get_fk_config
      @fk_hints << fk_config if fk_config
      
      # 收集FK模板
      fk_template = child.generate_fk_template
      @column_templates << fk_template if fk_template
      
      # 收集枚举模板
      enum_template = child.generate_enum_template
      @column_templates << enum_template if enum_template
    end
  end
end
```

### 模板注入到HTML（`table_item.rb:60-100`）
```ruby
<<~HTML
  <table id="#{table_id}" lay-filter="#{table_id}"></table>
  
  #{templates_html}  <!-- ⭐ 模板注入点 -->
  
  <script>
    layui.use(['table'], function() {
      var table = layui.table;
      
      table.render({
        elem: '##{table_id}',
        url: '/api/query',
        cols: #{cols_json},  <!-- 列配置引用模板ID -->
        ...
      });
    });
  </script>
HTML
```

### 生成的HTML效果示例
```html
<table id="employee_table" lay-filter="employee_table"></table>

<!-- FK模板 -->
<script type="text/html" id="fk_department_id_a3f2c1">
  {{# if (d.department_name) { }}
    {{ d.department_name }}
  {{# } else { }}
    <span style="color: #ccc;">-</span>
  {{# } }}
</script>

<!-- 枚举模板 -->
<script type="text/html" id="enum_gender_b4e7d2">
  {{# 
    var enumMap = { 0: '男', 1: '女', 2: '未知' };
    var label = enumMap[d.gender] || '未知';
    var colorMap = ['orange', 'green', 'blue', 'red', 'gray', 'cyan', 'purple'];
    var color = colorMap[d.gender] || 'gray';
  }}
  <span class="layui-badge layui-bg-{{color}}">{{label}}</span>
</script>

<script>
  layui.use(['table'], function() {
    var table = layui.table;
    table.render({
      elem: '#employee_table',
      cols: [[
        {field: 'name', title: '姓名', width: 120},
        {field: 'department_name', title: '部门', width: 150, templet: '#fk_department_id_a3f2c1'},
        {field: 'gender', title: '性别', width: 80, templet: '#enum_gender_b4e7d2'}
      ]]
    });
  });
</script>
```

---

## 📋 层次2: 业务模板系统（YAML配置）

### 用途
预定义**完整页面配置**，支持快速生成标准化的CRUD界面

### 模板定义文件
- 位置：`lib/templates/builtin/*.yml`
- 示例：`user_management.yml`

### 模板管理类
- **`TemplateManager`** - 单例模式，负责加载和管理所有模板
- **`TemplateToKrConverter`** - 将YAML配置转换为kr标签

### 模板结构示例（`user_management.yml`）
```yaml
# 元数据
metadata:
  id: user_management
  name: "用户管理系统"
  description: "左树右表布局的用户管理界面"
  version: "1.0.0"
  category: "system_management"
  tags: ["user", "organization", "tree_table", "crud"]

# 布局配置
layout:
  type: tree_table_layout
  responsive: true
  theme: "default"

# 树组件配置
tree_config:
  title: "组织机构"
  data_source:
    url: "/api/org/tree"
    method: "GET"
  features:
    search: true
    toolbar: ["add", "refresh", "expand", "collapse"]
  display:
    width: "300px"
    height: "500px"

# 表格组件配置
table_config:
  title: "用户管理"
  data_source:
    url: "/api/users"
    method: "GET"
  pagination:
    enabled: true
    page_size: 20
  columns:
    - field: "username"
      title: "用户名"
      width: 120
    - field: "email"
      title: "邮箱"
      width: 180
```

### 模板管理实现（`template_manager.rb`）
```ruby
class TemplateManager
  include Singleton
  
  # 加载所有内置模板
  def load_builtin_templates
    builtin_dir = File.join(__dir__, 'builtin')
    yaml_files = Dir.glob(File.join(builtin_dir, '*.yml'))
    
    yaml_files.each do |file_path|
      template_data = YAML.load_file(file_path)
      template_id = extract_template_id(template_data, file_path)
      
      @templates[template_id] = {
        data: template_data,
        file_path: file_path,
        loaded_at: Time.now
      }
    end
  end
  
  # 实例化模板为kr标签
  def instantiate(template_id, customizations = {})
    template_config = get_template(template_id)
    merged_config = deep_merge(template_config, customizations)
    
    # 转换为kr标签
    TemplateToKrConverter.convert(merged_config)
  end
end
```

### 模板使用示例
```ruby
# 获取模板
template = TemplateManager.get_template('user_management')

# 实例化模板（可自定义）
kr_tags = TemplateManager.instantiate('user_management', {
  'tree_config' => {
    'data_source' => {
      'url' => '/api/custom/tree'
    }
  }
})

# kr_tags 结果是生成的kr标签字符串
puts kr_tags
# 输出：
# <kr:tree-table-layout>
#   <kr:tree source="/api/custom/tree" ...>...</kr:tree>
#   <kr:datatable source="/api/users" ...>...</kr:datatable>
# </kr:tree-table-layout>
```

---

## 🎨 层次3: ERB 视图模板

### 用途
服务器端渲染的**页面模板**，包含kr标签的DSL定义

### 模板位置
- `api/views/*.erb`
- 例如：`employee_management.erb`

### 模板内容示例（`employee_management.erb:30-88`）
```erb
<div class="layui-card-body">
  
  <!-- 使用 kr:datatable 和 kr:col（核心！） -->
  <kr:datatable id="employee_table" source="org_employees" page="true" limit="15">
    
    <!-- 普通列 -->
    <kr:col title="工号" field="employee_id" width="100" sort="true" fixed="left" />
    <kr:col title="姓名" field="name" width="120" sort="true" />
    
    <!-- FK列: 所属部门 -->
    <kr:col 
      title="所属部门" 
      field="department_id"
      relation="department"
      relation_field="name"
      width="150" />
    
    <!-- 枚举列: 性别 -->
    <kr:col 
      title="性别" 
      field="gender" 
      type="enum"
      enum="男,女,未知"
      width="80" />
    
    <!-- 枚举列: 状态 -->
    <kr:col 
      title="状态" 
      field="status" 
      type="enum"
      enum="在职,离职,试用期"
      width="100" />
    
    <kr:col title="入职日期" field="entry_date" width="120" sort="true" />
    
  </kr:datatable>
  
</div>
```

### ERB模板渲染流程
```
1. ERB模板（.erb）
   ↓
2. ERB处理器解析
   ↓
3. kr标签（<kr:datatable>）
   ↓
4. KrTransformer转换
   ↓
5. LayUI元素（TableItem, TableColItem）
   ↓
6. 生成HTML + LayUI模板（<script type="text/html">）
   ↓
7. 最终HTML发送到浏览器
```

---

## 🔄 三个层次的协作关系

```
┌─────────────────────────────────────────────────────────────┐
│  业务模板系统 (YAML)                                         │
│  TemplateManager → TemplateToKrConverter                     │
│  生成: kr标签字符串                                          │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  ERB 视图模板 (.erb)                                         │
│  包含: kr标签定义                                            │
│  <kr:datatable> + <kr:col>                                   │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  KR转换器 (KrTransformer)                                    │
│  解析kr标签 → 生成LayUI元素实例                             │
│  TableItem + TableColItem                                    │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  LayUI元素生成HTML                                           │
│  • TableColItem#generate_fk_template                         │
│  • TableColItem#generate_enum_template                       │
│  • TableItem#collect_column_metadata                         │
│  • TableItem#output_tag                                      │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  最终HTML输出                                                │
│  • <table> 标签                                              │
│  • <script type="text/html"> 模板                           │
│  • <script> LayUI渲染代码                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 模板实现的关键特性

### 1. **动态性**
- FK模板根据relation自动生成
- 枚举模板根据模型定义或显式配置生成
- 无需手动编写模板代码

### 2. **可配置性**
- 业务模板支持YAML配置
- 支持自定义覆盖默认配置
- 支持特殊映射

### 3. **可扩展性**
- 易于添加新的模板类型
- 支持插件化扩展
- 模板ID唯一标识

### 4. **可重用性**
- 模板可在多个页面复用
- 支持部分覆盖和完全自定义
- 减少重复代码

### 5. **类型安全**
- 从模型元数据读取枚举值
- 自动验证FK关系
- 降低配置错误

---

## 📊 实际使用流程示例

### 场景：创建员工管理页面

#### 方式1: 使用业务模板
```ruby
# 使用预定义模板
kr_code = TemplateManager.instantiate('user_management', {
  'table_config' => {
    'data_source' => { 'url' => '/api/employees' }
  }
})

# 在controller中渲染
erb kr_code
```

#### 方式2: 直接编写ERB
```erb
<!-- employee_management.erb -->
<kr:datatable id="emp_table" source="org_employees">
  <kr:col title="姓名" field="name" />
  <kr:col title="部门" field="department_id" 
          relation="department" relation_field="name" />
  <kr:col title="状态" field="status" type="enum" enum="在职,离职,试用期" />
</kr:datatable>
```

#### 最终生成的HTML
```html
<table id="emp_table"></table>

<!-- 自动生成的FK模板 -->
<script type="text/html" id="fk_department_id_xxx">
  {{# if (d.department_name) { }}
    {{ d.department_name }}
  {{# } else { }}
    <span style="color: #ccc;">-</span>
  {{# } }}
</script>

<!-- 自动生成的枚举模板 -->
<script type="text/html" id="enum_status_yyy">
  {{# 
    var enumMap = { 0: '在职', 1: '离职', 2: '试用期' };
    var label = enumMap[d.status] || '未知';
  }}
  <span class="layui-badge">{{ label }}</span>
</script>

<script>
  layui.use(['table'], function() {
    table.render({
      cols: [[
        {field: 'name', title: '姓名'},
        {field: 'department_name', title: '部门', templet: '#fk_department_id_xxx'},
        {field: 'status', title: '状态', templet: '#enum_status_yyy'}
      ]]
    });
  });
</script>
```

---

## 📝 总结

| 模板层次 | 作用范围 | 实现方式 | 生成时机 | 配置来源 |
|---------|---------|---------|---------|---------|
| **LayUI前端模板** | 单元格渲染 | `<script type="text/html">` | 页面渲染时 | 从kr:col属性或模型 |
| **业务模板** | 完整页面 | YAML配置 | 模板实例化时 | lib/templates/builtin/ |
| **ERB视图模板** | 页面结构 | ERB + kr标签 | 请求处理时 | api/views/ |

三个层次的模板体系相互配合，实现了从**页面配置**到**UI渲染**的完整流程，既保证了灵活性，又确保了可维护性。

