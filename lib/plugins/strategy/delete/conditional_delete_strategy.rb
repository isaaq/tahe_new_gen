# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Delete; end

module Plugins
  module Strategy
    module Delete
      class ConditionalDeleteStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'delete', 'conditional'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: condition" unless params[:condition]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 条件删除
          document_id = params[:document_id]
          collection = params[:collection] || 'documents'
          conditions = params[:conditions] || {}

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 构建查询条件
          query = { _id: BSON::ObjectId(document_id) }.merge(conditions)

          # 检查条件是否满足
          document = collection_obj.find_one(query)
          unless document
            return { success: false, message: "文档不存在或条件不满足" }
          end

          # 删除文档
          delete_result = collection_obj.delete_one(query)

          {
            success: true,
            deleted_count: delete_result.deleted_count,
            message: "文档已删除"
                  }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

