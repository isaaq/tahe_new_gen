# 组件配置注册系统文档

## 概述

组件配置注册系统（ComponentConfigRegistry）是kr_new_gen框架的核心基础设施之一，专门负责UI组件配置的智能转换。它与Strategy插件、FieldRegistry并列，分别处理业务逻辑、数据层和UI层的可扩展性。

## 架构定位

```
┌─────────────────────────────────────┐
│      kr_new_gen 框架基础设施        │
├─────────────────────────────────────┤
│ Strategy插件      → 业务逻辑可插拔  │
│ FieldRegistry     → 字段类型管理    │
│ ComponentConfigRegistry → UI配置转换│
└─────────────────────────────────────┘
```

## 核心功能

### 1. 粗粒度到细粒度的配置转换

将框架无关的kr标签（5-10个属性）智能转换为框架特定的l标签（30+属性）。

**示例**：
```ruby
# kr标签（粗粒度）
<kr:tree url="/api/org" search="true" toolbar="add,refresh" />

# 转换后的l标签（细粒度）
<l:tree
  url="/api/org"
  method="post"
  skin="laySimple"
  iconStyle="dtreefont"
  initLevel="1"
  dataFormat="list"
  dataStyle="layuiStyle"
  width="100%"
  height="500px"
  toolbar="true"
  toolbarWay="follow"
  toolbarShow="['searchIcon']"
  toolbarExt="[{menubarId: 'btn-add', ...}, {menubarId: 'btn-refresh', ...}]"
  response="{statusName: 'code', statusCode: 0, ...}"
/>
```

### 2. 四层配置转换机制

```
kr属性 → ComponentConfigRegistry.transform(type, kr_attrs, context)
           ↓
       1. 默认值映射 (map_defaults)
           ↓
       2. 条件规则映射 (map_conditional)
           ↓
       3. 上下文推断 (infer_from_context)
           ↓
       4. AI增强（可选） (enhance)
           ↓
       l属性（完整配置）
```

## 使用方法

### 1. 注册配置映射器

**文件**: `lib/ui/config/_init.rb`

```ruby
require_relative 'component_config_registry'
require_relative 'mappers/tree_config_mapper'
require_relative 'mappers/datatable_config_mapper'

# 注册配置映射器
ComponentConfigRegistry.register_mapper('tree', TreeConfigMapper)
ComponentConfigRegistry.register_mapper('datatable', DatatableConfigMapper)
```

### 2. 创建配置映射器

**文件**: `lib/ui/config/mappers/tree_config_mapper.rb`

```ruby
class TreeConfigMapper
  # 1. 默认配置（约定俗成）
  DEFAULTS = {
    skin: 'laySimple',
    iconStyle: 'dtreefont',
    initLevel: 1,
    dataFormat: 'list',
    method: 'post'
  }.freeze
  
  # 2. 条件配置（规则引擎）
  CONDITIONAL_RULES = {
    search_true: {
      toolbar: true,
      toolbarWay: 'follow',
      toolbarShow: "['searchIcon']"
    }
  }.freeze
  
  # 3. 上下文配置（智能推断）
  CONTEXT_RULES = {
    org_tree: {
      accordion: true,
      initLevel: 2
    }
  }.freeze
  
  # 基础映射
  def self.map_defaults(kr_attrs)
    config = DEFAULTS.dup
    config[:url] = kr_attrs['url']
    config
  end
  
  # 条件映射
  def self.map_conditional(kr_attrs, base_config)
    config = base_config.dup
    
    if kr_attrs['search'] == 'true'
      config.merge!(CONDITIONAL_RULES[:search_true])
    end
    
    if kr_attrs['toolbar']
      buttons = kr_attrs['toolbar'].split(',')
      config[:toolbarExt] = build_toolbar_config(buttons)
    end
    
    config
  end
  
  # 上下文推断
  def self.infer_from_context(config, context)
    url = config[:url].to_s
    
    if url.include?('org')
      config.merge!(CONTEXT_RULES[:org_tree])
    end
    
    if context[:scenario] == 'tree_table_layout'
      config[:width] ||= '300px'
      config[:height] ||= '500px'
    end
    
    config
  end
end
```

### 3. 在Item类中使用配置系统

**文件**: `lib/ui/ui_impl/layui/source/tree_table_layout_item.rb`

```ruby
class TreeTableLayoutItem < LayuiElement
  def output_tag
    # 提取kr配置
    tree_kr_attrs = extract_tree_config
    table_kr_attrs = extract_table_config
    
    # 构建上下文
    context = {
      scenario: 'tree_table_layout',
      parent_component: self,
      linkage: true
    }
    
    # 使用配置注册表转换（核心步骤）
    tree_l_attrs = ComponentConfigRegistry.transform('tree', tree_kr_attrs, context)
    table_l_attrs = ComponentConfigRegistry.transform('datatable', table_kr_attrs, context)
    
    # 生成l标签
    tree_html = generate_l_tree(tree_l_attrs)
    table_html = generate_l_datatable(table_l_attrs)
    linkage_script = generate_linkage_script
    
    layout_wrapper(tree_html, table_html, linkage_script)
  end
end
```

