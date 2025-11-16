# frozen_string_literal: true

# 表单行为插件：自动填充插件
# 分类：other/form_behavior
# 插件ID：form-behavior-auto-fill

module Plugins
  module Other
    module FormBehavior
      class AutoFillPlugin
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
  expr = rule[:expr]
  # 简单表达式：支持占位串 "#{field}" 拼接
  value = expr.to_s.gsub(/\#\{([^}]+)\}/) { |m| form_data[$1] || '' }
  form_data[target.to_s] = value
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


