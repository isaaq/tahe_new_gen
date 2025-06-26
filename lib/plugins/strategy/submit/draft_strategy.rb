require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Submit; end

module Plugins
  module Strategy
    module Submit
      class DraftStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'submit', 'draft'
        
        def before_execute(params = {})
          # 验证必要参数
          raise "缺少必要参数: draft_id" unless params[:draft_id]
        end
        
        def perform(params = {})
          draft_id = params[:draft_id]
          draft_collection = params[:draft_collection] || 'drafts'
          target_collection = params[:target_collection] || 'documents'
          
          # 从草稿集合中获取草稿
          client = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')
          draft = client[draft_collection].find({ _id: BSON::ObjectId.from_string(draft_id.to_s) }).first
          
          raise "未找到草稿: #{draft_id}" unless draft
          
          # 移除草稿标记
          draft.delete('_draft')
          draft.delete('_draft_time')
          draft['_submitted_at'] = Time.now
          
          # 保存到目标集合
          result = client[target_collection].insert_one(draft)
          
          # 删除原草稿
          client[draft_collection].delete_one({ _id: BSON::ObjectId.from_string(draft_id.to_s) })
          
          {
            success: true,
            document_id: result.inserted_id.to_s,
            message: "草稿已提交并转为正式文档"
          }
        end
        
        def after_execute(params = {}, result = nil)
          if result && result[:success]
            puts "草稿已提交为正式文档: #{result[:document_id]}"
          end
        end
      end
    end
  end
end
