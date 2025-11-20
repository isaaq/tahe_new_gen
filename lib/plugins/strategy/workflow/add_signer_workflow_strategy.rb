# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Workflow; end

module Plugins
  module Strategy
    module Workflow
      class AddSignerWorkflowStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'workflow', 'process', 'add_signer'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: approver_id" unless params[:approver_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 加签工作流逻辑
          document_id = params[:document_id]
          workflow_id = params[:workflow_id] || document_id
          approver_id = params[:approver_id]

          return { success: false, message: "审批人未指定" } unless approver_id

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 添加审批人
          db['workflow_signers'].insert_one({
            workflow_id: workflow_id,
            document_id: document_id,
            approver_id: approver_id,
            status: 'pending',
            created_at: Time.now
          })

          # 更新工作流签批人列表
          db['workflows'].update_one(
            { _id: BSON::ObjectId(workflow_id) },
            { '$addToSet' => { signers: approver_id } }
          )

          { success: true, message: "已添加审批人", approver_id: approver_id }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

