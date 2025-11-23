# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Workflow; end

module Plugins
  module Strategy
    module Workflow
      class CompensateWorkflowStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'workflow', 'process', 'compensate'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 补偿工作流逻辑
          workflow_id = params[:workflow_id]
          compensation_action = params[:compensation_action] || {}

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 记录补偿操作
          db['workflow_compensations'].insert_one({
            workflow_id: workflow_id,
            action: compensation_action,
            created_at: Time.now
          })

          # 更新工作流状态
          db['workflows'].update_one(
            { _id: BSON::ObjectId(workflow_id) },
            { '$set' => { compensated: true, compensated_at: Time.now } }
          )

          { success: true, message: "补偿操作已执行" }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

