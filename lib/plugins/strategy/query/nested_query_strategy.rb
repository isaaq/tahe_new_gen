# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Query; end

module Plugins
  module Strategy
    module Query
      class NestedQueryStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'query', 'nested'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 嵌套查询逻辑
          query = params[:query] || {}
          nested_path = params[:nested_path] || params[:path]
          nested_query = params[:nested_query] || {}
          collection = params[:collection] || 'documents'

          return { success: false, message: "嵌套路径未指定" } unless nested_path

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 构建嵌套查询
          mongo_query = query.dup
          mongo_query["#{nested_path}"] = nested_query

          # 执行嵌套查询
          results = collection_obj.find(mongo_query).to_a

          { success: true, data: results, count: results.size, nested_path: nested_path }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

