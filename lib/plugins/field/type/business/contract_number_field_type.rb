# frozen_string_literal: true

require_relative '../../../field_type/base_field_type'

module Plugins
  module FieldType
    module Business
      class ContractNumberFieldType < ::Plugins::FieldType::BaseFieldType
        field_type_for 'contract_number'
        
        def initialize(name, options = {})
          super(name, :contract_number, options)
        end
        
        def validate(value)
          # 必填验证
          if required? && (value.nil? || value.to_s.empty?)
            return [false, "#{@name} 不能为空"]
          end
          
          # 类型特定验证
          unless value.is_a?(Numeric)
  return [false, "#{@name} 必须是数字"]
end

if @options[:min] && value < @options[:min]
  return [false, "#{@name} 不能小于 #{@options[:min]}"]
end

if @options[:max] && value > @options[:max]
  return [false, "#{@name} 不能大于 #{@options[:max]}"]
end

          
          [true, nil]
        end
        
        def to_mongo(value)
          # 转换为MongoDB存储格式
          value
        end
        
        def from_mongo(value)
          # 从MongoDB格式转换
          value
        end
        
        def to_ui(value)
          # 转换为UI显示格式
          value
        end
      end
    end
  end
end

