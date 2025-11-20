# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class LengthValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'length'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 长度验证逻辑
          data = params[:data] || {}
          length_rules = params[:length_rules] || {}

          errors = []

          length_rules.each do |field, length_config|
            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil?

            min_length = length_config[:min]
            max_length = length_config[:max]
            exact_length = length_config[:exact]
            value_length = field_value.to_s.length

            if exact_length && value_length != exact_length
              errors << { field: field, message: "#{field} 长度必须为 #{exact_length}" }
            elsif min_length && value_length < min_length
              errors << { field: field, message: "#{field} 长度不能小于 #{min_length}" }
            elsif max_length && value_length > max_length
              errors << { field: field, message: "#{field} 长度不能超过 #{max_length}" }
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

