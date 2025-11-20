# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Save; end

module Plugins
  module Strategy
    module Save
      class AuditSaveStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'save', 'audit'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 审计保存逻辑
          data = params[:data] || {}
          collection = params[:collection] || 'documents'
          operator_id = params[:operator_id]

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 保存数据
          result = collection_obj.insert_one(data)

          # 记录审计日志
          db['audit_logs'].insert_one({
            action: 'save',
                    document_id: result.inserted_id.to_s,
            collection: collection,
            operator_id: operator_id,
            data_snapshot: data,
            created_at: Time.now
          })

          { success: true, document_id: result.inserted_id.to_s, message: "文档已保存并记录审计日志" }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

