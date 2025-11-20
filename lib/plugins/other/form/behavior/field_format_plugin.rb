# frozen_string_literal: true

# 表单行为插件：字段格式化插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-format

module Plugins
  module Other
    module FormBehavior
      class FieldFormatPlugin
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
  format_type = rule[:format]
  value = form_data[field.to_s]
  if value
    formatted = case format_type
    when 'phone'
      value.to_s.gsub(/(\d{3})(\d{4})(\d{4})/, '\1-\2-\3')
    when 'currency'
      sprintf('%.2f', value.to_f)
    when 'date'
      Date.parse(value.to_s).strftime('%Y-%m-%d') rescue value
    else
      value
    end
    form_data[field.to_s] = formatted
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


