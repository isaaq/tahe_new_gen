# frozen_string_literal: true

# 表单行为插件：字段验证插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-validation

module Plugins
  module Other
    module FormBehavior
      class FieldValidationPlugin
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
  validator = rule[:validator]
  value = form_data[field.to_s]
  if value && validator
    # 执行验证逻辑
    valid = case validator[:type]
    when 'required'
      !value.nil? && value.to_s.strip != ''
    when 'min_length'
      value.to_s.length >= (validator[:value] || 0)
    when 'max_length'
      value.to_s.length <= (validator[:value] || 999999)
    when 'pattern'
      value.to_s =~ Regexp.new(validator[:value] || '.*')
    else
      true
    end
    ui_state[field.to_s] ||= {}
    ui_state[field.to_s][:error] = validator[:message] unless valid
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


