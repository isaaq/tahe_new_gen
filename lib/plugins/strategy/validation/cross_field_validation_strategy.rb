# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class CrossFieldValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'cross_field'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 跨字段验证逻辑
          data = params[:data] || {}
          cross_field_rules = params[:cross_field_rules] || []

          errors = []

          # 执行跨字段验证规则
          cross_field_rules.each do |rule|
            fields = rule[:fields] || []
            validator = rule[:validator]
            message = rule[:message] || '跨字段验证失败'

            if validator.respond_to?(:call)
              field_values = fields.map { |f| data[f.to_sym] || data[f.to_s] }
              unless validator.call(*field_values, data)
                errors << { fields: fields, message: message }
              end
            elsif rule[:type] == 'equal'
              # 字段值必须相等
              values = fields.map { |f| data[f.to_sym] || data[f.to_s] }
              unless values.uniq.size == 1
                errors << { fields: fields, message: "#{fields.join(', ')} 的值必须相等" }
              end
            elsif rule[:type] == 'sum'
              # 字段值之和必须等于指定值
              sum = fields.sum { |f| (data[f.to_sym] || data[f.to_s] || 0).to_f }
              expected_sum = rule[:expected_sum]
              if expected_sum && (sum - expected_sum).abs > 0.01
                errors << { fields: fields, message: "#{fields.join(' + ')} 的和必须等于 #{expected_sum}" }
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

