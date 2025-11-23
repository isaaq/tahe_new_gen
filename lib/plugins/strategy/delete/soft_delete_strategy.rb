# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Delete; end

module Plugins
  module Strategy
    module Delete
      class SoftDeleteStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'delete', 'soft'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 逻辑删除（软删除）
          document_id = params[:document_id]
          collection = params[:collection] || 'documents'
          deleted_field = params[:deleted_field] || 'deleted_at'

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 更新文档，标记为已删除
          update_result = collection_obj.update_one(
            { _id: BSON::ObjectId(document_id) },
            { '$set' => { deleted_field.to_sym => Time.now } }
          )

          {
            success: true,
            updated_count: update_result.modified_count,
            message: "文档已逻辑删除"
          }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