## 配置上下文（Context）

上下文是配置推断的重要依据：

```ruby
context = {
  scenario: 'tree_table_layout',  # 使用场景
  parent_component: self,          # 父组件引用
  linkage: true,                   # 是否联动
  tree_title: '分类',              # 业务语义
  table_title: '数据列表'
}
```

### 常见场景类型

| 场景 | 说明 | 配置影响 |
|------|------|----------|
| `single_tree` | 独立树组件 | 默认配置 |
| `single_table` | 独立表格 | 默认配置 |
| `tree_table_layout` | 树表联动 | 调整尺寸、启用联动 |
| `search_table` | 搜索表格 | 增加搜索配置 |
| `crud_table` | CRUD表格 | 增加工具栏、操作列 |

## AI配置增强（可选）

### 1. 启用AI增强

**文件**: `lib/ui/config/_init.rb`

```ruby
# 检查AI是否可用
if AIConfigEnhancer.ai_enabled?
  ComponentConfigRegistry.register_processor('tree', AIConfigEnhancer)
  ComponentConfigRegistry.register_processor('datatable', AIConfigEnhancer)
end
```

### 2. AI增强工作流程

```
规则引擎生成的配置
    ↓
AIConfigEnhancer.enhance(config, context)
    ↓
1. 构建提示词（基于config和context）
2. 调用LLM服务
3. 解析AI建议
4. 合并到配置中（不覆盖现有配置）
    ↓
最终优化的配置
```

### 3. AI提示词示例

```
你是一个UI组件配置专家。请根据以下信息为Layui树组件提供配置建议：

当前配置：
{"url": "/api/org", "skin": "laySimple", "initLevel": 1}

上下文信息：
- 数据源URL: /api/org
- 使用场景: tree_table_layout
- 是否联动: 是

请分析并建议以下配置项（只输出JSON，不要其他文字）：
- initLevel: 合适的初始展开层级
- accordion: 是否使用手风琴模式
- width/height: 合适的尺寸
- 其他优化建议

建议格式：{"initLevel": 2, "accordion": true, "width": "300px"}
```

## 配置优先级

当多个来源提供相同配置时，优先级如下：

```
用户显式指定 > AI增强 > 上下文推断 > 条件规则 > 默认值
```

## 扩展新组件

要为新组件添加配置支持：

### 步骤1：创建配置映射器

```ruby
# lib/ui/config/mappers/my_component_config_mapper.rb
class MyComponentConfigMapper
  DEFAULTS = { ... }
  
  def self.map_defaults(kr_attrs)
    # 实现默认值映射
  end
  
  def self.map_conditional(kr_attrs, base_config)
    # 实现条件规则
  end
  
  def self.infer_from_context(config, context)
    # 实现上下文推断
  end
end
```

### 步骤2：注册映射器

```ruby
# lib/ui/config/_init.rb
ComponentConfigRegistry.register_mapper('my_component', MyComponentConfigMapper)
```

### 步骤3：在Item类中使用

```ruby
class MyComponentItem < LayuiElement
  def output_tag
    kr_attrs = extract_attributes
    l_attrs = ComponentConfigRegistry.transform('my_component', kr_attrs, context)
    generate_output(l_attrs)
  end
end
```

## 最佳实践

### 1. 默认值设计

- 遵循框架官方文档的推荐配置
- 选择最常用的选项作为默认值
- 考虑性能和用户体验的平衡

### 2. 条件规则设计

- 规则应该简单明确
- 避免规则之间的冲突
- 规则应该有清晰的业务语义

### 3. 上下文推断设计

- 基于URL模式推断（如 `/api/org` → 组织树）
- 基于场景推断（如 `tree_table_layout` → 调整尺寸）
- 基于父组件推断（如父组件是Modal → 调整高度）

### 4. 性能优化

- 配置映射器的方法应该是纯函数
- 避免在映射过程中进行数据库查询
- 缓存常用的配置模板

## 调试和排错

### 启用调试模式

```ruby
# 在开发环境中查看配置转换过程
ComponentConfigRegistry.instance.instance_variable_set(:@debug, true)
```

### 常见问题

**Q: 配置没有生效怎么办？**
A: 检查配置优先级，用户显式指定的配置会覆盖自动生成的配置。

**Q: 如何验证配置映射器的输出？**
A: 在映射器方法中添加日志，或者使用单元测试验证。

**Q: AI增强不工作怎么办？**
A: 检查LLM服务是否配置正确，`AIConfigEnhancer.ai_enabled?` 是否返回 true。

## 参考

- [Layui Tree API文档](https://www.layui.com/demo/tree.html)
- [Layui Table API文档](https://www.layui.com/demo/table.html)
- [策略模式文档](./kr_new_gen_plugin_strategy.md)
- [字段注册表文档](./field_type_and_registry.md)

