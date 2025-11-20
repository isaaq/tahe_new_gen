# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Workflow; end

module Plugins
  module Strategy
    module Workflow
      class SubProcessWorkflowStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'workflow', 'process', 'sub_process'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          raise "缺少必要参数: sub_process_id" unless params[:sub_process_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 子流程工作流逻辑
          workflow_id = params[:workflow_id]
          sub_process_config = params[:sub_process_config] || {}

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 创建子流程实例
          sub_workflow = db['workflows'].insert_one({
            parent_workflow_id: workflow_id,
            type: 'sub_process',
            config: sub_process_config,
            status: 'active',
            created_at: Time.now
          })

          { success: true, message: "子流程已启动", sub_workflow_id: sub_workflow.inserted_id.to_s }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

