# frozen_string_literal: true

# 集合名称辅助类
# 用于统一管理集合名称，避免字符串硬编码
module CollectionHelper
  # 从模型类获取集合名称
  # @param model_class [Class, String] 模型类或类名
  # @return [Symbol, nil] 集合名称
  def self.collection_name(model_class)
    klass = model_class.is_a?(String) ? Object.const_get(model_class) : model_class
    klass.respond_to?(:表名) ? klass.表名 : nil
  rescue NameError
    nil
  end
  
  # 预定义的常用集合名称常量（从模型获取）
  module Collections
    # 组织相关
    def self.orgs
      @orgs ||= CollectionHelper.collection_name('MCOrg') || :c_orgs
    end
    
    def self.departments
      @departments ||= CollectionHelper.collection_name('MOrgDepartment') || :org_departments
    end
    
    def self.positions
      @positions ||= CollectionHelper.collection_name('MOrgPosition') || :org_positions
    end
    
    def self.employees
      @employees ||= CollectionHelper.collection_name('MOrgEmployee') || :org_employees
    end
    
    # 清除缓存
    def self.clear_cache!
      instance_variables.each { |var| remove_instance_variable(var) }
    end
  end
  
  # 便捷方法：直接从模型类名获取集合
  def self.[](model_class_name)
    collection_name(model_class_name)
  end
end

# 扩展到 Common::M，使其支持使用模型类名
module Common
  class << self
    # 允许使用模型类名访问集合
    # 例如：Common::M.for('MOrgEmployee') 等价于 Common::M[:org_employees]
    def self.for(model_class_name)
      collection = CollectionHelper[model_class_name]
      collection ? M[collection] : nil
    end
  end
end if defined?(Common)

