# frozen_string_literal: true

# 表单行为插件：字段依赖插件
# 分类：other/form_behavior
# 插件ID：form-behavior-field-dependency

module Plugins
  module Other
    module FormBehavior
      class FieldDependencyPlugin
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
  source = rule[:source]
  target = rule[:target]
  dependency = rule[:dependency]
  source_value = form_data[source.to_s]
  if dependency && dependency.key?(source_value)
    target_config = dependency[source_value]
    ui_state[target.to_s] ||= {}
    ui_state[target.to_s].merge!(target_config)
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


