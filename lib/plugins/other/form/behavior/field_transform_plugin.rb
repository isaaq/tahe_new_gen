# frozen_string_literal: true

# 表单行为插件：字段转换插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-transform

module Plugins
  module Other
    module FormBehavior
      class FieldTransformPlugin
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
  transform_type = rule[:transform]
  value = form_data[field.to_s]
  if value
    transformed = case transform_type
    when 'uppercase'
      value.to_s.upcase
    when 'lowercase'
      value.to_s.downcase
    when 'trim'
      value.to_s.strip
    when 'to_number'
      value.to_s.gsub(/[^\d.]/, '').to_f
    when 'to_string'
      value.to_s
    else
      value
    end
    form_data[field.to_s] = transformed
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


