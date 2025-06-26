require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Save; end

module Plugins
  module Strategy
    module Save
      class DraftSaveStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'save', 'draft'
        
        def before_execute(params = {})
          # 验证必要参数
          raise "缺少必要参数: data" unless params[:data]
          
          # 添加草稿标记
          params[:data][:_draft] = true
          params[:data][:_draft_time] = Time.now
        end
        
        def perform(params = {})
          data = params[:data]
          collection = params[:collection] || 'drafts'
          
          # 使用 MongoDB 存储草稿数据
          result = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')[collection].insert_one(data)
          
          # 返回结果
          {
            success: true,
            draft_id: result.inserted_id.to_s,
            message: "草稿已保存"
          }
        end
        
        def after_execute(params = {}, result = nil)
          # 记录日志
          puts "草稿已保存: #{result[:draft_id]}" if result && result[:success]
        end
      end
    end
  end
end
