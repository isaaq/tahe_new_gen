# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class BusinessLogicValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'business_logic'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 业务逻辑验证
          data = params[:data] || {}
          business_rules = params[:business_rules] || []

          errors = []

          # 执行业务规则验证
          business_rules.each do |rule|
            if rule.respond_to?(:call)
              result = rule.call(data)
              unless result == true || (result.is_a?(Hash) && result[:success])
                errors << { rule: rule.to_s, message: result.is_a?(Hash) ? result[:message] : result.to_s }
              end
            elsif rule.is_a?(Hash)
              # 基于规则的业务逻辑验证
              condition = rule[:condition]
              message = rule[:message] || '业务规则验证失败'
              if condition.respond_to?(:call) && !condition.call(data)
                errors << { rule: rule[:name] || 'business_rule', message: message }
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

