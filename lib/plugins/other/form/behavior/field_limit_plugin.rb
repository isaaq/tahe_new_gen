# frozen_string_literal: true

# 表单行为插件：字段限制插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-limit

module Plugins
  module Other
    module FormBehavior
      class FieldLimitPlugin
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
  max_length = rule[:max_length]
  min_value = rule[:min_value]
  max_value = rule[:max_value]
  value = form_data[field.to_s]
  if value
    if max_length && value.to_s.length > max_length
      form_data[field.to_s] = value.to_s[0, max_length]
    end
    if min_value && value.to_f < min_value
      form_data[field.to_s] = min_value
    end
    if max_value && value.to_f > max_value
      form_data[field.to_s] = max_value
    end
  end
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


