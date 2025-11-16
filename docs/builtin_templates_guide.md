# 内置模板使用指南

## 概述

内置模板系统是kr_new_gen框架的核心功能之一，提供了一系列预定义的业务模板，可以快速生成常见的页面布局和功能。

## 模板列表

### 用户管理模板 (user_management)

**用途**: 用户管理系统页面，采用左树右表布局

**特性**:
- 组织架构树（左侧）
- 用户列表表格（右侧）
- 树表联动功能
- 搜索表单
- 工具栏操作
- 数据导入导出
- 冻结列支持

**适用场景**:
- 企业用户管理
- 组织架构管理
- 权限管理系统
- 员工信息管理

## 快速开始

### 1. 列出所有可用模板

```ruby
templates = TemplateManager.list_templates
templates.each do |template|
  puts "#{template[:name]} - #{template[:description]}"
end
```

### 2. 获取模板详情

```ruby
template = TemplateManager.get_template('user_management')
puts template['layout']['type']  # => "tree_table_layout"
```

### 3. 生成默认页面

```ruby
# 生成默认的kr标签
kr_tags = TemplateManager.instantiate('user_management')

# 在ERB中使用
<%= kr_tags %>
```

### 4. 自定义配置

```ruby
customizations = {
  'tree_config' => {
    'title' => '我的组织架构',
    'data_source' => {
      'url' => '/api/my_org/tree'
    }
  },
  'table_config' => {
    'title' => '我的用户列表',
    'data_source' => {
      'url' => '/api/my_users'
    },
    'pagination' => {
      'default_limit' => 15
    }
  }
}

kr_tags = TemplateManager.instantiate('user_management', customizations)
```

## 模板配置详解

### 基础结构

每个模板YAML文件包含以下主要部分：

```yaml
# 元数据
metadata:
  id: template_id
  name: "模板名称"
  description: "模板描述"
  version: "1.0.0"

# 布局配置
layout:
  type: tree_table_layout

# 页面配置
page:
  title: "页面标题"

# 树组件配置
tree_config:
  title: "树标题"
  data_source:
    url: "/api/tree"
  features:
    search: true
    toolbar: ["add", "refresh"]

# 表格组件配置
table_config:
  title: "表格标题"
  data_source:
    url: "/api/table"
  features:
    search_form: true
    toolbar: true

# 联动配置
linkage:
  enabled: true
  param: "tree_id"
  type: "click"
```

### 树组件配置 (tree_config)

```yaml
tree_config:
  title: "组织机构"                    # 树标题
  data_source:
    url: "/api/org/tree"             # 数据源URL
    method: "GET"                    # 请求方法
    response_format: "standard"      # 响应格式
  
  features:
    search: true                     # 是否启用搜索
    toolbar: ["add", "refresh"]      # 工具栏按钮
    checkbar: false                  # 是否显示复选框
    contextmenu: true                # 是否启用右键菜单
  
  display:
    show_line: true                  # 是否显示连接线
    accordion: false                 # 是否手风琴模式
    init_level: 2                    # 初始展开层级
    width: "300px"                   # 宽度
    height: "500px"                  # 高度
```

### 表格组件配置 (table_config)

```yaml
table_config:
  title: "用户管理"                   # 表格标题
  data_source:
    url: "/api/users"               # 数据源URL
    method: "GET"                   # 请求方法
  
  pagination:
    enabled: true                   # 是否启用分页
    default_limit: 20               # 默认每页数量
    limits: [10, 20, 50, 100]      # 分页选项
  
  features:
    search_form: true               # 是否启用搜索表单
    toolbar: true                   # 是否显示工具栏
    frozen_cols: 1                  # 冻结列数
    action_col: true                # 是否显示操作列
    checkbox: true                  # 是否显示复选框
    export: true                    # 是否支持导出
    import: true                    # 是否支持导入
  
  columns:                          # 列配置
    - field: "id"
      title: "ID"
      width: 80
      sort: true
      type: "checkbox"
    - field: "name"
      title: "姓名"
      width: 120
      sort: true
```

### 搜索表单配置

```yaml
search_form:
  fields:
    - name: "login_name"
      label: "账号"
      type: "text"
      placeholder: "请输入登录账号"
      width: 120
    - name: "status"
      label: "状态"
      type: "select"
      options:
        - value: ""
          text: "全部"
        - value: "0"
          text: "正常"
        - value: "1"
          text: "停用"
```

### 联动配置 (linkage)

```yaml
linkage:
  enabled: true                     # 是否启用联动
  param: "org_id"                   # 联动参数名
  type: "click"                     # 联动类型
  behavior:
    auto_reload: true               # 自动重新加载
    show_loading: true              # 显示加载状态
    clear_selection: false          # 清除选择
```

## 支持的布局类型

### tree_table_layout

左树右表布局，适用于有层级关系的数据管理。

**特点**:
- 左侧显示树形结构
- 右侧显示表格数据
- 支持树表联动
- 适合组织架构、分类管理等场景

### simple_list

简单列表布局，适用于纯表格数据展示。

**特点**:
- 单一表格展示
- 支持搜索和分页
- 适合简单的数据列表场景

### search_table

