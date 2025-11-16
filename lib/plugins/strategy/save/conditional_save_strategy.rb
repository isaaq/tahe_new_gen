# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Save; end

module Plugins
  module Strategy
    module Save
      class ConditionalSaveStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'save', 'conditional'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: condition" unless params[:condition]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          data = params[:data]
collection = params[:collection] || 'documents'

# 使用 MongoDB 存储数据
result = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')[collection].insert_one(data)

{
  success: true,
  document_id: result.inserted_id.to_s,
  message: "文档已保存"
}

          
          # 返回结果
          {
            success: true,
            
            message: "文档已条件保存"
          }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

