# frozen_string_literal: true

require_relative '../../../field_type/base_field_type'

module Plugins
  module FieldType
    module Special
      class Base64FieldType < ::Plugins::FieldType::BaseFieldType
        field_type_for 'base64'
        
        def initialize(name, options = {})
          super(name, :base64, options)
        end
        
        def validate(value)
          # 必填验证
          if required? && (value.nil? || value.to_s.empty?)
            return [false, "#{@name} 不能为空"]
          end
          
          # 类型特定验证
          # 自定义验证逻辑
          
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

