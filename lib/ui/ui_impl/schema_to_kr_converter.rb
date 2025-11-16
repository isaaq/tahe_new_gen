# frozen_string_literal: true

require_relative '../config/model_metadata_helper'

class SchemaToKrConverter
  def self.convert(schema, options = {})
    new(schema, options).convert
  end
  
  def initialize(schema, options = {})
    @schema = schema.is_a?(String) ? YAML.load(schema) : schema
    @options = options
  end
  
  def convert
    case @schema['type']
    when 'datamanage'
      convert_datamanage_schema
    when 'crud'
      convert_crud_schema
    else
      raise "Unsupported schema type: #{@schema['type']}"
    end
  end
  
  private
  
  def convert_datamanage_schema
    collection = @schema['data']
    fields = @schema['fields'] || []
    actions = @schema['actions'] || ['list', 'view', 'add', 'edit', 'delete']
    layout = @schema['layout'] || 'auto'
    relations = @schema['relations'] || []
    
    if layout == 'auto' || layout == 'tree_table'
      # 树表布局
      generate_tree_table_layout(collection, fields, relations)
    else
      # 搜索表格布局
      generate_search_table(collection, fields, relations, actions)
    end
  end
  
  def convert_crud_schema
    # 类似datamanage，但包含完整的CRUD功能
    convert_datamanage_schema
  end
  
  def generate_tree_table_layout(collection, fields, relations)
    tree_source = find_tree_source(collection, relations)
    
    result = "<kr:tree_table_layout\n"
    result += "  tree_title=\"分类\"\n"
    result += "  tree_source=\"#{tree_source}\"\n"
    result += "  table_title=\"#{collection}列表\"\n"
    result += "  table_source=\"/api/#{collection}/list\"\n"
    result += "  link_param=\"#{collection}_id\">\n"
    result += "  #{generate_table_columns(collection, fields, relations)}\n"
    result += "  <kr:row-actions>\n"
    result += "    <kr:action name=\"view\" label=\"查看\" />\n"
    result += "    <kr:action name=\"edit\" label=\"编辑\" />\n"
    result += "    <kr:action name=\"delete\" label=\"删除\" confirm=\"确认删除？\" />\n"
    result += "  </kr:row-actions>\n"
    result += "</kr:tree_table_layout>\n"
    result
  end
  
  def generate_search_table(collection, fields, relations, actions)
    result = "<kr:search_table\n"
    result += "  table_title=\"#{collection}管理\"\n"
    result += "  table_source=\"/api/#{collection}/list\"\n"
    result += "  page=\"true\">\n"
    result += "  #{generate_search_fields(collection, fields)}\n"
    result += "  #{generate_table_columns(collection, fields, relations)}\n"
    result += "  <kr:row-actions>\n"
    result += "    #{generate_actions(actions)}\n"
    result += "  </kr:row-actions>\n"
    result += "</kr:search_table>\n"
    result
  end
  
  def generate_table_columns(collection, fields, relations)
    return '' if fields.empty?
    
    # 从模型获取字段信息
    all_fields = ModelMetadataHelper.get_all_fields(collection.to_sym) rescue []
    
    fields.map do |field_name|
      field_info = all_fields.find { |f| f[:name].to_s == field_name.to_s } || {}
      relation_info = relations.find { |r| r['name'] == field_name || r['field'] == field_name }
      
      generate_column_tag(field_name, field_info, relation_info, collection)
    end.join("\n        ")
  end
  
  def generate_column_tag(field_name, field_info, relation_info, collection)
    title = field_info[:display_name] || field_name.to_s.humanize
    width = infer_column_width(field_info)
    
    if relation_info
      # 关联字段
      result = "<kr:col \n"
      result += "  title=\"#{title}\" \n"
      result += "  field=\"#{field_name}\" \n"
      result += "  relation=\"#{relation_info['name'] || extract_relation_name(field_name)}\"\n"
      result += "  relation_field=\"#{relation_info['display_field'] || 'name'}\"\n"
      result += "  width=\"#{width}\" />\n"
      result
    elsif field_info[:type] == 'Enum'
      # 枚举字段
      enum_values = ModelMetadataHelper.get_enum_values(
        collection.to_sym,
        field_name
      ) rescue []
      enum_str = enum_values&.map { |v| v[:label] }&.join(',') || ''
      
      result = "<kr:col \n"
      result += "  title=\"#{title}\" \n"
      result += "  field=\"#{field_name}\" \n"
      result += "  enum=\"#{enum_str}\"\n"
      result += "  width=\"#{width}\" />\n"
      result
    else
      # 普通字段
      result = "<kr:col \n"
      result += "  title=\"#{title}\" \n"
      result += "  field=\"#{field_name}\" \n"
      result += "  width=\"#{width}\" />\n"
      result
    end
  end
  
  def generate_search_fields(collection, fields)
    # 生成搜索表单字段
    searchable_fields = fields.first(3)  # 只显示前3个字段作为搜索条件
    
    searchable_fields.map do |field_name|
      result = "<kr:search_field \n"
      result += "  name=\"#{field_name}\" \n"
      result += "  label=\"#{field_name.to_s.humanize}\" \n"
      result += "  type=\"input\" />\n"
      result
    end.join("  ")
  end
  
  def generate_actions(actions)
    action_tags = []
    action_tags << '<kr:action name="view" label="查看" />' if actions.include?('view')
    action_tags << '<kr:action name="edit" label="编辑" />' if actions.include?('edit')
    action_tags << '<kr:action name="delete" label="删除" confirm="确认删除？" />' if actions.include?('delete')
    action_tags.join("\n          ")
  end
  
  def find_tree_source(collection, relations)
    # 查找合适的树数据源（通常是分类或组织）
    tree_relation = relations.find { |r| 
      r['type'] == 'belongs_to' && 
      (r['name'].to_s.include?('category') || r['name'].to_s.include?('org') || r['name'].to_s.include?('tree'))
    }
    
    tree_relation ? "/api/#{tree_relation['collection']}/tree" : "/api/#{collection}/tree"
  end
  
  def extract_relation_name(field_name)
    field_name.to_s.sub(/_id(s)?$/, '')
  end
  
  def infer_column_width(field_info)
    case field_info[:type]
    when 'Text' then 200
    when 'Number' then 120
    when 'Date', 'DateTime' then 180
    when 'Enum' then 100
    when 'Link' then 150
    else 150
    end
  end
end

