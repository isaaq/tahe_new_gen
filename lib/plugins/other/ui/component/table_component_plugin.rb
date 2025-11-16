# frozen_string_literal: true

# UI组件插件：表格组件插件
# 分类：other/ui_component
# 插件ID：ui-component-table

module Plugins
  module Other
    module UiComponent
      class TableComponentPlugin
        # 渲染入口：返回HTML片段或组件描述（JSON）
        # context:
        # - props: 组件属性
        # - data: 绑定数据
        # - options: 运行时配置
        def render(context = {})
          props = context[:props] || {}
          data = context[:data] || {}
          options = context[:options] || {}

          # 返回极简HTML，真实项目可输出Layui或Vue配置
return "<table class='kr-table'>#{data}</table>"

        end
      end
    end
  end
end


