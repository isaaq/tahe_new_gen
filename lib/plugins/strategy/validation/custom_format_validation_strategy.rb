# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class CustomFormatValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'format_custom'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          raise "缺少必要参数: pattern" unless params[:pattern]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 验证逻辑
          data = params[:data] || {}
          validation_rules = params[:validation_rules] || {}

          errors = []

          # 实现具体的验证逻辑
          validation_rules.each do |field, rules|
            field_value = data[field]
            if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
              errors << { field: field, message: "#{field} 是必填字段" }
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

