# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Save; end

module Plugins
  module Strategy
    module Save
      class VersionSaveStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'save', 'version'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 版本保存逻辑
          data = params[:data] || {}
          collection = params[:collection] || 'documents'
          version = params[:version] || '1.0'

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 保存数据
          result = collection_obj.insert_one(data)

          # 保存版本记录
          db['document_versions'].insert_one({
            document_id: result.inserted_id.to_s,
            version: version.to_s,
            data: data,
            created_at: Time.now
          })

          { success: true, document_id: result.inserted_id.to_s, version: version, message: "文档已保存并创建版本" }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

