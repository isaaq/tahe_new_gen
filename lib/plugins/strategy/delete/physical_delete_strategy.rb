# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Delete; end

module Plugins
  module Strategy
    module Delete
      class PhysicalDeleteStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'delete', 'physical'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 物理删除（硬删除）
          document_id = params[:document_id]
          collection = params[:collection] || 'documents'

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 物理删除文档
          delete_result = collection_obj.delete_one({ _id: BSON::ObjectId(document_id) })

          {
            success: true,
            deleted_count: delete_result.deleted_count,
            message: "文档已物理删除"
          }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

