# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Submit; end

module Plugins
  module Strategy
    module Submit
      class RollbackPublishStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'submit', 'rollback'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: version" unless params[:version]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 回滚发布逻辑
          document_id = params[:document_id]
          target_version = params[:version] || params[:target_version]
          collection = params[:collection] || 'documents'

          return { success: false, message: "目标版本未指定" } unless target_version

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 查找目标版本
          version_doc = db['document_versions'].find_one({
            document_id: document_id,
            version: target_version.to_s
          })

          return { success: false, message: "目标版本不存在" } unless version_doc

          # 恢复文档内容
          version_data = version_doc['data'] || {}
          update_result = collection_obj.update_one(
            { _id: BSON::ObjectId(document_id) },
            { '$set' => version_data.merge({
              status: 'published',
              rolled_back_to: target_version,
              rolled_back_at: Time.now
            }) }
          )

          { success: true, updated_count: update_result.modified_count, version: target_version, message: "发布已回滚" }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

