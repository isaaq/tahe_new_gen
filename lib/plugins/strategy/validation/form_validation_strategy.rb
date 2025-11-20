# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class FormValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'form'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 表单验证逻辑
          data = params[:data] || {}
          validation_rules = params[:validation_rules] || {}

          errors = []

          # 遍历验证规则
          validation_rules.each do |field_name, rules|
            value = data[field_name.to_sym] || data[field_name.to_s]

            # 必填验证
            if rules[:required] && (value.nil? || value.to_s.strip.empty?)
              errors << { field: field_name, message: "#{field_name} 不能为空" }
              next
            end

            next if value.nil? || value.to_s.strip.empty?

            # 类型验证
            if rules[:type] && !value.is_a?(rules[:type])
              errors << { field: field_name, message: "#{field_name} 类型不正确" }
            end

            # 长度验证
            if rules[:min_length] && value.to_s.length < rules[:min_length]
              errors << { field: field_name, message: "#{field_name} 长度不能小于 #{rules[:min_length]}" }
            end

            if rules[:max_length] && value.to_s.length > rules[:max_length]
              errors << { field: field_name, message: "#{field_name} 长度不能超过 #{rules[:max_length]}" }
            end

            # 正则验证
            if rules[:pattern] && !value.to_s.match?(rules[:pattern])
              errors << { field: field_name, message: "#{field_name} 格式不正确" }
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

