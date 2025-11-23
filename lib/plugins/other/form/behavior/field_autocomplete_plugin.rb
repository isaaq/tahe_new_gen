# frozen_string_literal: true

# 表单行为插件：字段自动完成插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-autocomplete

module Plugins
  module Other
    module FormBehavior
      class FieldAutocompletePlugin
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
          rules = options[:rules] || []
rules.each do |rule|
  field = rule[:field]
  source = rule[:source] # 数据源：'api', 'static', 'field'
  options_list = rule[:options] || []
  ui_state[field.to_s] ||= {}
  ui_state[field.to_s][:autocomplete] = {
    source: source,
    options: options_list
  }
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


