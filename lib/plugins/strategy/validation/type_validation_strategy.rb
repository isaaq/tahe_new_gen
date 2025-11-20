# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class TypeValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'type'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 类型验证逻辑
          data = params[:data] || {}
          type_rules = params[:type_rules] || {}

          errors = []

          type_rules.each do |field, type_config|
            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil?

            expected_type = type_config[:type]
            allow_nil = type_config[:allow_nil] || false

            unless allow_nil && field_value.nil?
              case expected_type.to_s
              when 'string', 'String'
                unless field_value.is_a?(String)
                  errors << { field: field, message: "#{field} 必须是字符串类型" }
                end
              when 'integer', 'Integer', 'int'
                unless field_value.is_a?(Integer) || (field_value.is_a?(String) && field_value.match?(/^-?d+$/))
                  errors << { field: field, message: "#{field} 必须是整数类型" }
                end
              when 'float', 'Float', 'number', 'Numeric'
                unless field_value.is_a?(Numeric) || (field_value.is_a?(String) && field_value.match?(/^-?d+(.d+)?$/))
                  errors << { field: field, message: "#{field} 必须是数字类型" }
                end
              when 'boolean', 'Boolean', 'bool'
                unless [true, false].include?(field_value) || ['true', 'false'].include?(field_value.to_s.downcase)
                  errors << { field: field, message: "#{field} 必须是布尔类型" }
                end
              when 'array', 'Array'
                unless field_value.is_a?(Array)
                  errors << { field: field, message: "#{field} 必须是数组类型" }
                end
              when 'hash', 'Hash', 'object', 'Object'
                unless field_value.is_a?(Hash)
                  errors << { field: field, message: "#{field} 必须是对象类型" }
                end
              end
            end
          end

          if errors.empty?
            { success: true, valid: true }
          else
            { success: false, valid: false, errors: errors }
          end
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

