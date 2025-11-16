# frozen_string_literal: true

require 'singleton'

# 组件配置注册表
# 负责管理 kr → l 标签的配置转换映射器
# 与 Strategy、FieldRegistry 并列的基础设施
class ComponentConfigRegistry
  include Singleton
  
  def initialize
    @mappers = {}
    @processors = {}
  end
  
  # 注册配置映射器
  def self.register_mapper(component_type, mapper_class)
    instance.send(:register_mapper, component_type, mapper_class)
  end
  
  # 注册AI处理器（可选）
  def self.register_processor(component_type, processor)
    instance.send(:register_processor, component_type, processor)
  end
  
  # 转换kr配置到l配置
  def self.transform(component_type, kr_attrs, context = {})
    instance.send(:transform, component_type, kr_attrs, context)
  end
  
  private
  
  def register_mapper(component_type, mapper_class)
    @mappers[component_type.to_s] = mapper_class
    puts "已注册配置映射器: #{component_type} => #{mapper_class}" if dev?
  end
  
  def register_processor(component_type, processor)
    @processors[component_type.to_s] = processor
    puts "已注册AI处理器: #{component_type} => #{processor}" if dev?
  end
  
  def transform(component_type, kr_attrs, context = {})
    mapper = @mappers[component_type.to_s]
    raise "未注册的组件类型: #{component_type}" unless mapper
    
    # 1. 基础映射（约定俗成的默认值）
    l_attrs = mapper.map_defaults(kr_attrs)
    
    # 2. 条件映射（规则引擎）
    l_attrs = mapper.map_conditional(kr_attrs, l_attrs)
    
    # 3. 上下文推断（智能补全）
    l_attrs = mapper.infer_from_context(l_attrs, context)
    
    # 4. AI增强（可选，预留接口）
    if processor = @processors[component_type.to_s]
      l_attrs = processor.enhance(l_attrs, context)
    end
    
    l_attrs
  end
  
  def dev?
    defined?(Rails) ? Rails.env.development? : true
  end
end

