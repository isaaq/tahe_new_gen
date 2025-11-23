# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Workflow; end

module Plugins
  module Strategy
    module Workflow
      class ReturnWorkflowStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'workflow', 'process', 'return'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: target_node" unless params[:target_node]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 退回工作流逻辑
          workflow_id = params[:workflow_id]
          return_to = params[:return_to]
          comment = params[:comment] || ''

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 记录退回操作
          db['workflow_returns'].insert_one({
            workflow_id: workflow_id,
            return_to: return_to,
            comment: comment,
            returned_by: params[:operator_id],
            created_at: Time.now
          })

          # 更新工作流状态
          db['workflows'].update_one(
            { _id: BSON::ObjectId(workflow_id) },
            { '$set' => { status: 'returned', returned_to: return_to, returned_at: Time.now } }
          )

          { success: true, message: "工作流已退回", return_to: return_to }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

