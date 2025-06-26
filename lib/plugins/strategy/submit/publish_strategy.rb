require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Submit; end

module Plugins
  module Strategy
    module Submit
      class PublishStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'submit', 'publish'
        
        def before_execute(params = {})
          # 验证必要参数
          raise "缺少必要参数: document_id" unless params[:document_id]
        end
        
        def perform(params = {})
          document_id = params[:document_id]
          collection = params[:collection] || 'documents'
          
          # 获取文档
          client = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')
          document = client[collection].find({ _id: BSON::ObjectId.from_string(document_id.to_s) }).first
          
          raise "未找到文档: #{document_id}" unless document
          
          # 更新文档状态为已发布
          result = client[collection].update_one(
            { _id: BSON::ObjectId.from_string(document_id.to_s) },
            { "$set" => { 
                status: 'published', 
                published_at: Time.now,
                _published: true
              } 
            }
          )
          
          {
            success: result.modified_count > 0,
            document_id: document_id,
            message: "文档已发布"
          }
        end
        
        def after_execute(params = {}, result = nil)
          if result && result[:success]
            puts "文档已发布: #{result[:document_id]}"
            
            # 这里可以添加发布后的额外操作，如发送通知等
          end
        end
      end
    end
  end
end
