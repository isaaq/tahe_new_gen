# frozen_string_literal: true

require_relative 'builtin/field'
require_relative 'builtin/text'
require_relative 'builtin/enum'
require_relative 'custom/date_range_field'
require_relative 'custom/coordinate_field'
require_relative 'custom/number_range_field'

# 字段类型注册器
class FieldRegistry
  @@field_types = {}
  
  # 注册内置和自定义字段类型
  def self.register_default_types
    # 注册内置类型
    register('field', Field)
    register('text', Text)
    register('enum', Enum)
    
    # 注册自定义类型
    register('date_range', DateRangeField)
    register('coordinate', CoordinateField)
    register('number_range', NumberRangeField)
  end
  
  # 注册新的字段类型
  def self.register(type_name, field_class)
    @@field_types[type_name.to_s] = field_class
  end
  
  # 获取字段类型类
  def self.get_type(type_name)
    @@field_types[type_name.to_s] || Field
  end
  
  # 创建字段实例
  def self.create_field(type_name, options = {})
    field_class = get_type(type_name)
    field_class.new(options)
  end
  
  # 获取所有注册的字段类型
  def self.all_types
    @@field_types.keys
  end
  
  # 检测字段类型
  def self.detect_field_type(key, value)
    # 首先检查字段名称的后缀
    field_type = nil
    
    # 遍历所有注册的字段类型
    @@field_types.each do |type_name, field_class|
      # 调用字段类的类型检测方法（如果实现了）
      if field_class.respond_to?(:can_handle?) && field_class.can_handle?(key, value)
        field_type = type_name
        break
      end
    end
    
    field_type
  end
  
  # 处理字段数据
  def self.process_field(field_type, data, key, value)
    field_class = get_type(field_type)
    if field_class.respond_to?(:process_data)
      # 如果字段类实现了process_data方法，则使用它
      field_class.process_data(data, key, value)
    else
      # 否则使用默认处理方式
      field = create_field(field_type)
      if value.is_a?(Hash)
        field.from_db(value)
      else
        field.value = value
      end
      data[key] = field.value
    end
  end
  
  # 处理查询条件
  def self.process_query(field_key, query_value)
    # 检查所有注册的字段类型，查找能处理该查询的类型
    @@field_types.each do |type_name, field_class|
      # 如果字段类实现了can_process_query?和process_query方法
      if field_class.respond_to?(:can_process_query?) && 
         field_class.respond_to?(:process_query) && 
         field_class.can_process_query?(field_key, query_value)
        # 调用字段类的查询处理方法
        return field_class.process_query(field_key, query_value)
      end
    end
    
    # 如果没有找到可以处理该查询的字段类型，返回空
    return nil
  end
end

# 初始化注册默认类型
FieldRegistry.register_default_types
