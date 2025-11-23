# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class DataIntegrityValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'data_integrity'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 数据完整性验证逻辑
          data = params[:data] || {}
          integrity_rules = params[:integrity_rules] || {}

          errors = []

          # 验证数据完整性
          integrity_rules.each do |rule_type, rule_config|
            case rule_type.to_s
            when 'required_fields'
              required_fields = rule_config[:fields] || []
              required_fields.each do |field|
                field_value = data[field.to_sym] || data[field.to_s]
                if field_value.nil? || field_value.to_s.empty?
                  errors << { field: field, message: "#{field} 是必填字段" }
                end
              end
            when 'foreign_key'
              # 外键完整性验证
              foreign_key = rule_config[:field]
              reference_collection = rule_config[:collection]
              if foreign_key && reference_collection
                db = Common::M.database
                foreign_key_value = data[foreign_key.to_sym] || data[foreign_key.to_s]
                if foreign_key_value
                  referenced = db[reference_collection].find_one({ _id: BSON::ObjectId(foreign_key_value) })
                  unless referenced
                    errors << { field: foreign_key, message: "#{foreign_key} 引用的记录不存在" }
                  end
                end
              end
            when 'unique'
              # 唯一性验证
              unique_fields = rule_config[:fields] || []
              unique_fields.each do |field|
                field_value = data[field.to_sym] || data[field.to_s]
                if field_value
                  db = Common::M.database
                  collection = params[:collection] || 'documents'
                  existing = db[collection].find_one({ field.to_sym => field_value })
                  if existing && existing['_id'].to_s != (data[:_id] || data['_id']).to_s
                    errors << { field: field, message: "#{field} 的值必须唯一" }
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

