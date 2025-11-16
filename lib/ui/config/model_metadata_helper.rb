# frozen_string_literal: true

# 模型元数据辅助类
# 用于从模型定义中提取字段类型、枚举值等信息，避免硬编码
class ModelMetadataHelper
  class << self
    # 缓存已加载的模型元数据
    @model_cache = {}
    
    # 从模型获取枚举值
    # @param collection_name [String, Symbol] 集合名称，如 :org_employees
    # @param field_name [String, Symbol] 字段名称，如 'gender'
    # @return [Array<Hash>, nil] 枚举值数组 [{value: 0, label: '男'}, ...] 或 nil
    def get_enum_values(collection_name, field_name)
      model_class = find_model_by_collection(collection_name)
      return nil unless model_class
      
      field_info = find_field_info(model_class, field_name)
      return nil unless field_info
      
      # 检查是否是枚举类型
      if field_info[:type] == 'Enum' && field_info[:values]
        # 转换为标准格式 [{value: 0, label: '男'}, ...]
        field_info[:values].map.with_index do |label, idx|
          { value: idx, label: label }
        end
      else
        nil
      end
    end
    
    # 从模型获取字段类型
    # @param collection_name [String, Symbol] 集合名称
    # @param field_name [String, Symbol] 字段名称
    # @return [String, nil] 字段类型，如 'Text', 'Enum', 'Link' 等
    def get_field_type(collection_name, field_name)
      model_class = find_model_by_collection(collection_name)
      return nil unless model_class
      
      field_info = find_field_info(model_class, field_name)
      field_info ? field_info[:type] : nil
    end
    
    # 从模型获取关联信息
    # @param collection_name [String, Symbol] 集合名称
    # @param field_name [String, Symbol] 字段名称
    # @return [Hash, nil] 关联信息 {link_to: 'MOrgDepartment'} 或 nil
    def get_link_info(collection_name, field_name)
      model_class = find_model_by_collection(collection_name)
      return nil unless model_class
      
      field_info = find_field_info(model_class, field_name)
      return nil unless field_info
      
      if field_info[:type] == 'Link' && field_info[:link_to]
        {
          link_to: field_info[:link_to],
          link_to_collection: get_collection_name_from_model(field_info[:link_to])
        }
      else
        nil
      end
    end
    
    # 获取所有字段信息
    # @param collection_name [String, Symbol] 集合名称
    # @return [Array<Hash>] 字段信息数组
    def get_all_fields(collection_name)
      model_class = find_model_by_collection(collection_name)
      return [] unless model_class
      
      model_class.respond_to?(:fields) ? model_class.fields : []
    end
    
    # 清除缓存
    def clear_cache!
      @model_cache = {}
    end
    
    private
    
    # 根据集合名查找模型类
    # @param collection_name [String, Symbol] 集合名称
    # @return [Class, nil] 模型类
    def find_model_by_collection(collection_name)
      collection_sym = collection_name.to_sym
      
      # 从缓存返回
      return @model_cache[collection_sym] if @model_cache.key?(collection_sym)
      
      # 扫描所有模型类
      model_class = ObjectSpace.each_object(Class)
        .select { |c| c.respond_to?(:表名) }
        .find { |c| c.表名 == collection_sym }
      
      # 缓存结果（即使是nil）
      @model_cache[collection_sym] = model_class
      
      model_class
    end
    
    # 从模型类中查找字段信息
    # @param model_class [Class] 模型类
    # @param field_name [String, Symbol] 字段名称
    # @return [Hash, nil] 字段信息
    def find_field_info(model_class, field_name)
      return nil unless model_class.respond_to?(:fields)
      
      field_name_str = field_name.to_s
      model_class.fields.find { |f| f[:name]&.to_s == field_name_str }
    end
    
    # 从模型类名获取集合名称
    # @param model_class_name [String] 模型类名，如 'MOrgDepartment'
    # @return [Symbol, nil] 集合名称
    def get_collection_name_from_model(model_class_name)
      begin
        model_class = Object.const_get(model_class_name)
        model_class.respond_to?(:表名) ? model_class.表名 : nil
      rescue NameError
        nil
      end
    end
  end
end

