# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class CascadeValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'cascade'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 级联验证逻辑
          data = params[:data] || {}
          validation_rules = params[:validation_rules] || {}
          related_collections = params[:related_collections] || []

          errors = []

          # 验证主数据
          validation_rules.each do |field, rules|
            field_value = data[field]
            if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
              errors << { field: field, message: "#{field} 是必填字段" }
            end
          end

          # 级联验证关联数据
          if errors.empty? && !related_collections.empty?
            db = Common::M.database
            related_collections.each do |collection_name|
              foreign_key = params[:foreign_key] || 'document_id'
              related_data = db[collection_name].find({ foreign_key.to_sym => data[:_id] || data['_id'] }).to_a

              related_data.each do |related_item|
                related_rules = params[:related_validation_rules] || {}
                related_rules.each do |field, rules|
                  field_value = related_item[field.to_sym] || related_item[field.to_s]
                  if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
                    errors << {
                      field: "#{collection_name}.#{field}",
                      message: "#{collection_name} 的 #{field} 是必填字段"
                    }
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

