# frozen_string_literal: true

# 操作钩子插件：错误处理钩子插件
# 分类：other/hook
# 插件ID：hook-on-error

module Plugins
  module Other
    module Hook
      class OnErrorHookPlugin
        # 钩子执行：返回可能修改后的上下文
        # context:
        # - action: 执行动作（save/delete等）
        # - data: 当前数据
        # - options: 配置
        def call(context = {})
          action = context[:action]
          data = context[:data] || {}
          options = context[:options] || {}

          # 示例：记录错误日志
# Logger.error(error.message)


          {
            success: true,
            data: data
          }
        end
      end
    end
  end
end


