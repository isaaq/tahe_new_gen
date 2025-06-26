require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Save; end

module Plugins
  module Strategy
    module Save
      class NormalSaveStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'document', 'save', 'normal'
        
        def before_execute(params = {})
          # 验证必要参数
          raise "缺少必要参数: data" unless params[:data]
          
          # 添加正常保存标记
          params[:data][:_draft] = false
          params[:data][:_updated_at] = Time.now
        end
        
        def perform(params = {})
          data = params[:data]
          collection = params[:collection] || 'documents'
          
          # 使用 MongoDB 存储数据
          if data[:_id]
            # 更新现有文档
            id = data.delete(:_id)
            result = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')[collection].update_one(
              { _id: BSON::ObjectId.from_string(id.to_s) },
              { "$set" => data }
            )
            
            {
              success: result.modified_count > 0,
              document_id: id.to_s,
              message: "文档已更新"
            }
          else
            # 创建新文档
            result = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')[collection].insert_one(data)
            
            {
              success: true,
              document_id: result.inserted_id.to_s,
              message: "文档已保存"
            }
          end
        end
        
        def after_execute(params = {}, result = nil)
          # 记录日志
          if result && result[:success]
            puts "文档已保存: #{result[:document_id]}"
          end
        end
      end
    end
  end
end
