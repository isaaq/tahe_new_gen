# frozen_string_literal: true

# 表单行为插件：字段计算插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-calculation

module Plugins
  module Other
    module FormBehavior
      class FieldCalculationPlugin
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
  target = rule[:target]
  formula = rule[:formula] # 例如: "a + b - c"
  # 极简安全计算：仅允许数字、字母、下划线、加减乘除和空格
  if formula && formula =~ /\A[\w\s\+\-\*\/]+\z/
    expr = formula.gsub(/\b([a-zA-Z_]\w*)\b/) { |m| form_data[m].to_f }
    begin
      form_data[target.to_s] = eval(expr)
    rescue
      # 忽略错误
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


