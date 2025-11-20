# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class RangeValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'range'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 范围验证逻辑
          data = params[:data] || {}
          range_rules = params[:range_rules] || {}

          errors = []

          range_rules.each do |field, range_config|
            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil?

            min_value = range_config[:min]
            max_value = range_config[:max]
            numeric_value = field_value.to_f

            if min_value && numeric_value < min_value
              errors << { field: field, message: "#{field} 不能小于 #{min_value}" }
            elsif max_value && numeric_value > max_value
              errors << { field: field, message: "#{field} 不能大于 #{max_value}" }
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

