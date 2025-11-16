# frozen_string_literal: true

# 模板到kr标签转换器
# 将YAML模板配置转换为kr标签
class TemplateToKrConverter
  # 转换模板配置为kr标签
  def self.convert(template_config)
    layout_type = template_config['layout']['type']
    
    case layout_type
    when 'tree_table_layout'
      convert_tree_table_layout(template_config)
    when 'simple_list'
      convert_simple_list(template_config)
    when 'search_table'
      convert_search_table(template_config)
    else
      raise "不支持的布局类型: #{layout_type}"
    end
  end
  
  private
  
  # 转换树表联动布局
  def self.convert_tree_table_layout(config)
    tree_config = extract_tree_config(config)
    table_config = extract_table_config(config)
    linkage_config = extract_linkage_config(config)
    
    # 构建kr标签属性
    kr_attrs = build_tree_table_attributes(tree_config, table_config, linkage_config)
    
    # 生成kr标签
    generate_kr_tag('tree_table_layout', kr_attrs)
  end
  
  # 转换简单列表布局
  def self.convert_simple_list(config)
    table_config = extract_table_config(config)
    kr_attrs = build_simple_table_attributes(table_config)
    
    generate_kr_tag('datatable', kr_attrs)
  end
  
  # 转换搜索表格布局
  def self.convert_search_table(config)
    table_config = extract_table_config(config)
    search_config = extract_search_config(config)
    kr_attrs = build_search_table_attributes(table_config, search_config)
    
    generate_kr_tag('search_table', kr_attrs)
  end
  
  # 提取树配置
  def self.extract_tree_config(config)
    tree_config = config['tree_config'] || {}
    
    {
      'title' => tree_config['title'] || '分类',
      'url' => tree_config.dig('data_source', 'url') || '/api/tree',
      'search' => tree_config.dig('features', 'search') ? 'true' : 'false',
      'toolbar' => extract_toolbar_buttons(tree_config),
      'checkbar' => tree_config.dig('features', 'checkbar') ? 'true' : 'false',
      'contextmenu' => tree_config.dig('features', 'contextmenu') ? 'true' : 'false'
    }
  end
  
  # 提取表格配置
  def self.extract_table_config(config)
    table_config = config['table_config'] || {}
    
    {
      'title' => table_config['title'] || '数据列表',
      'url' => table_config.dig('data_source', 'url') || '/api/table',
      'page' => table_config.dig('pagination', 'enabled') ? 'true' : 'false',
      'limit' => table_config.dig('pagination', 'default_limit') || 10,
      'frozen-cols' => table_config.dig('features', 'frozen_cols') || 0,
      'action-col' => table_config.dig('features', 'action_col') ? 'true' : 'false',
      'toolbar' => table_config.dig('features', 'toolbar') ? 'true' : 'false',
      'checkbox' => table_config.dig('features', 'checkbox') ? 'true' : 'false',
      'columns' => extract_table_columns(table_config)
    }
  end
  
  # 提取联动配置
  def self.extract_linkage_config(config)
    linkage_config = config['linkage'] || {}
    
    {
      'link_param' => linkage_config['param'] || 'tree_id',
      'link_type' => linkage_config['type'] || 'click'
    }
  end
  
  # 提取搜索配置
  def self.extract_search_config(config)
    search_form = config.dig('table_config', 'search_form') || {}
    search_form['fields'] || []
  end
  
  # 提取工具栏按钮
  def self.extract_toolbar_buttons(tree_config)
    buttons = tree_config.dig('features', 'toolbar') || []
    return '' if buttons.empty?
    
    # 映射按钮名称
    button_map = {
      'add' => 'add',
      'refresh' => 'refresh',
      'expand' => 'expand',
      'collapse' => 'collapse'
    }
    
    mapped_buttons = buttons.map { |btn| button_map[btn] || btn }.compact
    mapped_buttons.join(',')
  end
  
  # 提取表格列配置
  def self.extract_table_columns(table_config)
    columns = table_config['columns'] || []
    
    # 转换列配置格式
    columns.map do |col|
      column_config = {}
      
      # 基础属性
      column_config['field'] = col['field'] if col['field']
      column_config['title'] = col['title'] if col['title']
      column_config['width'] = col['width'] if col['width']
      column_config['sort'] = col['sort'] if col['sort']
      column_config['fixed'] = col['fixed'] if col['fixed']
      column_config['type'] = col['type'] if col['type']
      
      column_config
    end
  end
  
  # 构建树表联动属性
  def self.build_tree_table_attributes(tree_config, table_config, linkage_config)
    attrs = {}
    
    # 树配置属性
    attrs.merge!(prefix_attrs(tree_config, 'tree_'))
    
    # 表格配置属性
    attrs.merge!(prefix_attrs(table_config, 'table_'))
    
    # 联动配置属性
    attrs.merge!(linkage_config)
    
    attrs
  end
  
  # 构建简单表格属性
  def self.build_simple_table_attributes(table_config)
    # 移除tree_前缀，直接使用表格配置
    table_config
  end
  
  # 构建搜索表格属性
  def self.build_search_table_attributes(table_config, search_config)
    attrs = table_config.dup
    
    # 添加搜索表单配置
    if search_config.any?
      attrs['search_fields'] = search_config.to_json
    end
    
    attrs
  end
  
  # 为属性添加前缀
  def self.prefix_attrs(config, prefix)
    prefixed = {}
    config.each do |key, value|
      prefixed["#{prefix}#{key}"] = value
    end
    prefixed
  end
  
  # 生成kr标签
  def self.generate_kr_tag(tag_name, attrs)
    # 构建属性字符串
    attrs_string = attrs.map do |key, value|
      case value
      when String
        "#{key}='#{value}'"
      when Array, Hash
        "#{key}='#{value.to_json}'"
      when true
        "#{key}='true'"
      when false
        "#{key}='false'"
      else
        "#{key}=#{value}"
      end
    end.join(' ')
    
    # 生成自闭合标签
    "<kr:#{tag_name} #{attrs_string} />"
  end
  
  # 验证配置
  def self.validate_config(config)
    errors = []
    
    # 检查必需的布局配置
    unless config['layout'] && config['layout']['type']
      errors << "缺少布局类型配置"
    end
    
    # 检查树表联动布局的必需配置
    if config.dig('layout', 'type') == 'tree_table_layout'
      unless config['tree_config']
        errors << "树表联动布局缺少树配置"
      end
      
      unless config['table_config']
        errors << "树表联动布局缺少表格配置"
      end
    end
    
    errors
  end
  
  # 获取支持的布局类型
  def self.supported_layout_types
    %w[tree_table_layout simple_list search_table]
  end
  
  # 检查布局类型是否支持
  def self.supports_layout_type?(layout_type)
    supported_layout_types.include?(layout_type)
  end
end

