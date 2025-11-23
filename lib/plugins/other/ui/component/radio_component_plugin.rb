# frozen_string_literal: true

# UI组件插件：单选框组件插件
# 分类：other/ui_component
# 插件ID：ui-component-radio

module Plugins
  module Other
    module UiComponent
      class RadioComponentPlugin
        # 渲染入口：返回HTML片段或组件描述（JSON）
        # context:
        # - props: 组件属性
        # - data: 绑定数据
        # - options: 运行时配置
        def render(context = {})
          props = context[:props] || {}
          data = context[:data] || {}
          options = context[:options] || {}

          return "<input type='radio' class='kr-radio' />"

        end
      end
    end
  end
end


