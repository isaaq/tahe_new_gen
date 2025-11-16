# frozen_string_literal: true

# 字段类型基类
module Plugins
  module FieldType
    class BaseFieldType
      attr_reader :name, :type, :options
      
      def initialize(name, type, options = {})
        @name = name.to_s
        @type = type
        @options = default_options.merge(options)
      end
      
      def required?
        !!@options[:required]
      end
      
      def searchable?
        !!@options[:searchable]
      end
      
      def validate(value)
        # 必填验证
        if required? && (value.nil? || value.to_s.empty?)
          return [false, "#{@name} 不能为空"]
        end
        
        [true, nil]
      end
      
      def to_mongo(value)
        value
      end
      
      def from_mongo(value)
        value
      end
      
      def to_ui(value)
        value
      end
      
      # 字段类型注册方法
      def self.field_type_for(type_name)
        # 注册到字段类型注册表
        if defined?(FieldTypeRegistry)
          FieldTypeRegistry.register(type_name.to_sym, self)
        end
      end
      
      private
      
      def default_options
        {
          required: false,
          searchable: false
        }
      end
    end
  end
end

