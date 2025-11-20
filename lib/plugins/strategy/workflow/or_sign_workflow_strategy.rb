# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Workflow; end

module Plugins
  module Strategy
    module Workflow
      class OrSignWorkflowStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'workflow', 'process', 'or_sign'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: approver_ids" unless params[:approver_ids]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 会签/或签工作流逻辑
          workflow_id = params[:workflow_id]
          signers = params[:signers] || []
          is_counter_sign = 'or_sign' == 'counter_sign'

          return { success: false, message: "签批人列表为空" } if signers.empty?

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 为每个签批人创建签批任务
          signers.each do |signer_id|
            db['workflow_sign_tasks'].insert_one({
              workflow_id: workflow_id,
              signer_id: signer_id,
              sign_type: is_counter_sign ? 'counter_sign' : 'or_sign',
              status: 'pending',
              created_at: Time.now
            })
          end

          # 更新工作流状态
          db['workflows'].update_one(
            { _id: BSON::ObjectId(workflow_id) },
            { '$set' => {
              sign_type: is_counter_sign ? 'counter_sign' : 'or_sign',
              signers: signers,
              sign_status: 'pending'
            } }
          )

          { success: true, message: "#{is_counter_sign ? '会签' : '或签'}已执行", signers: signers }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

