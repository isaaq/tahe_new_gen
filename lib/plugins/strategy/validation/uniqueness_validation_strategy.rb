# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class UniquenessValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'uniqueness'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 唯一性验证逻辑
          data = params[:data] || {}
          uniqueness_rules = params[:uniqueness_rules] || {}

          errors = []

          uniqueness_rules.each do |field, uniqueness_config|
            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil? || field_value.to_s.empty?

            scope = uniqueness_config[:scope] || []
            collection = params[:collection] || 'documents'

            # 构建查询条件
            query = { field.to_sym => field_value }
            scope.each do |scope_field|
              scope_value = data[scope_field.to_sym] || data[scope_field.to_s]
              query[scope_field.to_sym] = scope_value if scope_value
            end

            # 检查是否已存在
            db = Common::M.database
            existing = db[collection].find_one(query)
            if existing && existing['_id'].to_s != (data[:_id] || data['_id']).to_s
              scope_msg = scope.empty? ? '' : " (在 #{scope.join(', ')} 范围内)"
              errors << { field: field, message: "#{field} 的值必须唯一#{scope_msg}" }
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

