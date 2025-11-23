# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class ReferentialValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'referential'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 引用完整性验证逻辑
          data = params[:data] || {}
          referential_rules = params[:referential_rules] || []

          errors = []

          referential_rules.each do |rule|
            field = rule[:field]
            reference_collection = rule[:collection]
            reference_field = rule[:reference_field] || '_id'

            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil? || field_value.to_s.empty?

            # 验证引用是否存在
            db = Common::M.database
            referenced = db[reference_collection].find_one({ reference_field.to_sym => field_value })
            unless referenced
              errors << { field: field, message: "#{field} 引用的记录在 #{reference_collection} 中不存在" }
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

