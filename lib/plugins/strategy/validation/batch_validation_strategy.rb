# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class BatchValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'batch'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data_list" unless params[:data_list]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 异步/批量验证逻辑
          data_list = params[:data_list] || [params[:data]].compact
          validation_rules = params[:validation_rules] || {}

          all_errors = []
          validated_count = 0

          data_list.each_with_index do |data, index|
            errors = []

            validation_rules.each do |field, rules|
              field_value = data[field.to_sym] || data[field.to_s]
              if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
                errors << { field: field, message: "#{field} 是必填字段", index: index }
              end
            end

            if errors.empty?
              validated_count += 1
            else
              all_errors.concat(errors)
            end
          end

          if all_errors.empty?
            { success: true, valid: true, validated_count: validated_count, total: data_list.size }
          else
            { success: false, valid: false, errors: all_errors, validated_count: validated_count, total: data_list.size }
          end
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

