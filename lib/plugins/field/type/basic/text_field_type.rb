# frozen_string_literal: true

require_relative '../../../field_type/base_field_type'

module Plugins
  module FieldType
    module Basic
      class TextFieldType < ::Plugins::FieldType::BaseFieldType
        field_type_for 'text'
        
        def initialize(name, options = {})
          super(name, :text, options)
        end
        
        def validate(value)
          # 必填验证
          if required? && (value.nil? || value.to_s.empty?)
            return [false, "#{@name} 不能为空"]
          end
          
          # 类型特定验证
          unless value.is_a?(String)
  return [false, "#{@name} 必须是字符串"]
end

if @options[:min_length] && value.length < @options[:min_length]
  return [false, "#{@name} 长度不能小于 #{@options[:min_length]}"]
end

if @options[:max_length] && value.length > @options[:max_length]
  return [false, "#{@name} 长度不能超过 #{@options[:max_length]}"]
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

