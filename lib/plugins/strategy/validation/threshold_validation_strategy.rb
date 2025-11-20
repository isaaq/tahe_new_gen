# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class ThresholdValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'threshold'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 阈值验证逻辑
          data = params[:data] || {}
          threshold_rules = params[:threshold_rules] || {}

          errors = []

          threshold_rules.each do |field, threshold_config|
            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil?

            min_threshold = threshold_config[:min]
            max_threshold = threshold_config[:max]
            numeric_value = field_value.to_f

            if min_threshold && numeric_value < min_threshold
              errors << { field: field, message: "#{field} 不能低于阈值 #{min_threshold}" }
            elsif max_threshold && numeric_value > max_threshold
              errors << { field: field, message: "#{field} 不能超过阈值 #{max_threshold}" }
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

