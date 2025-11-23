# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Notification; end

module Plugins
  module Strategy
    module Notification
      class TemplateNotificationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'notification', 'notify', 'template'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: recipient" unless params[:recipient]
          
          raise "缺少必要参数: template_id" unless params[:template_id]
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 模板通知逻辑
          recipient = params[:recipient]
          template_id = params[:template_id]
          template_vars = params[:template_vars] || {}
          channel = params[:channel] || 'email'

          return { success: false, message: "收件人未指定" } unless recipient
          return { success: false, message: "模板ID未指定" } unless template_id

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 获取模板
          template = db['notification_templates'].find_one({ _id: template_id })
          return { success: false, message: "模板不存在" } unless template

          # 渲染模板内容
          subject = (template['subject'] || '').gsub(/{{(w+)}}/) { |m| template_vars[$1.to_sym] || template_vars[$1] || m }
          content = (template['content'] || '').gsub(/{{(w+)}}/) { |m| template_vars[$1.to_sym] || template_vars[$1] || m }

          # 发送通知
          db['notification_logs'].insert_one({
            type: channel,
            recipient: recipient,
            subject: subject,
            content: content,
            template_id: template_id,
            sent_at: Time.now,
            status: 'sent'
          })

          { success: true, message: "模板通知已发送", template_id: template_id }
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

