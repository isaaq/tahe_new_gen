# frozen_string_literal: true

require 'erb'

# 插件文档生成器
class PluginDocGenerator
  DOC_TEMPLATE = <<~'TEMPLATE'
# <%= @name %>

## 基本信息

- **插件ID**: `<%= @plugin_id %>`
- **分类**: `<%= @category %>`
- **版本**: `<%= @version %>`
- **作者**: `<%= @author %>`

## 描述

<%= @description %>

## 使用方法

### 基本用法

<%= @basic_usage %>

### 配置选项

<%= @config_options %>

## 示例

<%= @examples %>

## API参考

<%= @api_reference %>
  TEMPLATE
  
  def generate_doc(plugin_metadata)
    @name = plugin_metadata[:name] || plugin_metadata[:class_name]
    @plugin_id = plugin_metadata[:plugin_id]
    @category = plugin_metadata[:category]
    @version = plugin_metadata[:version] || '1.0.0'
    @author = plugin_metadata[:author] || 'kr_new_gen_team'
    @description = plugin_metadata[:description] || '暂无描述'
    @basic_usage = generate_basic_usage(plugin_metadata)
    @config_options = generate_config_options(plugin_metadata)
    @examples = generate_examples(plugin_metadata)
    @api_reference = generate_api_reference(plugin_metadata)
    
    ERB.new(DOC_TEMPLATE, trim_mode: '-').result(binding)
  end
  
  private
  
  def generate_basic_usage(metadata)
    metadata_type = metadata[:type].to_s
    
    if metadata_type == 'strategy'
      domain = metadata[:domain] || 'document'
      action = metadata[:action] || 'save'
      context = metadata[:context] || 'default'
      code = <<~CODE
strategy = Strategy.resolve(
  domain: '#{domain}',
  action: '#{action}',
  context: '#{context}'
)

result = strategy.execute(
  data: { /* 数据 */ },
  collection: 'documents'
)
      CODE
      "```ruby\n#{code}```"
    elsif metadata_type == 'field_type'
      class_name = metadata[:class_name] || 'FieldType'
      code = <<~CODE
field = #{class_name}.new('field_name', {
  required: true,
  # 其他选项
})

valid, error = field.validate(value)
      CODE
      "```ruby\n#{code}```"
    else
      '请参考插件代码'
    end
  end
  
  def generate_config_options(metadata)
    if metadata[:config_schema] && metadata[:config_schema][:fields]
      options = metadata[:config_schema][:fields].map do |field|
        "- `#{field[:name]}` (#{field[:type]}): #{field[:description] || ''} #{field[:required] ? '(必填)' : '(可选)'}"
      end.join("\n")
      options.empty? ? '无配置选项' : options
    else
      '无配置选项'
    end
  end
  
  def generate_examples(metadata)
    if metadata[:examples] && metadata[:examples].any?
      metadata[:examples].map do |example|
        <<~MARKDOWN
### <%= example[:title] %>

```ruby
<%= example[:code] %>
```
        MARKDOWN
      end.join("\n")
    else
      '暂无示例'
    end
  end
  
  def generate_api_reference(metadata)
    if metadata[:type] == 'strategy'
      <<~MARKDOWN
### 方法

- `before_execute(params)`: 执行前钩子
- `perform(params)`: 执行策略逻辑
- `after_execute(params, result)`: 执行后钩子
      MARKDOWN
    elsif metadata[:type] == 'field_type'
      <<~MARKDOWN
### 方法

- `validate(value)`: 验证字段值
- `to_mongo(value)`: 转换为MongoDB格式
- `from_mongo(value)`: 从MongoDB格式转换
- `to_ui(value)`: 转换为UI显示格式
      MARKDOWN
    else
      '请参考插件代码'
    end
  end
end

