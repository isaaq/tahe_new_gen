# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class CustomValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'custom'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: validator" unless params[:validator]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 自定义验证逻辑
          data = params[:data] || {}
          validator = params[:validator]

          return { success: false, message: "验证器未指定" } unless validator

          # 调用自定义验证器
          if validator.respond_to?(:call)
            result = validator.call(data)
            if result.is_a?(Hash)
              result
            elsif result == true
              { success: true, valid: true }
            else
              { success: false, valid: false, errors: [{ message: result.to_s }] }
            end
          else
            { success: false, message: "验证器必须是可调用的对象" }
          end
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

