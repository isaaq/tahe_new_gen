# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Delete; end

module Plugins
  module Strategy
    module Delete
      class CascadeDeleteStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'delete', 'cascade'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 级联删除逻辑
          document_id = params[:document_id]
          collection = params[:collection] || 'documents'
          related_collections = params[:related_collections] || []
          foreign_key_field = params[:foreign_key_field] || 'document_id'

          # 获取 MongoDB 客户端
          db = Common::M.database
          main_collection = db[collection]

          # 删除主文档
          delete_result = main_collection.delete_one({ _id: BSON::ObjectId(document_id) })

          # 级联删除关联数据
          deleted_count = delete_result.deleted_count
          related_deleted = {}

          related_collections.each do |related_collection_name|
            related_collection = db[related_collection_name]
            related_query = { foreign_key_field.to_sym => document_id }
            related_result = related_collection.delete_many(related_query)
            related_deleted[related_collection_name] = related_result.deleted_count
            deleted_count += related_result.deleted_count
          end

                  {
                    success: true,
            deleted_count: deleted_count,
            main_deleted: delete_result.deleted_count,
            related_deleted: related_deleted,
            message: "文档及关联数据已删除"
          }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

