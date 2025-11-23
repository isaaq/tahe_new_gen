# frozen_string_literal: true

# 操作钩子插件：成功处理钩子插件
# 分类：other/hook
# 插件ID：hook-on-success

module Plugins
  module Other
    module Hook
      class OnSuccessHookPlugin
        # 钩子执行：返回可能修改后的上下文
        # context:
        # - action: 执行动作（save/delete等）
        # - data: 当前数据
        # - options: 配置
        def call(context = {})
          action = context[:action]
          data = context[:data] || {}
          options = context[:options] || {}

          # 示例：发送成功通知
# Notification.send_success(data)


          {
            success: true,
            data: data
          }
        end
      end
    end
  end
end


