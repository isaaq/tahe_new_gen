# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Submit; end

module Plugins
  module Strategy
    module Submit
      class ManualPublishStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'submit', 'manual'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: operator_id" unless params[:operator_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 手动提交逻辑
          document_id = params[:document_id]
          operator_id = params[:operator_id]
          collection = params[:collection] || 'documents'

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 更新文档状态为已提交
          update_result = collection_obj.update_one(
            { _id: BSON::ObjectId(document_id) },
            { '$set' => { status: 'submitted', submitted_at: Time.now, operator_id: operator_id } }
          )

          { success: true, updated_count: update_result.modified_count, message: "文档已手动提交" }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

