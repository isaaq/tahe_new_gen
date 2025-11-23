# frozen_string_literal: true

# 表单行为插件：字段脱敏插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-mask

module Plugins
  module Other
    module FormBehavior
      class FieldMaskPlugin
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
  mask_char = rule[:mask_char] || '*'
  keep_start = rule[:keep_start] || 0
  keep_end = rule[:keep_end] || 0
  value = form_data[field.to_s]
  if value && value.to_s.length > keep_start + keep_end
    masked = value.to_s[0, keep_start] + 
             mask_char * (value.to_s.length - keep_start - keep_end) + 
             value.to_s[-keep_end, keep_end]
    ui_state[field.to_s] ||= {}
    ui_state[field.to_s][:display_value] = masked
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


