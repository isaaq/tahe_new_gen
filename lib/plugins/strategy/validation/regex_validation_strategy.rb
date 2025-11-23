# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class RegexValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'regex'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          raise "缺少必要参数: pattern" unless params[:pattern]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 正则表达式验证逻辑
          data = params[:data] || {}
          regex_rules = params[:regex_rules] || {}

          errors = []

          regex_rules.each do |field, regex_config|
            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil? || field_value.to_s.empty?

            pattern = regex_config[:pattern]
            message = regex_config[:message] || "#{field} 格式不正确"

            if pattern
              regex = pattern.is_a?(Regexp) ? pattern : Regexp.new(pattern)
              unless field_value.to_s.match?(regex)
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