搜索表格布局，适用于需要复杂搜索的数据管理。

**特点**:
- 顶部搜索表单
- 下方数据表格
- 支持多条件搜索
- 适合数据查询和筛选场景

## 自定义配置

### 覆盖默认配置

```ruby
customizations = {
  'tree_config' => {
    'title' => '自定义树标题',
    'data_source' => {
      'url' => '/api/custom/tree'
    }
  },
  'table_config' => {
    'title' => '自定义表格标题',
    'pagination' => {
      'default_limit' => 25
    }
  }
}

kr_tags = TemplateManager.instantiate('user_management', customizations)
```

### 深度合并

自定义配置会与模板默认配置进行深度合并，相同键的值会被覆盖。

```ruby
# 原始配置
original = {
  'table_config' => {
    'pagination' => {
      'default_limit' => 20,
      'limits' => [10, 20, 50]
    }
  }
}

# 自定义配置
custom = {
  'table_config' => {
    'pagination' => {
      'default_limit' => 15  # 只覆盖这个值
    }
  }
}

# 结果配置
result = {
  'table_config' => {
    'pagination' => {
      'default_limit' => 15,  # 被覆盖
      'limits' => [10, 20, 50]  # 保持不变
    }
  }
}
```

## 创建新模板

### 1. 创建YAML文件

在 `lib/templates/builtin/` 目录下创建新的YAML文件：

```yaml
# product_management.yml
metadata:
  id: product_management
  name: "产品管理"
  description: "产品分类和产品列表管理"
  version: "1.0.0"

layout:
  type: tree_table_layout

# ... 其他配置
```

### 2. 重新加载模板

```ruby
TemplateManager.reload_templates
```

### 3. 验证模板

```ruby
# 检查模板是否存在
if TemplateManager.template_exists?('product_management')
  puts "模板创建成功"
else
  puts "模板创建失败"
end
```

## API参考

### TemplateManager

#### list_templates

列出所有可用模板。

```ruby
templates = TemplateManager.list_templates
# 返回: [{id: "user_management", name: "用户管理", ...}, ...]
```

#### get_template(template_id)

获取指定模板的配置。

```ruby
template = TemplateManager.get_template('user_management')
# 返回: Hash - 模板配置
```

#### instantiate(template_id, customizations = {})

实例化模板为kr标签。

```ruby
kr_tags = TemplateManager.instantiate('user_management', customizations)
# 返回: String - kr标签字符串
```

#### template_exists?(template_id)

检查模板是否存在。

```ruby
exists = TemplateManager.template_exists?('user_management')
# 返回: Boolean
```

#### reload_templates

重新加载所有模板。

```ruby
TemplateManager.reload_templates
```

### TemplateToKrConverter

#### convert(template_config)

将模板配置转换为kr标签。

```ruby
kr_tags = TemplateToKrConverter.convert(template_config)
# 返回: String - kr标签字符串
```

#### validate_config(config)

验证模板配置的有效性。

```ruby
errors = TemplateToKrConverter.validate_config(config)
# 返回: Array - 错误列表
```

#### supported_layout_types

获取支持的布局类型。

```ruby
types = TemplateToKrConverter.supported_layout_types
# 返回: ["tree_table_layout", "simple_list", "search_table"]
```

## 最佳实践

### 1. 模板设计原则

- **单一职责**: 每个模板专注于一种业务场景
- **配置完整**: 提供合理的默认配置
- **易于定制**: 支持灵活的自定义配置
- **文档完善**: 详细说明模板用途和配置项

### 2. 自定义配置建议

- **最小化覆盖**: 只覆盖需要修改的配置项
- **保持一致性**: 遵循模板的原有设计风格
- **测试验证**: 自定义后测试功能是否正常

### 3. 性能优化

- **懒加载**: 模板只在需要时加载
- **缓存机制**: 避免重复解析YAML文件
- **内存管理**: 及时释放不用的模板数据

## 故障排除

### 常见问题

**Q: 模板加载失败怎么办？**

A: 检查YAML文件格式是否正确，确保所有必需字段都存在。

**Q: 自定义配置不生效？**

A: 检查配置键名是否正确，确保使用正确的嵌套结构。

**Q: 生成的kr标签格式错误？**

A: 检查模板配置的布局类型是否支持，验证必需配置项是否存在。

### 调试方法

```ruby
# 开启调试模式
ENV['DEBUG'] = 'true'

# 查看模板加载日志
TemplateManager.load_builtin_templates

# 验证模板配置
errors = TemplateToKrConverter.validate_config(template_config)
puts errors if errors.any?

# 测试转换过程
begin
  kr_tags = TemplateManager.instantiate('user_management')
  puts "转换成功: #{kr_tags}"
rescue => e
  puts "转换失败: #{e.message}"
  puts e.backtrace.first(5)
end
```

## 更新日志

### v1.0.0 (2025-10-11)

- 初始版本发布
- 支持用户管理模板
- 实现模板管理器
- 支持kr标签转换
- 提供完整的API和文档

## 参考

- [组件配置系统文档](./component_config_system.md)
- [API参考文档](./tree_table_api_reference.md)
- [实施总结](./implementation_summary.md)

