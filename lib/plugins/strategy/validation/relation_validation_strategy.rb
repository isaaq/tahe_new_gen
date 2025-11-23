# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class RelationValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'relation'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 关联验证逻辑
          data = params[:data] || {}
          relation_rules = params[:relation_rules] || []

          errors = []

          relation_rules.each do |rule|
            relation_type = rule[:type]
            fields = rule[:fields] || []

            case relation_type.to_s
            when 'one_to_one'
              # 一对一关系验证
              if fields.size == 2
                field1_value = data[fields[0].to_sym] || data[fields[0].to_s]
                field2_value = data[fields[1].to_sym] || data[fields[1].to_s]
                if field1_value && field2_value
                  db = Common::M.database
                  collection = params[:collection] || 'documents'
                  existing = db[collection].find_one({ fields[0].to_sym => field1_value, fields[1].to_sym => field2_value })
                  if existing && existing['_id'].to_s != (data[:_id] || data['_id']).to_s
                    errors << { fields: fields, message: "一对一关系已存在" }
                  end
                end
              end
            when 'one_to_many'
              # 一对多关系验证（通常不需要验证，但可以检查数量限制）
              field = rule[:field]
              max_count = rule[:max_count]
              if field && max_count
                db = Common::M.database
                related_collection = rule[:related_collection]
                if related_collection
                  count = db[related_collection].count_documents({ field.to_sym => data[:_id] || data['_id'] })
                  if count > max_count
                    errors << { field: field, message: "#{field} 关联数量不能超过 #{max_count}" }
                  end
                end
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

