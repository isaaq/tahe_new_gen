# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Workflow; end

module Plugins
  module Strategy
    module Workflow
      class UrgeWorkflowStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'workflow', 'process', 'urge'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: document_id" unless params[:document_id]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 催办工作流逻辑
          workflow_id = params[:workflow_id]
          message = params[:urge_message] || '请尽快处理'

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 记录催办操作
          db['workflow_urges'].insert_one({
            workflow_id: workflow_id,
            message: message,
            urged_by: params[:operator_id],
            created_at: Time.now
          })

          # 更新工作流催办次数
          db['workflows'].update_one(
            { _id: BSON::ObjectId(workflow_id) },
            { '$inc' => { urge_count: 1 }, '$set' => { last_urged_at: Time.now } }
          )

          { success: true, message: "催办已发送" }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

