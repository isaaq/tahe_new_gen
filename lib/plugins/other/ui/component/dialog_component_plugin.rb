# frozen_string_literal: true

# UI组件插件：对话框组件插件
# 分类：other/ui_component
# 插件ID：ui-component-dialog

module Plugins
  module Other
    module UiComponent
      class DialogComponentPlugin
        # 渲染入口：返回HTML片段或组件描述（JSON）
        # context:
        # - props: 组件属性
        # - data: 绑定数据
        # - options: 运行时配置
        def render(context = {})
          props = context[:props] || {}
          data = context[:data] || {}
          options = context[:options] || {}

          return "<div class='kr-dialog'></div>"

        end
      end
    end
  end
end


