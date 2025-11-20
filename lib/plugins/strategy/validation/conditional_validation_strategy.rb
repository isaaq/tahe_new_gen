# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class ConditionalValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'conditional'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: condition" unless params[:condition]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 条件验证逻辑
          data = params[:data] || {}
          condition = params[:condition]
          validation_rules = params[:validation_rules] || {}

          errors = []

          # 检查条件是否满足
          condition_met = true
          if condition.respond_to?(:call)
            condition_met = condition.call(data)
          elsif condition.is_a?(Hash)
            condition.each do |field, expected_value|
              actual_value = data[field.to_sym] || data[field.to_s]
              unless actual_value == expected_value
                condition_met = false
                break
              end
            end
          end

          # 只有在条件满足时才执行验证
          if condition_met
            validation_rules.each do |field, rules|
              field_value = data[field]
              if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
                errors << { field: field, message: "#{field} 是必填字段" }
              end
            end
          end

          if errors.empty?
            { success: true, valid: true, condition_met: condition_met }
          else
            { success: false, valid: false, errors: errors, condition_met: condition_met }
          end
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

