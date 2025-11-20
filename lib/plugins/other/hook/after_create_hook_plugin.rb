# frozen_string_literal: true

# 操作钩子插件：创建后钩子插件
# 分类：other/hook
# 插件ID：hook-after-create

module Plugins
  module Other
    module Hook
      class AfterCreateHookPlugin
        # 钩子执行：返回可能修改后的上下文
        # context:
        # - action: 执行动作（save/delete等）
        # - data: 当前数据
        # - options: 配置
        def call(context = {})
          action = context[:action]
          data = context[:data] || {}
          options = context[:options] || {}

          # 示例：发送创建通知
# Notification.send_created(data)


          {
            success: true,
            data: data
          }
        end
      end
    end
  end
end


