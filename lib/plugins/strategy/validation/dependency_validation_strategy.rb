# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class DependencyValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'dependency'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 依赖验证逻辑
          data = params[:data] || {}
          dependency_rules = params[:dependency_rules] || []

          errors = []

          # 验证字段依赖关系
          dependency_rules.each do |rule|
            dependent_field = rule[:dependent_field]
            depends_on_field = rule[:depends_on_field]
            condition = rule[:condition] || ->(dep_value) { !dep_value.nil? && !dep_value.to_s.empty? }

            depends_on_value = data[depends_on_field.to_sym] || data[depends_on_field.to_s]
            dependent_value = data[dependent_field.to_sym] || data[dependent_field.to_s]

            # 如果依赖字段满足条件，则被依赖字段必须存在
            if condition.respond_to?(:call) && condition.call(depends_on_value)
              if dependent_value.nil? || dependent_value.to_s.empty?
                errors << {
                  field: dependent_field,
                  message: "#{dependent_field} 依赖于 #{depends_on_field}，当 #{depends_on_field} 存在时，#{dependent_field} 必须填写"
                }
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

