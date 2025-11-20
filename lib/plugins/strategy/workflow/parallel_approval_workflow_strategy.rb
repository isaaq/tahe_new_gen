# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Workflow; end

module Plugins
  module Strategy
    module Workflow
      class ParallelApprovalWorkflowStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'workflow', 'process', 'parallel_approval'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: approver_ids" unless params[:approver_ids]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 并行审批工作流逻辑
          workflow_id = params[:workflow_id] || params[:document_id]
          approvers = params[:approvers] || []
          action_type = params[:action] || 'approve'
          approver_id = params[:approver_id]

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 获取工作流
          workflow = db['workflows'].find_one({ _id: BSON::ObjectId(workflow_id) })
          return { success: false, message: "工作流不存在" } unless workflow

          # 记录审批结果
          db['workflow_approvals'].insert_one({
            workflow_id: workflow_id,
            approver_id: approver_id,
            action: action_type,
            created_at: Time.now
          })

          # 检查是否所有审批人都已审批
          approval_count = db['workflow_approvals'].count_documents({ workflow_id: workflow_id, action: 'approve' })
          if approval_count >= approvers.size
            # 所有审批人已通过
            db['workflows'].update_one(
              { _id: BSON::ObjectId(workflow_id) },
              { '$set' => { status: 'approved', completed_at: Time.now } }
            )
            { success: true, message: "并行审批已完成", approval_count: approval_count, total: approvers.size }
          else
            { success: true, message: "审批已记录", approval_count: approval_count, total: approvers.size }
          end
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

