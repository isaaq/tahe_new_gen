# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class BusinessRuleValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'business_rule'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 业务规则验证
          data = params[:data] || {}
          rules = params[:rules] || []

          errors = []

          rules.each do |rule|
            field = rule[:field]
            condition = rule[:condition]
            message = rule[:message] || "#{field} 不符合业务规则"

            field_value = data[field.to_sym] || data[field.to_s]

            if condition.respond_to?(:call)
              unless condition.call(field_value, data)
                errors << { field: field, message: message }
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

