# frozen_string_literal: true

# 操作钩子插件：变更钩子插件
# 分类：other/hook
# 插件ID：hook-on-change

module Plugins
  module Other
    module Hook
      class OnChangeHookPlugin
        # 钩子执行：返回可能修改后的上下文
        # context:
        # - action: 执行动作（save/delete等）
        # - data: 当前数据
        # - options: 配置
        def call(context = {})
          action = context[:action]
          data = context[:data] || {}
          options = context[:options] || {}

          # 示例：记录变更历史
# History.record_change(data, changes)


          {
            success: true,
            data: data
          }
        end
      end
    end
  end
end


