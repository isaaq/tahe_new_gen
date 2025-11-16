# frozen_string_literal: true

class KrNodeBuilder
  include Common
  
  # 构建 kr 标签的 AST 结构
  def self.build(content)
    builder = new
    builder.parse(content)
  end
  
  def initialize
    @context = {}
    @current_scope = nil
  end
  
  def parse(content)
    return {} if content.nil? || content.empty?
    
    # 解析 krnode 文件内容
    # 这里假设内容是 JSON 或 YAML 格式的配置
    begin
      if content.strip.start_with?('{') || content.strip.start_with?('[')
        # JSON 格式
        config = JSON.parse(content, symbolize_names: true)
      else
        # YAML 格式
        config = YAML.safe_load(content, symbolize_names: true)
      end
      
      build_context(config)
    rescue => e
      __p "解析 krnode 内容失败: #{e.message}"
      {}
    end
  end
  
  private
  
  def build_context(config)
    context = {}
    
    # 处理页面级配置
    if config[:page]
      context[:page] = build_page_context(config[:page])
    end
    
    # 处理表单配置
    if config[:forms]
      context[:forms] = {}
      config[:forms].each do |form_id, form_config|
        context[:forms][form_id.to_sym] = build_form_context(form_config)
      end
    end
    
    # 处理表格配置
    if config[:tables]
      context[:tables] = {}
      config[:tables].each do |table_id, table_config|
        context[:tables][table_id.to_sym] = build_table_context(table_config)
      end
    end
    
    # 处理字段配置
    if config[:fields]
      context[:fields] = {}
      config[:fields].each do |field_name, field_config|
        context[:fields][field_name.to_sym] = build_field_context(field_config)
      end
    end
    
    context
  end
  
  def build_page_context(page_config)
    {
      title: page_config[:title] || 'Untitled Page',
      layout: page_config[:layout] || 'default',
      scripts: page_config[:scripts] || [],
      styles: page_config[:styles] || [],
      meta: page_config[:meta] || {}
    }
  end
  
  def build_form_context(form_config)
    {
      model: form_config[:model],
      action: form_config[:action],
      method: form_config[:method] || 'POST',
      layout: form_config[:layout] || 'horizontal',
      fields: form_config[:fields] || [],
      validation: form_config[:validation] || {},
      submit_options: form_config[:submit_options] || {}
    }
  end
  
  def build_table_context(table_config)
    {
      source: table_config[:source],
      columns: build_columns_context(table_config[:columns] || []),
      pagination: table_config[:pagination] || false,
      row_actions: table_config[:row_actions] || [],
      checkbox: table_config[:checkbox] || false,
      search: table_config[:search] || false,
      export: table_config[:export] || false
    }
  end
  
  def build_columns_context(columns)
    columns.map do |col|
      {
        field: col[:field],
        title: col[:title],
        width: col[:width],
        align: col[:align] || 'left',
        sort: col[:sort] || false,
        filter: col[:filter] || false,
        formatter: col[:formatter],
        template: col[:template]
      }
    end
  end
  
  def build_field_context(field_config)
    {
      type: field_config[:type] || 'text',
      label: field_config[:label],
      name: field_config[:name],
      required: field_config[:required] || false,
      placeholder: field_config[:placeholder],
      default_value: field_config[:default_value],
      options: field_config[:options] || [],
      validation: field_config[:validation] || {},
      attributes: field_config[:attributes] || {}
    }
  end
end