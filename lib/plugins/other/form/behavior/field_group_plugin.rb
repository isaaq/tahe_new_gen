# frozen_string_literal: true

# 表单行为插件：字段分组插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-group

module Plugins
  module Other
    module FormBehavior
      class FieldGroupPlugin
        # 入口方法：对表单数据或UI上下文进行处理
        # context 含义约定：
        # - form_data: Hash 当前表单数据
        # - schema: Hash 表单schema（可选）
        # - ui_state: Hash UI状态（可选）
        # - options: Hash 插件配置
        def run(context = {})
          form_data = context[:form_data] || {}
          ui_state = context[:ui_state] || {}
          options = context[:options] || {}

          # 行为实现
          groups = options[:groups] || []
groups.each do |group|
  group_id = group[:id]
  condition = group[:condition] || {}
  visible = condition.all? { |k, v| form_data[k.to_s] == v }
  ui_state["_group_#{group_id}"] ||= {}
  ui_state["_group_#{group_id}"][:visible] = visible
end


          {
            success: true,
            form_data: form_data,
            ui_state: ui_state
          }
        end
      end
    end
  end
end


