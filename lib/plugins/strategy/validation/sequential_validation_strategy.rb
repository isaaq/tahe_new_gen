# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class SequentialValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'sequential'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: validators" unless params[:validators]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 顺序验证逻辑
          data = params[:data] || {}
          validators = params[:validators] || []

          errors = []

          validators.each do |validator|
            if validator.respond_to?(:call)
              result = validator.call(data)
              unless result == true || (result.is_a?(Hash) && result[:success])
                errors << { validator: validator.to_s, message: result.to_s }
                break  # 顺序验证，遇到错误就停止
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

