# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Query; end

module Plugins
  module Strategy
    module Query
      class FulltextQueryStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'query', 'fulltext'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: keyword" unless params[:keyword]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 全文搜索逻辑
          keyword = params[:keyword] || params[:query][:keyword]
          collection = params[:collection] || 'documents'

          return { success: false, message: "搜索关键词未指定" } unless keyword

          # 获取 MongoDB 客户端
          db = Common::M.database
          collection_obj = db[collection]

          # 构建全文搜索查询
          search_query = {
            '$text' => { '$search' => keyword }
          }

          # 执行全文搜索
          results = collection_obj.find(search_query).to_a

          { success: true, data: results, count: results.size, keyword: keyword }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

