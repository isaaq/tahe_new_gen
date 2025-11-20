# frozen_string_literal: true

require_relative 'plugin_generator'
require_relative 'plugin_store'
require_relative 'generate_builtin_plugin_metadata'

# 批量插件生成脚本
class BatchPluginGenerator
  def initialize
    @generator = PluginGenerator.new
    @store = PluginStore.instance
  end
  
  # 生成表单行为插件配置模板
  def self.create_form_behavior_plugin_configs
    [
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-linkage',
        name: '字段联动插件',
        category: 'other/form_behavior',
        class_name: 'FieldLinkagePlugin',
        description: '根据一个字段的变化自动更新其他字段可选值或显示状态。',
        tags: ['form', 'behavior', 'linkage'],
        behavior_logic: <<~'RUBY'
          # options里可定义联动规则
          rules = options[:rules] || []
          rules.each do |rule|
            source = rule[:source]
            target = rule[:target]
            mapping = rule[:mapping] || {}
            source_value = form_data[source.to_s] || form_data[source.to_sym]
            if mapping.key?(source_value)
              ui_state[target.to_s] ||= {}
              ui_state[target.to_s][:options] = mapping[source_value]
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-auto-fill',
        name: '自动填充插件',
        category: 'other/form_behavior',
        class_name: 'AutoFillPlugin',
        description: '根据规则自动填充表单字段，例如默认值、组合值等。',
        tags: ['form', 'behavior', 'auto_fill'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            target = rule[:target]
            expr = rule[:expr]
            # 简单表达式：支持占位串 "#{field}" 拼接
            value = expr.to_s.gsub(/\#\{([^}]+)\}/) { |m| form_data[$1] || '' }
            form_data[target.to_s] = value
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-conditional-display',
        name: '条件显示插件',
        category: 'other/form_behavior',
        class_name: 'ConditionalDisplayPlugin',
        description: '按条件隐藏/显示字段或分组，支持复杂条件。',
        tags: ['form', 'behavior', 'display'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            target = rule[:target]
            condition = rule[:condition] || {}
            show = condition.all? do |k, v|
              form_data[k.to_s] == v
            end
            ui_state[target.to_s] ||= {}
            ui_state[target.to_s][:hidden] = !show
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-calculation',
        name: '字段计算插件',
        category: 'other/form_behavior',
        class_name: 'FieldCalculationPlugin',
        description: '对多个字段进行计算并写入目标字段，例如合计、差值等。',
        tags: ['form', 'behavior', 'calculation'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-validation',
        name: '字段验证插件',
        category: 'other/form_behavior',
        class_name: 'FieldValidationPlugin',
        description: '实时验证字段值，支持自定义验证规则。',
        tags: ['form', 'behavior', 'validation'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-format',
        name: '字段格式化插件',
        category: 'other/form_behavior',
        class_name: 'FieldFormatPlugin',
        description: '自动格式化字段值，如日期、金额、手机号等。',
        tags: ['form', 'behavior', 'format'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-copy',
        name: '字段复制插件',
        category: 'other/form_behavior',
        class_name: 'FieldCopyPlugin',
        description: '将一个字段的值复制到另一个字段。',
        tags: ['form', 'behavior', 'copy'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            source = rule[:source]
            target = rule[:target]
            if form_data[source.to_s]
              form_data[target.to_s] = form_data[source.to_s]
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-clear',
        name: '字段清空插件',
        category: 'other/form_behavior',
        class_name: 'FieldClearPlugin',
        description: '根据条件清空指定字段的值。',
        tags: ['form', 'behavior', 'clear'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            condition = rule[:condition] || {}
            should_clear = condition.all? do |k, v|
              form_data[k.to_s] == v
            end
            form_data[field.to_s] = nil if should_clear
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-disable',
        name: '字段禁用插件',
        category: 'other/form_behavior',
        class_name: 'FieldDisablePlugin',
        description: '根据条件禁用或启用字段。',
        tags: ['form', 'behavior', 'disable'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            condition = rule[:condition] || {}
            disabled = condition.all? do |k, v|
              form_data[k.to_s] == v
            end
            ui_state[field.to_s] ||= {}
            ui_state[field.to_s][:disabled] = disabled
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-readonly',
        name: '字段只读插件',
        category: 'other/form_behavior',
        class_name: 'FieldReadonlyPlugin',
        description: '根据条件设置字段为只读。',
        tags: ['form', 'behavior', 'readonly'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            condition = rule[:condition] || {}
            readonly = condition.all? do |k, v|
              form_data[k.to_s] == v
            end
            ui_state[field.to_s] ||= {}
            ui_state[field.to_s][:readonly] = readonly
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-required',
        name: '字段必填插件',
        category: 'other/form_behavior',
        class_name: 'FieldRequiredPlugin',
        description: '根据条件动态设置字段为必填。',
        tags: ['form', 'behavior', 'required'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            condition = rule[:condition] || {}
            required = condition.all? do |k, v|
              form_data[k.to_s] == v
            end
            ui_state[field.to_s] ||= {}
            ui_state[field.to_s][:required] = required
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-tooltip',
        name: '字段提示插件',
        category: 'other/form_behavior',
        class_name: 'FieldTooltipPlugin',
        description: '动态设置字段的提示信息。',
        tags: ['form', 'behavior', 'tooltip'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            tooltip = rule[:tooltip]
            condition = rule[:condition] || {}
            if condition.all? { |k, v| form_data[k.to_s] == v }
              ui_state[field.to_s] ||= {}
              ui_state[field.to_s][:tooltip] = tooltip
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-placeholder',
        name: '字段占位符插件',
        category: 'other/form_behavior',
        class_name: 'FieldPlaceholderPlugin',
        description: '动态设置字段的占位符文本。',
        tags: ['form', 'behavior', 'placeholder'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            placeholder = rule[:placeholder]
            condition = rule[:condition] || {}
            if condition.all? { |k, v| form_data[k.to_s] == v }
              ui_state[field.to_s] ||= {}
              ui_state[field.to_s][:placeholder] = placeholder
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-default',
        name: '字段默认值插件',
        category: 'other/form_behavior',
        class_name: 'FieldDefaultPlugin',
        description: '为字段设置默认值。',
        tags: ['form', 'behavior', 'default'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            default_value = rule[:default]
            condition = rule[:condition] || {}
            if condition.all? { |k, v| form_data[k.to_s] == v }
              form_data[field.to_s] ||= default_value
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-dependency',
        name: '字段依赖插件',
        category: 'other/form_behavior',
        class_name: 'FieldDependencyPlugin',
        description: '处理字段之间的依赖关系。',
        tags: ['form', 'behavior', 'dependency'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-group',
        name: '字段分组插件',
        category: 'other/form_behavior',
        class_name: 'FieldGroupPlugin',
        description: '动态管理字段分组显示。',
        tags: ['form', 'behavior', 'group'],
        behavior_logic: <<~'RUBY'
          groups = options[:groups] || []
          groups.each do |group|
            group_id = group[:id]
            condition = group[:condition] || {}
            visible = condition.all? { |k, v| form_data[k.to_s] == v }
            ui_state["_group_#{group_id}"] ||= {}
            ui_state["_group_#{group_id}"][:visible] = visible
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-sort',
        name: '字段排序插件',
        category: 'other/form_behavior',
        class_name: 'FieldSortPlugin',
        description: '动态调整字段的显示顺序。',
        tags: ['form', 'behavior', 'sort'],
        behavior_logic: <<~'RUBY'
          sort_rules = options[:sort_rules] || []
          sort_rules.each do |rule|
            field = rule[:field]
            position = rule[:position]
            condition = rule[:condition] || {}
            if condition.all? { |k, v| form_data[k.to_s] == v }
              ui_state[field.to_s] ||= {}
              ui_state[field.to_s][:order] = position
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-transform',
        name: '字段转换插件',
        category: 'other/form_behavior',
        class_name: 'FieldTransformPlugin',
        description: '转换字段值的数据类型或格式。',
        tags: ['form', 'behavior', 'transform'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-limit',
        name: '字段限制插件',
        category: 'other/form_behavior',
        class_name: 'FieldLimitPlugin',
        description: '限制字段值的输入范围或长度。',
        tags: ['form', 'behavior', 'limit'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-mask',
        name: '字段脱敏插件',
        category: 'other/form_behavior',
        class_name: 'FieldMaskPlugin',
        description: '对敏感字段进行脱敏显示。',
        tags: ['form', 'behavior', 'mask'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-upload',
        name: '字段上传插件',
        category: 'other/form_behavior',
        class_name: 'FieldUploadPlugin',
        description: '处理文件上传字段的特殊行为。',
        tags: ['form', 'behavior', 'upload'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            max_size = rule[:max_size]
            allowed_types = rule[:allowed_types] || []
            # 文件上传处理逻辑
            ui_state[field.to_s] ||= {}
            ui_state[field.to_s][:upload_config] = {
              max_size: max_size,
              allowed_types: allowed_types
            }
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-autocomplete',
        name: '字段自动完成插件',
        category: 'other/form_behavior',
        class_name: 'FieldAutocompletePlugin',
        description: '为字段提供自动完成功能。',
        tags: ['form', 'behavior', 'autocomplete'],
        behavior_logic: <<~'RUBY'
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
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-history',
        name: '字段历史记录插件',
        category: 'other/form_behavior',
        class_name: 'FieldHistoryPlugin',
        description: '记录字段的历史值，支持撤销和重做。',
        tags: ['form', 'behavior', 'history'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            max_history = rule[:max_history] || 10
            # 历史记录处理逻辑
            ui_state[field.to_s] ||= {}
            ui_state[field.to_s][:history_enabled] = true
            ui_state[field.to_s][:max_history] = max_history
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-sync',
        name: '字段同步插件',
        category: 'other/form_behavior',
        class_name: 'FieldSyncPlugin',
        description: '同步多个字段的值，保持一致性。',
        tags: ['form', 'behavior', 'sync'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            source = rule[:source]
            targets = rule[:targets] || []
            source_value = form_data[source.to_s]
            targets.each do |target|
              form_data[target.to_s] = source_value
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-watch',
        name: '字段监听插件',
        category: 'other/form_behavior',
        class_name: 'FieldWatchPlugin',
        description: '监听字段变化并触发回调。',
        tags: ['form', 'behavior', 'watch'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            callback = rule[:callback]
            # 字段变化监听逻辑
            ui_state[field.to_s] ||= {}
            ui_state[field.to_s][:watch] = true
            ui_state[field.to_s][:callback] = callback
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-validate-on-blur',
        name: '失焦验证插件',
        category: 'other/form_behavior',
        class_name: 'FieldValidateOnBlurPlugin',
        description: '字段失焦时进行验证。',
        tags: ['form', 'behavior', 'validate', 'blur'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            validator = rule[:validator]
            ui_state[field.to_s] ||= {}
            ui_state[field.to_s][:validate_on_blur] = true
            ui_state[field.to_s][:validator] = validator
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-focus',
        name: '字段聚焦插件',
        category: 'other/form_behavior',
        class_name: 'FieldFocusPlugin',
        description: '自动聚焦到指定字段。',
        tags: ['form', 'behavior', 'focus'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            condition = rule[:condition] || {}
            if condition.all? { |k, v| form_data[k.to_s] == v }
              ui_state[field.to_s] ||= {}
              ui_state[field.to_s][:auto_focus] = true
            end
          end
        RUBY
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-reset',
        name: '字段重置插件',
        category: 'other/form_behavior',
        class_name: 'FieldResetPlugin',
        description: '重置字段到初始值或默认值。',
        tags: ['form', 'behavior', 'reset'],
        behavior_logic: <<~'RUBY'
          rules = options[:rules] || []
          rules.each do |rule|
            field = rule[:field]
            reset_value = rule[:reset_value]
            condition = rule[:condition] || {}
            if condition.all? { |k, v| form_data[k.to_s] == v }
              form_data[field.to_s] = reset_value
            end
          end
        RUBY
      },
      # 新增表单行为插件
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-conditional-required',
        name: '条件必填插件',
        category: 'form_behavior',
        class_name: 'FieldConditionalRequiredPlugin',
        description: '根据条件动态设置字段必填状态。',
        tags: ['form', 'behavior', 'conditional', 'required']
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-conditional-visible',
        name: '条件显示插件',
        category: 'form_behavior',
        class_name: 'FieldConditionalVisiblePlugin',
        description: '根据条件动态显示或隐藏字段。',
        tags: ['form', 'behavior', 'conditional', 'visible']
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-auto-save',
        name: '自动保存插件',
        category: 'form_behavior',
        class_name: 'FieldAutoSavePlugin',
        description: '字段值变化时自动保存到本地存储或服务器。',
        tags: ['form', 'behavior', 'auto_save', 'persistence']
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-remote-validate',
        name: '远程验证插件',
        category: 'form_behavior',
        class_name: 'FieldRemoteValidatePlugin',
        description: '调用远程接口验证字段值。',
        tags: ['form', 'behavior', 'remote', 'validation']
      },
      {
        type: 'form_behavior',
        plugin_id: 'form-behavior-field-format-on-blur',
        name: '失焦格式化插件',
        category: 'form_behavior',
        class_name: 'FieldFormatOnBlurPlugin',
        description: '字段失焦时自动格式化值。',
        tags: ['form', 'behavior', 'format', 'blur']
      }
    ]
  end

  # 从配置文件批量生成插件
  def generate_from_config(config_file)
    configs = YAML.load_file(config_file)
    generate_plugins(configs['plugins'] || [])
  end
  
  # 生成插件列表
  def generate_plugins(plugin_configs)
    output_dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'plugins')
    
    results = @generator.batch_generate(plugin_configs, output_dir)
    
    # 生成元数据
    metadata_results = generate_metadata(plugin_configs, results)
    
    {
      code_generation: results,
      metadata_generation: metadata_results
    }
  end
  
  # 生成策略插件配置模板
  def self.create_strategy_plugin_configs
    [
      # 保存策略（20+）
      {
        type: 'strategy',
        plugin_id: 'strategy-save-review',
        name: '审核保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'ReviewSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'review',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已保存待审核',
        description: '保存文档并标记为待审核状态，适用于需要审核流程的场景。',
        tags: ['save', 'review', 'workflow']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-batch',
        name: '批量保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'BatchSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'batch',
        required_params: ['data_list'],
        collection: 'documents',
        success_message: '批量保存成功',
        description: '支持批量保存多个文档，提高保存效率。',
        tags: ['save', 'batch', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-async',
        name: '异步保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'AsyncSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'async',
        required_params: ['data'],
        collection: 'documents',
        success_message: '异步保存任务已提交',
        description: '异步保存文档，不阻塞主线程，适用于大数据量保存。',
        tags: ['save', 'async', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-version',
        name: '版本保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'VersionSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'version',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档版本已保存',
        description: '保存文档时自动创建版本记录，支持版本回滚。',
        tags: ['save', 'version', 'history']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-encrypted',
        name: '加密保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'EncryptedSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'encrypted',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已加密保存',
        description: '保存文档时自动加密敏感字段，提高数据安全性。',
        tags: ['save', 'encryption', 'security']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-audit',
        name: '审计保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'AuditSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'audit',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已保存并记录审计日志',
        description: '保存文档时自动记录审计日志，包括操作人、时间、变更内容等。',
        tags: ['save', 'audit', 'logging']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-incremental',
        name: '增量保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'IncrementalSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'incremental',
        required_params: ['data', 'document_id'],
        collection: 'documents',
        success_message: '文档增量更新成功',
        description: '只保存变更的字段，提高保存效率。',
        tags: ['save', 'incremental', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-transaction',
        name: '事务保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'TransactionSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'transaction',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已事务保存',
        description: '在事务中保存文档，支持回滚。',
        tags: ['save', 'transaction', 'rollback']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-conditional',
        name: '条件保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'ConditionalSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'conditional',
        required_params: ['data', 'condition'],
        collection: 'documents',
        success_message: '文档已条件保存',
        description: '根据条件决定是否保存，支持条件判断。',
        tags: ['save', 'conditional', 'logic']
      },
      # 提交策略（15+）
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-review',
        name: '审核发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'ReviewPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'review',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已提交审核',
        description: '提交文档到审核流程，需要审核通过后才能发布。',
        tags: ['submit', 'review', 'workflow']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-scheduled',
        name: '定时发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'ScheduledPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'scheduled',
        required_params: ['document_id', 'publish_time'],
        collection: 'documents',
        success_message: '定时发布任务已创建',
        description: '支持定时发布文档，在指定时间自动发布。',
        tags: ['submit', 'scheduled', 'automation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-batch',
        name: '批量发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'BatchPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'batch',
        required_params: ['document_ids'],
        collection: 'documents',
        success_message: '批量发布成功',
        description: '批量发布多个文档，提高发布效率。',
        tags: ['submit', 'batch', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-conditional',
        name: '条件发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'ConditionalPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'conditional',
        required_params: ['document_id', 'condition'],
        collection: 'documents',
        success_message: '条件发布成功',
        description: '根据条件决定是否发布，支持条件判断。',
        tags: ['submit', 'conditional', 'logic']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-gray',
        name: '灰度发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'GrayPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'gray',
        required_params: ['document_id', 'gray_percentage'],
        collection: 'documents',
        success_message: '灰度发布任务已创建',
        description: '支持灰度发布，逐步扩大发布范围。',
        tags: ['submit', 'gray', 'gradual']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-rollback',
        name: '回滚发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'RollbackPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'rollback',
        required_params: ['document_id', 'version'],
        collection: 'documents',
        success_message: '发布已回滚',
        description: '回滚到指定版本的发布，支持版本管理。',
        tags: ['submit', 'rollback', 'version']
      },
      # 查询策略（30+）
      {
        type: 'strategy',
        plugin_id: 'strategy-query-pagination',
        name: '分页查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'PaginationQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'pagination',
        required_params: [],
        collection: 'documents',
        description: '支持分页查询，返回指定页的数据和总数。',
        tags: ['query', 'pagination', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-advanced-filter',
        name: '高级筛选策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'AdvancedFilterQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'advanced_filter',
        required_params: [],
        collection: 'documents',
        description: '支持复杂的多条件筛选查询。',
        tags: ['query', 'filter', 'advanced']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-fulltext',
        name: '全文搜索策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'FulltextQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'fulltext',
        required_params: ['keyword'],
        collection: 'documents',
        description: '支持全文检索，基于关键字的模糊搜索与权重排序。',
        tags: ['query', 'fulltext', 'search']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-relation',
        name: '关联查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'RelationQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'relation',
        required_params: [],
        collection: 'documents',
        description: '支持关联查询，自动加载关联数据。',
        tags: ['query', 'relation', 'join']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-aggregate',
        name: '聚合查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'AggregateQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'aggregate',
        required_params: [],
        collection: 'documents',
        description: '支持聚合查询，如统计、分组、求和等。',
        tags: ['query', 'aggregate', 'statistics']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-cached',
        name: '缓存查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'CachedQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'cached',
        required_params: [],
        collection: 'documents',
        description: '使用缓存加速查询，提高查询性能。',
        tags: ['query', 'cache', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-sharded',
        name: '分片查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'ShardedQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'sharded',
        required_params: [],
        collection: 'documents',
        description: '支持分片查询，适用于大数据量场景。',
        tags: ['query', 'shard', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-realtime',
        name: '实时查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'RealtimeQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'realtime',
        required_params: [],
        collection: 'documents',
        description: '实时查询策略，支持数据变更监听和实时更新。',
        tags: ['query', 'realtime', 'streaming']
      },
      # 删除策略（10+）
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-soft',
        name: '软删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'SoftDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'soft',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已软删除',
        description: '软删除文档，只标记删除状态，数据仍保留在数据库中。',
        tags: ['delete', 'soft', 'recoverable']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-hard',
        name: '硬删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'HardDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'hard',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已永久删除',
        description: '硬删除文档，从数据库中永久删除数据。',
        tags: ['delete', 'hard', 'permanent']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-cascade',
        name: '级联删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'CascadeDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'cascade',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档及关联数据已删除',
        description: '删除文档时自动删除所有关联数据。',
        tags: ['delete', 'cascade', 'relation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-batch',
        name: '批量删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'BatchDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'batch',
        required_params: ['document_ids'],
        collection: 'documents',
        success_message: '批量删除成功',
        description: '批量删除多个文档，提高删除效率。',
        tags: ['delete', 'batch', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-conditional',
        name: '条件删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'ConditionalDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'conditional',
        required_params: ['document_id', 'condition'],
        collection: 'documents',
        success_message: '条件删除成功',
        description: '根据条件决定是否删除，支持条件判断。',
        tags: ['delete', 'conditional', 'logic']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-archive',
        name: '归档删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'ArchiveDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'archive',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已归档',
        description: '删除文档时自动归档到归档表，支持数据恢复。',
        tags: ['delete', 'archive', 'recoverable']
      },
      # 数据权限策略
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-data',
        name: '数据权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'DataPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'data',
        required_params: [],
        description: '按业务数据范围控制访问权限，支持维度与标签。',
        tags: ['permission', 'data', 'scope']
      },
      # 权限策略（20+）
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-store-isolation',
        name: '门店隔离策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'StoreIsolationStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'store_isolation',
        required_params: [],
        description: '基于门店的数据隔离，用户只能访问所属门店的数据。',
        tags: ['permission', 'isolation', 'store']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-department-isolation',
        name: '部门隔离策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'DepartmentIsolationStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'department_isolation',
        required_params: [],
        description: '基于部门的数据隔离，用户只能访问所属部门的数据。',
        tags: ['permission', 'isolation', 'department']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-role',
        name: '角色权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'RolePermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'role',
        required_params: [],
        description: '基于角色的权限控制，不同角色有不同的数据访问权限。',
        tags: ['permission', 'role', 'rbac']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-field',
        name: '字段权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'FieldPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'field',
        required_params: [],
        description: '控制字段级别的访问权限，可以隐藏或只读某些字段。',
        tags: ['permission', 'field', 'granular']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-time',
        name: '时间权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'TimePermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'time',
        required_params: [],
        description: '基于时间的权限控制，支持时间段限制。',
        tags: ['permission', 'time', 'schedule']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-ip',
        name: 'IP权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'IpPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'ip',
        required_params: [],
        description: '基于IP地址的权限控制，支持IP白名单和黑名单。',
        tags: ['permission', 'ip', 'network']
      },
      # 验证策略（25+）
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-form',
        name: '表单验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'FormValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'form',
        required_params: ['data'],
        description: '表单级别的数据验证，验证所有字段的格式和规则。',
        tags: ['validation', 'form', 'data']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-business-rule',
        name: '业务规则验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'BusinessRuleValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'business_rule',
        required_params: ['data'],
        description: '业务规则级别的验证，验证复杂的业务逻辑约束。',
        tags: ['validation', 'business', 'rule']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-uniqueness',
        name: '唯一性验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'UniquenessValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'uniqueness',
        required_params: ['data', 'field'],
        description: '验证字段值的唯一性，确保数据库中不存在重复值。',
        tags: ['validation', 'uniqueness', 'constraint']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-format',
        name: '格式验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'FormatValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'format',
        required_params: ['data', 'field'],
        description: '验证字段值的格式，如邮箱、手机号、身份证等。',
        tags: ['validation', 'format', 'pattern']
      },
      # 通知策略（15+）
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-email',
        name: '邮件通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'EmailNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'email',
        required_params: ['recipient', 'subject', 'content'],
        description: '发送邮件通知，支持HTML格式和附件。',
        tags: ['notification', 'email', 'communication']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-sms',
        name: '短信通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'SmsNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'sms',
        required_params: ['phone', 'message'],
        description: '发送短信通知，支持模板和批量发送。',
        tags: ['notification', 'sms', 'communication']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-webhook',
        name: 'Webhook通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'WebhookNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'webhook',
        required_params: ['url', 'payload'],
        description: '通过Webhook发送通知，支持自定义HTTP请求。',
        tags: ['notification', 'webhook', 'integration']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-wechat-work',
        name: '企业微信通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'WechatWorkNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'wechat_work',
        required_params: ['user_id', 'message'],
        description: '发送企业微信通知，支持文本、图片、文件等。',
        tags: ['notification', 'wechat', 'enterprise']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-insite',
        name: '站内信通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'InSiteMessageStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'insite',
        required_params: ['user_id', 'message'],
        description: '发送站内消息通知，支持未读已读状态与收件箱聚合。',
        tags: ['notification', 'insite', 'message']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-dingtalk',
        name: '钉钉通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'DingtalkNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'dingtalk',
        required_params: ['webhook', 'message'],
        description: '通过钉钉机器人发送通知，支持Markdown消息。',
        tags: ['notification', 'dingtalk', 'robot']
      },
      # 工作流策略（20+）
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-approval',
        name: '审批流程策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'ApprovalWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'approval',
        required_params: ['document_id', 'approver_id'],
        description: '处理审批流程，支持多级审批和条件审批。',
        tags: ['workflow', 'approval', 'process']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-status-transition',
        name: '状态流转策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'StatusTransitionWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'status_transition',
        required_params: ['document_id', 'target_status'],
        description: '处理状态流转，支持状态机模式和条件流转。',
        tags: ['workflow', 'status', 'transition']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-auto-trigger',
        name: '自动触发策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'AutoTriggerWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'auto_trigger',
        required_params: ['trigger_condition'],
        description: '根据条件自动触发工作流，支持定时触发和事件触发。',
        tags: ['workflow', 'automation', 'trigger']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-task-assignment',
        name: '任务分配策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'TaskAssignmentWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'task_assignment',
        required_params: ['document_id', 'assignee_id'],
        description: '将任务按角色或规则分配给处理人，支持轮询与负载均衡。',
        tags: ['workflow', 'assignment', 'task']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-parallel-approval',
        name: '并行审批策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'ParallelApprovalWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'parallel_approval',
        required_params: ['document_id', 'approver_ids'],
        description: '并行发起多路审批，支持多数通过或全体通过策略。',
        tags: ['workflow', 'approval', 'parallel']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-sequential-approval',
        name: '串行审批策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'SequentialApprovalWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'sequential_approval',
        required_params: ['document_id', 'sequence'],
        description: '按序列依次审批，上一节点通过后进入下一节点。',
        tags: ['workflow', 'approval', 'sequential']
      },
      # 自动备份保存策略
      {
        type: 'strategy',
        plugin_id: 'strategy-save-auto-backup',
        name: '自动备份保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'AutoBackupSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'auto_backup',
        required_params: ['data'],
        collection: 'documents_backup',
        success_message: '文档已保存并完成备份',
        description: '保存主数据同时写入备份集合，支持回溯与对比。',
        tags: ['save', 'backup', 'safety']
      },
      # 新增保存策略
      {
        type: 'strategy',
        plugin_id: 'strategy-save-compressed',
        name: '压缩保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'CompressedSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'compressed',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已压缩保存',
        description: '保存文档时自动压缩大字段，节省存储空间。',
        tags: ['save', 'compression', 'storage']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-validated',
        name: '校验保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'ValidatedSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'validated',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已校验并保存',
        description: '保存前进行完整的数据校验，确保数据质量。',
        tags: ['save', 'validation', 'quality']
      },
      # 新增提交策略
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-immediate',
        name: '立即发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'ImmediatePublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'immediate',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已立即发布',
        description: '提交后立即发布，无需等待审核。',
        tags: ['submit', 'immediate', 'publish']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-delayed',
        name: '延迟发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'DelayedPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'delayed',
        required_params: ['document_id', 'delay_seconds'],
        collection: 'documents',
        success_message: '延迟发布任务已创建',
        description: '提交后延迟指定时间后发布，支持倒计时。',
        tags: ['submit', 'delayed', 'scheduled']
      },
      # 新增查询策略
      {
        type: 'strategy',
        plugin_id: 'strategy-query-fuzzy',
        name: '模糊查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'FuzzyQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'fuzzy',
        required_params: ['keyword'],
        collection: 'documents',
        description: '支持模糊匹配查询，使用正则表达式进行模式匹配。',
        tags: ['query', 'fuzzy', 'pattern']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-exact',
        name: '精确查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'ExactQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'exact',
        required_params: ['field', 'value'],
        collection: 'documents',
        description: '精确匹配查询，支持多字段组合精确查询。',
        tags: ['query', 'exact', 'match']
      },
      # 新增删除策略
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-scheduled',
        name: '定时删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'ScheduledDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'scheduled',
        required_params: ['document_id', 'delete_time'],
        collection: 'documents',
        success_message: '定时删除任务已创建',
        description: '在指定时间自动删除文档，支持定时任务。',
        tags: ['delete', 'scheduled', 'automation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-recycle',
        name: '回收站删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'RecycleDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'recycle',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已移至回收站',
        description: '删除文档时移至回收站，支持恢复功能。',
        tags: ['delete', 'recycle', 'recoverable']
      },
      # 新增权限策略
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-geofence',
        name: '地理围栏权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'GeofencePermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'geofence',
        required_params: [],
        description: '基于地理位置的权限控制，支持地理围栏限制访问范围。',
        tags: ['permission', 'geofence', 'location']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-org-hierarchy',
        name: '组织层级联动权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'OrgHierarchyPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'org_hierarchy',
        required_params: [],
        description: '基于组织层级的权限控制，支持上下级数据联动访问。',
        tags: ['permission', 'organization', 'hierarchy']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-field-masking',
        name: '字段级脱敏权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'FieldMaskingPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'field_masking',
        required_params: [],
        description: '字段级别的数据脱敏，支持敏感字段自动脱敏显示。',
        tags: ['permission', 'masking', 'privacy']
      },
      # 新增验证策略
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-cross-field',
        name: '跨字段一致性验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'CrossFieldValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'cross_field',
        required_params: ['data'],
        description: '验证多个字段之间的一致性，如开始时间必须早于结束时间。',
        tags: ['validation', 'cross_field', 'consistency']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-referential',
        name: '引用完整性验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'ReferentialValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'referential',
        required_params: ['data'],
        description: '验证关联数据的引用完整性，确保关联数据存在且有效。',
        tags: ['validation', 'referential', 'integrity']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-threshold',
        name: '阈值区间验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'ThresholdValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'threshold',
        required_params: ['data', 'field'],
        description: '验证字段值是否在指定阈值区间内，支持动态阈值配置。',
        tags: ['validation', 'threshold', 'range']
      },
      # 新增保存策略
      {
        type: 'strategy',
        plugin_id: 'strategy-save-deduplicate',
        name: '去重保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'DeduplicateSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'deduplicate',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已去重保存',
        description: '保存前自动去重，避免重复数据。',
        tags: ['save', 'deduplicate', 'unique']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-merge',
        name: '合并保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'MergeSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'merge',
        required_params: ['data', 'document_id'],
        collection: 'documents',
        success_message: '文档已合并保存',
        description: '将新数据合并到现有文档，支持字段级合并策略。',
        tags: ['save', 'merge', 'update']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-snapshot',
        name: '快照保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'SnapshotSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'snapshot',
        required_params: ['data'],
        collection: 'documents_snapshot',
        success_message: '文档快照已保存',
        description: '保存文档快照，用于版本对比和回滚。',
        tags: ['save', 'snapshot', 'version']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-delayed',
        name: '延迟保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'DelayedSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'delayed',
        required_params: ['data', 'delay_seconds'],
        collection: 'documents',
        success_message: '延迟保存任务已创建',
        description: '延迟指定时间后保存，支持定时任务。',
        tags: ['save', 'delayed', 'scheduled']
      },
      # 新增提交策略
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-ab-test',
        name: 'A/B测试发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'AbTestPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'ab_test',
        required_params: ['document_id', 'variant'],
        collection: 'documents',
        success_message: 'A/B测试发布已创建',
        description: '支持A/B测试发布，对比不同版本效果。',
        tags: ['submit', 'ab_test', 'experiment']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-auto',
        name: '自动发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'AutoPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'auto',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已自动发布',
        description: '满足条件时自动发布，无需人工干预。',
        tags: ['submit', 'auto', 'automation']
      },
      # 新增查询策略
      {
        type: 'strategy',
        plugin_id: 'strategy-query-range',
        name: '范围查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'RangeQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'range',
        required_params: ['field', 'min', 'max'],
        collection: 'documents',
        description: '支持范围查询，查询指定字段在范围内的数据。',
        tags: ['query', 'range', 'filter']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-sort',
        name: '排序查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'SortQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'sort',
        required_params: [],
        collection: 'documents',
        description: '支持多字段排序查询，可指定升序或降序。',
        tags: ['query', 'sort', 'order']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-group',
        name: '分组查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'GroupQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'group',
        required_params: ['group_by'],
        collection: 'documents',
        description: '支持分组查询，按指定字段分组统计。',
        tags: ['query', 'group', 'aggregate']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-distinct',
        name: '去重查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'DistinctQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'distinct',
        required_params: ['field'],
        collection: 'documents',
        description: '支持去重查询，返回指定字段的唯一值列表。',
        tags: ['query', 'distinct', 'unique']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-statistics',
        name: '统计查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'StatisticsQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'statistics',
        required_params: [],
        collection: 'documents',
        description: '支持统计查询，返回计数、求和、平均值等统计信息。',
        tags: ['query', 'statistics', 'aggregate']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-export',
        name: '导出查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'ExportQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'export',
        required_params: [],
        collection: 'documents',
        description: '支持导出查询结果，可导出为Excel、CSV等格式。',
        tags: ['query', 'export', 'file']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-history',
        name: '历史查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'HistoryQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'history',
        required_params: ['document_id'],
        collection: 'documents_history',
        description: '查询文档历史版本，支持版本对比。',
        tags: ['query', 'history', 'version']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-similar',
        name: '相似查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'SimilarQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'similar',
        required_params: ['document_id'],
        collection: 'documents',
        description: '查询相似文档，基于内容相似度算法。',
        tags: ['query', 'similar', 'recommendation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-recommend',
        name: '推荐查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'RecommendQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'recommend',
        required_params: ['user_id'],
        collection: 'documents',
        description: '基于用户行为推荐相关文档。',
        tags: ['query', 'recommend', 'personalization']
      },
      # 新增权限策略
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-dynamic',
        name: '动态权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'DynamicPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'dynamic',
        required_params: [],
        description: '基于运行时条件动态计算权限，支持复杂权限规则。',
        tags: ['permission', 'dynamic', 'runtime']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-temporary',
        name: '临时权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'TemporaryPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'temporary',
        required_params: [],
        description: '授予临时访问权限，支持过期时间自动回收。',
        tags: ['permission', 'temporary', 'timeout']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-delegate',
        name: '委托权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'DelegatePermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'delegate',
        required_params: [],
        description: '支持权限委托，允许用户临时授权他人访问。',
        tags: ['permission', 'delegate', 'authorization']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-inherit',
        name: '继承权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'InheritPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'inherit',
        required_params: [],
        description: '支持权限继承，子资源自动继承父资源权限。',
        tags: ['permission', 'inherit', 'hierarchy']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-composite',
        name: '组合权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'CompositePermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'composite',
        required_params: [],
        description: '组合多个权限策略，支持AND/OR逻辑组合。',
        tags: ['permission', 'composite', 'logic']
      },
      # 新增验证策略
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-data-integrity',
        name: '数据完整性验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'DataIntegrityValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'data_integrity',
        required_params: ['data'],
        description: '验证数据完整性，确保必填字段和关联数据完整。',
        tags: ['validation', 'integrity', 'completeness']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-relation',
        name: '关联验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'RelationValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'relation',
        required_params: ['data'],
        description: '验证关联数据有效性，确保关联关系正确。',
        tags: ['validation', 'relation', 'reference']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-range',
        name: '范围验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'RangeValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'range',
        required_params: ['data', 'field'],
        description: '验证字段值是否在指定范围内，支持数值和日期范围。',
        tags: ['validation', 'range', 'boundary']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-length',
        name: '长度验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'LengthValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'length',
        required_params: ['data', 'field'],
        description: '验证字段长度，支持最小长度、最大长度限制。',
        tags: ['validation', 'length', 'size']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-type',
        name: '类型验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'TypeValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'type',
        required_params: ['data', 'field'],
        description: '验证字段数据类型，确保类型匹配。',
        tags: ['validation', 'type', 'datatype']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-regex',
        name: '正则验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'RegexValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'regex',
        required_params: ['data', 'field', 'pattern'],
        description: '使用正则表达式验证字段格式，支持自定义模式。',
        tags: ['validation', 'regex', 'pattern']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-async',
        name: '异步验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'AsyncValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'async',
        required_params: ['data'],
        description: '异步执行验证，适用于耗时较长的验证逻辑。',
        tags: ['validation', 'async', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-batch',
        name: '批量验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'BatchValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'batch',
        required_params: ['data_list'],
        description: '批量验证多条数据，提高验证效率。',
        tags: ['validation', 'batch', 'performance']
      },
      # 新增通知策略
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-push',
        name: '推送通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'PushNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'push',
        required_params: ['user_id', 'message'],
        description: '发送推送通知，支持移动端和Web端推送。',
        tags: ['notification', 'push', 'mobile']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-voice',
        name: '语音通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'VoiceNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'voice',
        required_params: ['phone', 'message'],
        description: '发送语音通知，支持电话语音播报。',
        tags: ['notification', 'voice', 'phone']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-custom',
        name: '自定义通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'CustomNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'custom',
        required_params: ['channel', 'message'],
        description: '支持自定义通知渠道，可扩展新的通知方式。',
        tags: ['notification', 'custom', 'extensible']
      },
      # 新增工作流策略
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-counter-sign',
        name: '会签策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'CounterSignWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'counter_sign',
        required_params: ['document_id', 'approver_ids'],
        description: '会签流程，需要所有审批人同意才能通过。',
        tags: ['workflow', 'counter_sign', 'approval']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-or-sign',
        name: '或签策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'OrSignWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'or_sign',
        required_params: ['document_id', 'approver_ids'],
        description: '或签流程，任意一个审批人同意即可通过。',
        tags: ['workflow', 'or_sign', 'approval']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-transfer',
        name: '转办策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'TransferWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'transfer',
        required_params: ['document_id', 'from_user_id', 'to_user_id'],
        description: '转办任务，将任务转交给其他处理人。',
        tags: ['workflow', 'transfer', 'assignment']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-add-signer',
        name: '加签策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'AddSignerWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'add_signer',
        required_params: ['document_id', 'approver_id'],
        description: '加签流程，在审批流程中增加审批人。',
        tags: ['workflow', 'add_signer', 'approval']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-return',
        name: '退回策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'ReturnWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'return',
        required_params: ['document_id', 'target_node'],
        description: '退回流程，将任务退回到指定节点重新处理。',
        tags: ['workflow', 'return', 'rollback']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-withdraw',
        name: '撤回策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'WithdrawWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'withdraw',
        required_params: ['document_id'],
        description: '撤回流程，撤回已提交的审批流程。',
        tags: ['workflow', 'withdraw', 'cancel']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-urge',
        name: '催办策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'UrgeWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'urge',
        required_params: ['document_id'],
        description: '催办流程，发送催办通知提醒处理人。',
        tags: ['workflow', 'urge', 'reminder']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-timeout',
        name: '超时处理策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'TimeoutWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'timeout',
        required_params: ['document_id'],
        description: '超时处理，任务超时后自动处理或转办。',
        tags: ['workflow', 'timeout', 'automation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-conditional-transition',
        name: '条件流转策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'ConditionalTransitionWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'conditional_transition',
        required_params: ['document_id', 'condition'],
        description: '条件流转，根据条件决定流程走向。',
        tags: ['workflow', 'conditional', 'transition']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-auto-transition',
        name: '自动流转策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'AutoTransitionWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'auto_transition',
        required_params: ['document_id'],
        description: '自动流转，满足条件时自动进入下一节点。',
        tags: ['workflow', 'auto', 'automation']
      },
      # 新增保存策略
      {
        type: 'strategy',
        plugin_id: 'strategy-save-queue',
        name: '队列保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'QueueSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'queue',
        required_params: ['data'],
        collection: 'documents',
        success_message: '保存任务已加入队列',
        description: '将保存任务加入队列，异步处理。',
        tags: ['save', 'queue', 'async']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-replicate',
        name: '复制保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'ReplicateSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'replicate',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已复制保存',
        description: '保存数据到多个副本，支持数据复制。',
        tags: ['save', 'replicate', 'redundancy']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-optimize',
        name: '优化保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'OptimizeSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'optimize',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已优化保存',
        description: '保存前优化数据结构，提高存储效率。',
        tags: ['save', 'optimize', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-save-index',
        name: '索引保存策略',
        category: 'strategy/save',
        category_module: 'Save',
        class_name: 'IndexSaveStrategy',
        domain: 'document',
        action: 'save',
        context: 'index',
        required_params: ['data'],
        collection: 'documents',
        success_message: '文档已保存并建立索引',
        description: '保存数据并自动建立索引，提高查询效率。',
        tags: ['save', 'index', 'performance']
      },
      # 新增提交策略
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-version-compare',
        name: '版本对比发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'VersionComparePublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'version_compare',
        required_params: ['document_id', 'compare_version'],
        collection: 'documents',
        success_message: '版本对比发布已创建',
        description: '对比版本差异后发布，支持版本对比。',
        tags: ['submit', 'version', 'compare']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-manual',
        name: '手动发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'ManualPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'manual',
        required_params: ['document_id', 'operator_id'],
        collection: 'documents',
        success_message: '文档已手动发布',
        description: '需要人工确认后发布，支持手动审批。',
        tags: ['submit', 'manual', 'approval']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-conditional-review',
        name: '条件审核发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'ConditionalReviewPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'conditional_review',
        required_params: ['document_id', 'condition'],
        collection: 'documents',
        success_message: '条件审核发布已创建',
        description: '根据条件决定是否需要审核后发布。',
        tags: ['submit', 'conditional', 'review']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-batch-review',
        name: '批量审核发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'BatchReviewPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'batch_review',
        required_params: ['document_ids'],
        collection: 'documents',
        success_message: '批量审核发布已创建',
        description: '批量提交审核后发布，提高审核效率。',
        tags: ['submit', 'batch', 'review']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-submit-priority',
        name: '优先级发布策略',
        category: 'strategy/submit',
        category_module: 'Submit',
        class_name: 'PriorityPublishStrategy',
        domain: 'document',
        action: 'submit',
        context: 'priority',
        required_params: ['document_id', 'priority'],
        collection: 'documents',
        success_message: '优先级发布已创建',
        description: '根据优先级决定发布顺序，支持优先级队列。',
        tags: ['submit', 'priority', 'queue']
      },
      # 新增查询策略
      {
        type: 'strategy',
        plugin_id: 'strategy-query-facets',
        name: '分面查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'FacetsQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'facets',
        required_params: [],
        collection: 'documents',
        description: '支持分面查询，返回分类统计信息。',
        tags: ['query', 'facets', 'aggregate']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-nested',
        name: '嵌套查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'NestedQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'nested',
        required_params: [],
        collection: 'documents',
        description: '支持嵌套字段查询，查询嵌套对象内的数据。',
        tags: ['query', 'nested', 'complex']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-geospatial',
        name: '地理空间查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'GeospatialQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'geospatial',
        required_params: ['location', 'radius'],
        collection: 'documents',
        description: '支持地理空间查询，基于地理位置范围查询。',
        tags: ['query', 'geospatial', 'location']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-time-series',
        name: '时间序列查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'TimeSeriesQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'time_series',
        required_params: ['time_field', 'start_time', 'end_time'],
        collection: 'documents',
        description: '支持时间序列查询，按时间范围查询数据。',
        tags: ['query', 'time_series', 'temporal']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-faceted-search',
        name: '分面搜索策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'FacetedSearchQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'faceted_search',
        required_params: ['keyword'],
        collection: 'documents',
        description: '支持分面搜索，结合全文搜索和分面统计。',
        tags: ['query', 'faceted_search', 'search']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-multi-index',
        name: '多索引查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'MultiIndexQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'multi_index',
        required_params: [],
        collection: 'documents',
        description: '支持多索引查询，跨多个索引查询数据。',
        tags: ['query', 'multi_index', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-batch',
        name: '批量查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'BatchQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'batch',
        required_params: ['document_ids'],
        collection: 'documents',
        description: '支持批量查询，一次查询多个文档。',
        tags: ['query', 'batch', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-stream',
        name: '流式查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'StreamQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'stream',
        required_params: [],
        collection: 'documents',
        description: '支持流式查询，实时返回查询结果。',
        tags: ['query', 'stream', 'realtime']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-vector',
        name: '向量查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'VectorQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'vector',
        required_params: ['vector'],
        collection: 'documents',
        description: '支持向量查询，基于向量相似度查询。',
        tags: ['query', 'vector', 'similarity']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-graph',
        name: '图查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'GraphQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'graph',
        required_params: ['start_node'],
        collection: 'documents',
        description: '支持图查询，基于图结构查询关联数据。',
        tags: ['query', 'graph', 'relation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-query-fuzzy-match',
        name: '模糊匹配查询策略',
        category: 'strategy/query',
        category_module: 'Query',
        class_name: 'FuzzyMatchQueryStrategy',
        domain: 'document',
        action: 'query',
        context: 'fuzzy_match',
        required_params: ['field', 'value'],
        collection: 'documents',
        description: '支持模糊匹配查询，使用编辑距离算法。',
        tags: ['query', 'fuzzy_match', 'algorithm']
      },
      # 新增删除策略
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-logical',
        name: '逻辑删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'LogicalDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'logical',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已逻辑删除',
        description: '逻辑删除文档，标记删除状态但保留数据。',
        tags: ['delete', 'logical', 'recoverable']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-delete-physical',
        name: '物理删除策略',
        category: 'strategy/delete',
        category_module: 'Delete',
        class_name: 'PhysicalDeleteStrategy',
        domain: 'document',
        action: 'delete',
        context: 'physical',
        required_params: ['document_id'],
        collection: 'documents',
        success_message: '文档已物理删除',
        description: '物理删除文档，从存储中彻底删除数据。',
        tags: ['delete', 'physical', 'permanent']
      },
      # 新增权限策略
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-attribute-based',
        name: '基于属性权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'AttributeBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'attribute_based',
        required_params: [],
        description: '基于用户属性控制权限，支持ABAC模型。',
        tags: ['permission', 'attribute', 'abac']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-resource-based',
        name: '基于资源权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'ResourceBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'resource_based',
        required_params: [],
        description: '基于资源类型控制权限，支持资源级权限控制。',
        tags: ['permission', 'resource', 'rbac']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-rule-based',
        name: '基于规则权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'RuleBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'rule_based',
        required_params: [],
        description: '基于规则引擎控制权限，支持复杂权限规则。',
        tags: ['permission', 'rule', 'engine']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-context-based',
        name: '基于上下文权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'ContextBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'context_based',
        required_params: [],
        description: '基于上下文环境控制权限，支持环境感知权限。',
        tags: ['permission', 'context', 'environment']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-tag-based',
        name: '基于标签权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'TagBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'tag_based',
        required_params: [],
        description: '基于标签控制权限，支持标签匹配权限。',
        tags: ['permission', 'tag', 'matching']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-ownership-based',
        name: '基于所有权权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'OwnershipBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'ownership_based',
        required_params: [],
        description: '基于数据所有权控制权限，所有者拥有完全权限。',
        tags: ['permission', 'ownership', 'owner']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-time-window',
        name: '时间窗口权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'TimeWindowPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'time_window',
        required_params: [],
        description: '基于时间窗口控制权限，支持时间段权限控制。',
        tags: ['permission', 'time_window', 'schedule']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-ip-whitelist',
        name: 'IP白名单权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'IpWhitelistPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'ip_whitelist',
        required_params: [],
        description: '基于IP白名单控制权限，仅允许白名单IP访问。',
        tags: ['permission', 'ip_whitelist', 'security']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-device-based',
        name: '基于设备权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'DeviceBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'device_based',
        required_params: [],
        description: '基于设备类型控制权限，支持设备级权限控制。',
        tags: ['permission', 'device', 'mobile']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-permission-location-based',
        name: '基于位置权限策略',
        category: 'strategy/permission',
        category_module: 'Permission',
        class_name: 'LocationBasedPermissionStrategy',
        domain: 'permission',
        action: 'filter',
        context: 'location_based',
        required_params: [],
        description: '基于地理位置控制权限，支持位置感知权限。',
        tags: ['permission', 'location', 'geolocation']
      },
      # 新增验证策略
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-custom',
        name: '自定义验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'CustomValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'custom',
        required_params: ['data', 'validator'],
        description: '支持自定义验证逻辑，可扩展验证规则。',
        tags: ['validation', 'custom', 'extensible']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-conditional',
        name: '条件验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'ConditionalValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'conditional',
        required_params: ['data', 'condition'],
        description: '根据条件执行不同的验证规则。',
        tags: ['validation', 'conditional', 'rule']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-dependency',
        name: '依赖验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'DependencyValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'dependency',
        required_params: ['data'],
        description: '验证字段依赖关系，确保依赖字段有效。',
        tags: ['validation', 'dependency', 'relation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-format-custom',
        name: '自定义格式验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'CustomFormatValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'format_custom',
        required_params: ['data', 'field', 'pattern'],
        description: '使用自定义格式模式验证字段值。',
        tags: ['validation', 'format', 'custom']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-business-logic',
        name: '业务逻辑验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'BusinessLogicValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'business_logic',
        required_params: ['data'],
        description: '验证复杂业务逻辑，支持多步骤验证。',
        tags: ['validation', 'business_logic', 'complex']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-external',
        name: '外部验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'ExternalValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'external',
        required_params: ['data', 'validator_url'],
        description: '调用外部服务进行验证，支持第三方验证。',
        tags: ['validation', 'external', 'api']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-cascade',
        name: '级联验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'CascadeValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'cascade',
        required_params: ['data'],
        description: '级联验证关联数据，确保关联数据有效。',
        tags: ['validation', 'cascade', 'relation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-sequential',
        name: '顺序验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'SequentialValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'sequential',
        required_params: ['data', 'validators'],
        description: '按顺序执行多个验证器，支持验证链。',
        tags: ['validation', 'sequential', 'chain']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-parallel',
        name: '并行验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'ParallelValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'parallel',
        required_params: ['data', 'validators'],
        description: '并行执行多个验证器，提高验证效率。',
        tags: ['validation', 'parallel', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-validation-cache',
        name: '缓存验证策略',
        category: 'strategy/validation',
        category_module: 'Validation',
        class_name: 'CacheValidationStrategy',
        domain: 'validation',
        action: 'validate',
        context: 'cache',
        required_params: ['data'],
        description: '使用缓存加速验证，提高验证性能。',
        tags: ['validation', 'cache', 'performance']
      },
      # 新增通知策略
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-batch',
        name: '批量通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'BatchNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'batch',
        required_params: ['recipients', 'message'],
        description: '批量发送通知，支持批量处理。',
        tags: ['notification', 'batch', 'performance']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-scheduled',
        name: '定时通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'ScheduledNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'scheduled',
        required_params: ['recipient', 'message', 'schedule_time'],
        description: '定时发送通知，支持定时任务。',
        tags: ['notification', 'scheduled', 'automation']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-priority',
        name: '优先级通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'PriorityNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'priority',
        required_params: ['recipient', 'message', 'priority'],
        description: '根据优先级发送通知，支持优先级队列。',
        tags: ['notification', 'priority', 'queue']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-template',
        name: '模板通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'TemplateNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'template',
        required_params: ['recipient', 'template_id', 'data'],
        description: '使用模板发送通知，支持模板化消息。',
        tags: ['notification', 'template', 'message']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-retry',
        name: '重试通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'RetryNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'retry',
        required_params: ['recipient', 'message'],
        description: '失败时自动重试发送通知，支持重试机制。',
        tags: ['notification', 'retry', 'reliability']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-notification-multi-channel',
        name: '多渠道通知策略',
        category: 'strategy/notification',
        category_module: 'Notification',
        class_name: 'MultiChannelNotificationStrategy',
        domain: 'notification',
        action: 'notify',
        context: 'multi_channel',
        required_params: ['recipient', 'message', 'channels'],
        description: '通过多个渠道发送通知，提高送达率。',
        tags: ['notification', 'multi_channel', 'reliability']
      },
      # 新增工作流策略
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-sub-process',
        name: '子流程策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'SubProcessWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'sub_process',
        required_params: ['document_id', 'sub_process_id'],
        description: '启动子流程，支持流程嵌套。',
        tags: ['workflow', 'sub_process', 'nested']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-compensate',
        name: '补偿策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'CompensateWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'compensate',
        required_params: ['document_id'],
        description: '执行补偿操作，支持事务回滚。',
        tags: ['workflow', 'compensate', 'rollback']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-escalation',
        name: '升级策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'EscalationWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'escalation',
        required_params: ['document_id'],
        description: '任务升级处理，超时或异常时升级。',
        tags: ['workflow', 'escalation', 'exception']
      },
      {
        type: 'strategy',
        plugin_id: 'strategy-workflow-delegate',
        name: '委托策略',
        category: 'strategy/workflow',
        category_module: 'Workflow',
        class_name: 'DelegateWorkflowStrategy',
        domain: 'workflow',
        action: 'process',
        context: 'delegate',
        required_params: ['document_id', 'delegate_to'],
        description: '委托任务给其他处理人，支持任务委托。',
        tags: ['workflow', 'delegate', 'assignment']
      }
    ]
  end
  
  # 生成字段类型插件配置模板
  def self.create_field_type_plugin_configs
    [
      # 基础类型（10+）
      {
        type: 'field_type',
        plugin_id: 'field-type-text',
        name: '文本字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'TextFieldType',
        field_type_name: 'text',
        description: '标准文本字段类型，支持字符串输入和验证。',
        tags: ['field_type', 'basic', 'text']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-number',
        name: '数字字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'NumberFieldType',
        field_type_name: 'number',
        description: '数字字段类型，支持整数和浮点数，可设置范围。',
        tags: ['field_type', 'basic', 'number']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-date',
        name: '日期字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'DateFieldType',
        field_type_name: 'date',
        description: '日期字段类型，支持日期选择和数据验证。',
        tags: ['field_type', 'basic', 'date']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-boolean',
        name: '布尔字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'BooleanFieldType',
        field_type_name: 'boolean',
        description: '布尔字段类型，支持true/false值。',
        tags: ['field_type', 'basic', 'boolean']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-enum',
        name: '枚举字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'EnumFieldType',
        field_type_name: 'enum',
        description: '枚举字段类型，支持预定义选项列表。',
        tags: ['field_type', 'basic', 'enum']
      },
      # 业务类型（30+）
      {
        type: 'field_type',
        plugin_id: 'field-type-phone',
        name: '手机号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'PhoneFieldType',
        field_type_name: 'phone',
        description: '手机号字段类型，自动验证手机号格式。',
        tags: ['field_type', 'business', 'phone', 'validation']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-email',
        name: '邮箱字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'EmailFieldType',
        field_type_name: 'email',
        description: '邮箱字段类型，自动验证邮箱格式。',
        tags: ['field_type', 'business', 'email', 'validation']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-id-card',
        name: '身份证字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'IdCardFieldType',
        field_type_name: 'id_card',
        description: '身份证字段类型，自动验证身份证号码格式和校验位。',
        tags: ['field_type', 'business', 'id_card', 'validation']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-amount',
        name: '金额字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'AmountFieldType',
        field_type_name: 'amount',
        description: '金额字段类型，支持货币格式化和精度控制。',
        tags: ['field_type', 'business', 'amount', 'currency']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-percentage',
        name: '百分比字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'PercentageFieldType',
        field_type_name: 'percentage',
        description: '百分比字段类型，支持0-100范围验证和格式化。',
        tags: ['field_type', 'business', 'percentage']
      },
      # 复合类型（15+）
      {
        type: 'field_type',
        plugin_id: 'field-type-address',
        name: '地址字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'AddressFieldType',
        field_type_name: 'address',
        description: '地址字段类型，支持省市区三级联动选择。',
        tags: ['field_type', 'composite', 'address']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-json-object',
        name: 'JSON对象字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'JsonObjectFieldType',
        field_type_name: 'json_object',
        description: 'JSON对象字段类型，支持复杂的嵌套数据结构。',
        tags: ['field_type', 'composite', 'json']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-array',
        name: '数组字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'ArrayFieldType',
        field_type_name: 'array',
        description: '数组字段类型，支持存储多个值的列表。',
        tags: ['field_type', 'composite', 'array']
      },
      # 关联类型（10+）
      {
        type: 'field_type',
        plugin_id: 'field-type-single-relation',
        name: '单关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'SingleRelationFieldType',
        field_type_name: 'single_relation',
        description: '单关联字段类型，支持一对一或一对多关系。',
        tags: ['field_type', 'relation', 'single']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-multiple-relation',
        name: '多关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'MultipleRelationFieldType',
        field_type_name: 'multiple_relation',
        description: '多关联字段类型，支持多对多关系。',
        tags: ['field_type', 'relation', 'multiple']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-tree-relation',
        name: '树形关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'TreeRelationFieldType',
        field_type_name: 'tree_relation',
        description: '树形关联字段类型，支持树形结构数据。',
        tags: ['field_type', 'relation', 'tree']
      },
      # 特殊类型（20+）
      {
        type: 'field_type',
        plugin_id: 'field-type-rich-text',
        name: '富文本字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'RichTextFieldType',
        field_type_name: 'rich_text',
        description: '富文本字段类型，支持HTML格式的文本编辑。',
        tags: ['field_type', 'special', 'rich_text', 'html']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-markdown',
        name: 'Markdown字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'MarkdownFieldType',
        field_type_name: 'markdown',
        description: 'Markdown字段类型，支持Markdown格式的文本编辑。',
        tags: ['field_type', 'special', 'markdown']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-code-editor',
        name: '代码编辑器字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'CodeEditorFieldType',
        field_type_name: 'code_editor',
        description: '代码编辑器字段类型，支持代码高亮和语法检查。',
        tags: ['field_type', 'special', 'code', 'editor']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-formula',
        name: '公式计算字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'FormulaFieldType',
        field_type_name: 'formula',
        description: '公式计算字段类型，支持基于其他字段的自动计算。',
        tags: ['field_type', 'special', 'formula', 'calculation']
      },
      # 基础类型补充
      {
        type: 'field_type',
        plugin_id: 'field-type-file',
        name: '文件字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'FileFieldType',
        field_type_name: 'file',
        description: '文件字段类型，支持文件上传和下载。',
        tags: ['field_type', 'basic', 'file', 'upload']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-image',
        name: '图片字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'ImageFieldType',
        field_type_name: 'image',
        description: '图片字段类型，支持图片上传、预览和裁剪。',
        tags: ['field_type', 'basic', 'image', 'upload']
      },
      # 业务类型补充
      {
        type: 'field_type',
        plugin_id: 'field-type-bank-card',
        name: '银行卡字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'BankCardFieldType',
        field_type_name: 'bank_card',
        description: '银行卡字段类型，自动验证银行卡号格式和校验位。',
        tags: ['field_type', 'business', 'bank_card', 'validation']
      },
      # 特殊类型补充
      {
        type: 'field_type',
        plugin_id: 'field-type-signature',
        name: '签名板字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'SignatureFieldType',
        field_type_name: 'signature',
        description: '签名板字段类型，支持手写签名采集和图片存储。',
        tags: ['field_type', 'special', 'signature', 'handwriting']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-progress',
        name: '进度条字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'ProgressFieldType',
        field_type_name: 'progress',
        description: '进度条字段类型，支持数值进度显示和百分比展示。',
        tags: ['field_type', 'special', 'progress', 'percentage']
      },
      # 新增基础类型
      {
        type: 'field_type',
        plugin_id: 'field-type-time',
        name: '时间字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'TimeFieldType',
        field_type_name: 'time',
        description: '时间字段类型，支持时分秒选择。',
        tags: ['field_type', 'basic', 'time']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-datetime',
        name: '日期时间字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'DateTimeFieldType',
        field_type_name: 'datetime',
        description: '日期时间字段类型，支持日期和时间组合选择。',
        tags: ['field_type', 'basic', 'datetime']
      },
      # 新增复合类型
      {
        type: 'field_type',
        plugin_id: 'field-type-date-range',
        name: '日期范围字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'DateRangeFieldType',
        field_type_name: 'date_range',
        description: '日期范围字段类型，支持开始日期和结束日期选择。',
        tags: ['field_type', 'composite', 'date_range']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-coordinate',
        name: '坐标字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'CoordinateFieldType',
        field_type_name: 'coordinate',
        description: '坐标字段类型，支持经纬度坐标输入和地图选择。',
        tags: ['field_type', 'composite', 'coordinate', 'map']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-color',
        name: '颜色字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'ColorFieldType',
        field_type_name: 'color',
        description: '颜色字段类型，支持颜色选择器和十六进制输入。',
        tags: ['field_type', 'composite', 'color']
      },
      # 新增业务类型
      {
        type: 'field_type',
        plugin_id: 'field-type-url',
        name: 'URL字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'UrlFieldType',
        field_type_name: 'url',
        description: 'URL字段类型，自动验证URL格式。',
        tags: ['field_type', 'business', 'url', 'validation']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-ip',
        name: 'IP地址字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'IpFieldType',
        field_type_name: 'ip',
        description: 'IP地址字段类型，自动验证IPv4和IPv6格式。',
        tags: ['field_type', 'business', 'ip', 'validation']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-credit-code',
        name: '统一社会信用代码字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'CreditCodeFieldType',
        field_type_name: 'credit_code',
        description: '统一社会信用代码字段类型，自动验证18位信用代码格式。',
        tags: ['field_type', 'business', 'credit_code', 'validation']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-tax-id',
        name: '税号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'TaxIdFieldType',
        field_type_name: 'tax_id',
        description: '税号字段类型，自动验证税号格式。',
        tags: ['field_type', 'business', 'tax_id', 'validation']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-currency',
        name: '货币字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'CurrencyFieldType',
        field_type_name: 'currency',
        description: '货币字段类型，支持多币种和汇率转换。',
        tags: ['field_type', 'business', 'currency', 'money']
      },
      # 新增特殊类型
      {
        type: 'field_type',
        plugin_id: 'field-type-qrcode',
        name: '二维码字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'QrcodeFieldType',
        field_type_name: 'qrcode',
        description: '二维码字段类型，支持生成和扫描二维码。',
        tags: ['field_type', 'special', 'qrcode', 'barcode']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-barcode',
        name: '条形码字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'BarcodeFieldType',
        field_type_name: 'barcode',
        description: '条形码字段类型，支持生成和扫描条形码。',
        tags: ['field_type', 'special', 'barcode']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-video',
        name: '视频字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'VideoFieldType',
        field_type_name: 'video',
        description: '视频字段类型，支持视频上传、预览和播放。',
        tags: ['field_type', 'special', 'video', 'upload']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-audio',
        name: '音频字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'AudioFieldType',
        field_type_name: 'audio',
        description: '音频字段类型，支持音频上传和播放。',
        tags: ['field_type', 'special', 'audio', 'upload']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-slider',
        name: '滑块字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'SliderFieldType',
        field_type_name: 'slider',
        description: '滑块字段类型，支持数值范围选择。',
        tags: ['field_type', 'special', 'slider', 'range']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-rating',
        name: '评分字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'RatingFieldType',
        field_type_name: 'rating',
        description: '评分字段类型，支持星级评分和数字评分。',
        tags: ['field_type', 'special', 'rating', 'star']
      },
      # 新增基础类型
      {
        type: 'field_type',
        plugin_id: 'field-type-boolean',
        name: '布尔字段类型',
        category: 'field_type/basic',
        category_module: 'Basic',
        class_name: 'BooleanFieldType',
        field_type_name: 'boolean',
        description: '布尔字段类型，支持true/false值。',
        tags: ['field_type', 'basic', 'boolean']
      },
      # 新增复合类型
      {
        type: 'field_type',
        plugin_id: 'field-type-address',
        name: '地址字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'AddressFieldType',
        field_type_name: 'address',
        description: '地址字段类型，支持省市区详细地址。',
        tags: ['field_type', 'composite', 'address', 'location']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-contact',
        name: '联系方式字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'ContactFieldType',
        field_type_name: 'contact',
        description: '联系方式字段类型，支持电话、邮箱、地址等。',
        tags: ['field_type', 'composite', 'contact']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-name',
        name: '姓名字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'NameFieldType',
        field_type_name: 'name',
        description: '姓名字段类型，支持姓和名分开存储。',
        tags: ['field_type', 'composite', 'name']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-json',
        name: 'JSON字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'JsonFieldType',
        field_type_name: 'json',
        description: 'JSON字段类型，支持存储任意JSON结构。',
        tags: ['field_type', 'composite', 'json', 'flexible']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-array',
        name: '数组字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'ArrayFieldType',
        field_type_name: 'array',
        description: '数组字段类型，支持存储数组数据。',
        tags: ['field_type', 'composite', 'array', 'list']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-object',
        name: '对象字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'ObjectFieldType',
        field_type_name: 'object',
        description: '对象字段类型，支持存储嵌套对象。',
        tags: ['field_type', 'composite', 'object', 'nested']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-map',
        name: '地图字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'MapFieldType',
        field_type_name: 'map',
        description: '地图字段类型，支持存储键值对映射。',
        tags: ['field_type', 'composite', 'map', 'key_value']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-tuple',
        name: '元组字段类型',
        category: 'field_type/composite',
        category_module: 'Composite',
        class_name: 'TupleFieldType',
        field_type_name: 'tuple',
        description: '元组字段类型，支持存储固定结构的数据。',
        tags: ['field_type', 'composite', 'tuple', 'fixed']
      },
      # 新增关联类型
      {
        type: 'field_type',
        plugin_id: 'field-type-many-to-many',
        name: '多对多关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'ManyToManyFieldType',
        field_type_name: 'many_to_many',
        description: '多对多关联字段类型，支持双向关联。',
        tags: ['field_type', 'relation', 'many_to_many']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-one-to-many',
        name: '一对多关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'OneToManyFieldType',
        field_type_name: 'one_to_many',
        description: '一对多关联字段类型，支持一对多关系。',
        tags: ['field_type', 'relation', 'one_to_many']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-polymorphic',
        name: '多态关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'PolymorphicFieldType',
        field_type_name: 'polymorphic',
        description: '多态关联字段类型，支持多态关联。',
        tags: ['field_type', 'relation', 'polymorphic']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-self-referencing',
        name: '自关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'SelfReferencingFieldType',
        field_type_name: 'self_referencing',
        description: '自关联字段类型，支持树形结构。',
        tags: ['field_type', 'relation', 'self_referencing', 'tree']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-through',
        name: '中间表关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'ThroughFieldType',
        field_type_name: 'through',
        description: '中间表关联字段类型，支持通过中间表关联。',
        tags: ['field_type', 'relation', 'through', 'join']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-has-many-through',
        name: '通过关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'HasManyThroughFieldType',
        field_type_name: 'has_many_through',
        description: '通过关联字段类型，支持has_many_through关系。',
        tags: ['field_type', 'relation', 'has_many_through']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-has-and-belongs-to-many',
        name: '多对多直接关联字段类型',
        category: 'field_type/relation',
        category_module: 'Relation',
        class_name: 'HasAndBelongsToManyFieldType',
        field_type_name: 'has_and_belongs_to_many',
        description: '多对多直接关联字段类型，支持直接关联。',
        tags: ['field_type', 'relation', 'has_and_belongs_to_many']
      },
      # 新增业务类型
      {
        type: 'field_type',
        plugin_id: 'field-type-bank-card',
        name: '银行卡字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'BankCardFieldType',
        field_type_name: 'bank_card',
        description: '银行卡字段类型，支持银行卡号验证和格式化。',
        tags: ['field_type', 'business', 'bank_card', 'finance']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-id-card',
        name: '身份证字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'IdCardFieldType',
        field_type_name: 'id_card',
        description: '身份证字段类型，支持身份证号验证。',
        tags: ['field_type', 'business', 'id_card', 'identity']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-phone-number',
        name: '电话号码字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'PhoneNumberFieldType',
        field_type_name: 'phone_number',
        description: '电话号码字段类型，支持手机号和固定电话。',
        tags: ['field_type', 'business', 'phone', 'contact']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-email',
        name: '邮箱字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'EmailFieldType',
        field_type_name: 'email',
        description: '邮箱字段类型，支持邮箱格式验证。',
        tags: ['field_type', 'business', 'email', 'contact']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-postal-code',
        name: '邮政编码字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'PostalCodeFieldType',
        field_type_name: 'postal_code',
        description: '邮政编码字段类型，支持邮政编码验证。',
        tags: ['field_type', 'business', 'postal_code', 'address']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-license-plate',
        name: '车牌号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'LicensePlateFieldType',
        field_type_name: 'license_plate',
        description: '车牌号字段类型，支持车牌号验证。',
        tags: ['field_type', 'business', 'license_plate', 'vehicle']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-social-security',
        name: '社保号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'SocialSecurityFieldType',
        field_type_name: 'social_security',
        description: '社保号字段类型，支持社保号验证。',
        tags: ['field_type', 'business', 'social_security', 'identity']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-passport',
        name: '护照号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'PassportFieldType',
        field_type_name: 'passport',
        description: '护照号字段类型，支持护照号验证。',
        tags: ['field_type', 'business', 'passport', 'identity']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-company-code',
        name: '企业代码字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'CompanyCodeFieldType',
        field_type_name: 'company_code',
        description: '企业代码字段类型，支持统一社会信用代码等。',
        tags: ['field_type', 'business', 'company_code', 'enterprise']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-organization-code',
        name: '组织机构代码字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'OrganizationCodeFieldType',
        field_type_name: 'organization_code',
        description: '组织机构代码字段类型，支持组织机构代码验证。',
        tags: ['field_type', 'business', 'organization_code', 'enterprise']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-invoice-number',
        name: '发票号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'InvoiceNumberFieldType',
        field_type_name: 'invoice_number',
        description: '发票号字段类型，支持发票号验证。',
        tags: ['field_type', 'business', 'invoice_number', 'finance']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-contract-number',
        name: '合同号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'ContractNumberFieldType',
        field_type_name: 'contract_number',
        description: '合同号字段类型，支持合同号验证。',
        tags: ['field_type', 'business', 'contract_number', 'legal']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-order-number',
        name: '订单号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'OrderNumberFieldType',
        field_type_name: 'order_number',
        description: '订单号字段类型，支持订单号生成和验证。',
        tags: ['field_type', 'business', 'order_number', 'ecommerce']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-serial-number',
        name: '序列号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'SerialNumberFieldType',
        field_type_name: 'serial_number',
        description: '序列号字段类型，支持序列号生成和验证。',
        tags: ['field_type', 'business', 'serial_number', 'product']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-batch-number',
        name: '批次号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'BatchNumberFieldType',
        field_type_name: 'batch_number',
        description: '批次号字段类型，支持批次号生成和验证。',
        tags: ['field_type', 'business', 'batch_number', 'logistics']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-tracking-number',
        name: '追踪号字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'TrackingNumberFieldType',
        field_type_name: 'tracking_number',
        description: '追踪号字段类型，支持物流追踪号。',
        tags: ['field_type', 'business', 'tracking_number', 'logistics']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-mac-address',
        name: 'MAC地址字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'MacAddressFieldType',
        field_type_name: 'mac_address',
        description: 'MAC地址字段类型，支持MAC地址验证。',
        tags: ['field_type', 'business', 'mac_address', 'network']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-imei',
        name: 'IMEI字段类型',
        category: 'field_type/business',
        category_module: 'Business',
        class_name: 'ImeiFieldType',
        field_type_name: 'imei',
        description: 'IMEI字段类型，支持IMEI号验证。',
        tags: ['field_type', 'business', 'imei', 'device']
      },
      # 新增特殊类型
      {
        type: 'field_type',
        plugin_id: 'field-type-signature',
        name: '签名字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'SignatureFieldType',
        field_type_name: 'signature',
        description: '签名字段类型，支持手写签名和电子签名。',
        tags: ['field_type', 'special', 'signature', 'legal']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-fingerprint',
        name: '指纹字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'FingerprintFieldType',
        field_type_name: 'fingerprint',
        description: '指纹字段类型，支持指纹数据存储。',
        tags: ['field_type', 'special', 'fingerprint', 'biometric']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-encrypted',
        name: '加密字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'EncryptedFieldType',
        field_type_name: 'encrypted',
        description: '加密字段类型，支持字段级加密存储。',
        tags: ['field_type', 'special', 'encrypted', 'security']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-hash',
        name: '哈希字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'HashFieldType',
        field_type_name: 'hash',
        description: '哈希字段类型，支持存储哈希值。',
        tags: ['field_type', 'special', 'hash', 'security']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-token',
        name: '令牌字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'TokenFieldType',
        field_type_name: 'token',
        description: '令牌字段类型，支持存储访问令牌。',
        tags: ['field_type', 'special', 'token', 'security']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-uuid',
        name: 'UUID字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'UuidFieldType',
        field_type_name: 'uuid',
        description: 'UUID字段类型，支持UUID生成和验证。',
        tags: ['field_type', 'special', 'uuid', 'identifier']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-base64',
        name: 'Base64字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'Base64FieldType',
        field_type_name: 'base64',
        description: 'Base64字段类型，支持Base64编码数据。',
        tags: ['field_type', 'special', 'base64', 'encoding']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-compressed',
        name: '压缩字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'CompressedFieldType',
        field_type_name: 'compressed',
        description: '压缩字段类型，支持数据压缩存储。',
        tags: ['field_type', 'special', 'compressed', 'storage']
      },
      # 新增特殊类型
      {
        type: 'field_type',
        plugin_id: 'field-type-geojson',
        name: 'GeoJSON字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'GeojsonFieldType',
        field_type_name: 'geojson',
        description: 'GeoJSON字段类型，支持地理空间数据。',
        tags: ['field_type', 'special', 'geojson', 'geospatial']
      },
      {
        type: 'field_type',
        plugin_id: 'field-type-binary',
        name: '二进制字段类型',
        category: 'field_type/special',
        category_module: 'Special',
        class_name: 'BinaryFieldType',
        field_type_name: 'binary',
        description: '二进制字段类型，支持存储二进制数据。',
        tags: ['field_type', 'special', 'binary', 'data']
      }
    ]
  end
  
  # 生成UI组件插件配置模板
  def self.create_ui_component_plugin_configs
    [
      {
        type: 'ui_component',
        plugin_id: 'ui-component-table',
        name: '表格组件插件',
        category: 'other/ui_component',
        class_name: 'TableComponentPlugin',
        description: '渲染可分页、可排序的表格组件。',
        tags: ['ui', 'table', 'component'],
        render_logic: <<~'RUBY'
          # 返回极简HTML，真实项目可输出Layui或Vue配置
          return "<table class='kr-table'>#{data}</table>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-form',
        name: '表单组件插件',
        category: 'other/ui_component',
        class_name: 'FormComponentPlugin',
        description: '渲染动态表单组件，支持schema驱动。',
        tags: ['ui', 'form', 'component'],
        render_logic: <<~'RUBY'
          return "<form class='kr-form'></form>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-chart',
        name: '图表组件插件',
        category: 'other/ui_component',
        class_name: 'ChartComponentPlugin',
        description: '渲染图表组件，支持多种图表类型。',
        tags: ['ui', 'chart', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-chart' data-type='line'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-map',
        name: '地图组件插件',
        category: 'other/ui_component',
        class_name: 'MapComponentPlugin',
        description: '渲染地图组件，支持标记与热力图。',
        tags: ['ui', 'map', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-map'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-tree',
        name: '树形组件插件',
        category: 'other/ui_component',
        class_name: 'TreeComponentPlugin',
        description: '渲染树形组件，支持层级数据展示。',
        tags: ['ui', 'tree', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-tree'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-calendar',
        name: '日历组件插件',
        category: 'other/ui_component',
        class_name: 'CalendarComponentPlugin',
        description: '渲染日历组件，支持日期选择和事件展示。',
        tags: ['ui', 'calendar', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-calendar'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-carousel',
        name: '轮播图组件插件',
        category: 'other/ui_component',
        class_name: 'CarouselComponentPlugin',
        description: '渲染轮播图组件，支持图片和内容轮播。',
        tags: ['ui', 'carousel', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-carousel'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-tabs',
        name: '标签页组件插件',
        category: 'other/ui_component',
        class_name: 'TabsComponentPlugin',
        description: '渲染标签页组件，支持多标签切换。',
        tags: ['ui', 'tabs', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-tabs'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-dialog',
        name: '对话框组件插件',
        category: 'other/ui_component',
        class_name: 'DialogComponentPlugin',
        description: '渲染对话框组件，支持模态和非模态对话框。',
        tags: ['ui', 'dialog', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-dialog'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-menu',
        name: '菜单组件插件',
        category: 'other/ui_component',
        class_name: 'MenuComponentPlugin',
        description: '渲染菜单组件，支持多级菜单和导航。',
        tags: ['ui', 'menu', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-menu'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-pagination',
        name: '分页组件插件',
        category: 'other/ui_component',
        class_name: 'PaginationComponentPlugin',
        description: '渲染分页组件，支持分页导航。',
        tags: ['ui', 'pagination', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-pagination'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-tooltip',
        name: '提示框组件插件',
        category: 'other/ui_component',
        class_name: 'TooltipComponentPlugin',
        description: '渲染提示框组件，支持悬停提示。',
        tags: ['ui', 'tooltip', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-tooltip'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-badge',
        name: '徽章组件插件',
        category: 'other/ui_component',
        class_name: 'BadgeComponentPlugin',
        description: '渲染徽章组件，支持数字和状态徽章。',
        tags: ['ui', 'badge', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-badge'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-progress',
        name: '进度条组件插件',
        category: 'other/ui_component',
        class_name: 'ProgressComponentPlugin',
        description: '渲染进度条组件，支持进度显示。',
        tags: ['ui', 'progress', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-progress'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-button',
        name: '按钮组件插件',
        category: 'other/ui_component',
        class_name: 'ButtonComponentPlugin',
        description: '渲染按钮组件，支持多种样式和状态。',
        tags: ['ui', 'button', 'component'],
        render_logic: <<~'RUBY'
          return "<button class='kr-button'></button>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-input',
        name: '输入框组件插件',
        category: 'other/ui_component',
        class_name: 'InputComponentPlugin',
        description: '渲染输入框组件，支持多种输入类型。',
        tags: ['ui', 'input', 'component'],
        render_logic: <<~'RUBY'
          return "<input class='kr-input' />"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-select',
        name: '下拉选择组件插件',
        category: 'other/ui_component',
        class_name: 'SelectComponentPlugin',
        description: '渲染下拉选择组件，支持单选和多选。',
        tags: ['ui', 'select', 'component'],
        render_logic: <<~'RUBY'
          return "<select class='kr-select'></select>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-checkbox',
        name: '复选框组件插件',
        category: 'other/ui_component',
        class_name: 'CheckboxComponentPlugin',
        description: '渲染复选框组件，支持单个和多个选择。',
        tags: ['ui', 'checkbox', 'component'],
        render_logic: <<~'RUBY'
          return "<input type='checkbox' class='kr-checkbox' />"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-radio',
        name: '单选框组件插件',
        category: 'other/ui_component',
        class_name: 'RadioComponentPlugin',
        description: '渲染单选框组件，支持单选组。',
        tags: ['ui', 'radio', 'component'],
        render_logic: <<~'RUBY'
          return "<input type='radio' class='kr-radio' />"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-switch',
        name: '开关组件插件',
        category: 'other/ui_component',
        class_name: 'SwitchComponentPlugin',
        description: '渲染开关组件，支持开关状态切换。',
        tags: ['ui', 'switch', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-switch'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-slider',
        name: '滑块组件插件',
        category: 'other/ui_component',
        class_name: 'SliderComponentPlugin',
        description: '渲染滑块组件，支持数值范围选择。',
        tags: ['ui', 'slider', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-slider'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-rate',
        name: '评分组件插件',
        category: 'other/ui_component',
        class_name: 'RateComponentPlugin',
        description: '渲染评分组件，支持星级评分。',
        tags: ['ui', 'rate', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-rate'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-upload',
        name: '上传组件插件',
        category: 'other/ui_component',
        class_name: 'UploadComponentPlugin',
        description: '渲染文件上传组件，支持单文件和多文件上传。',
        tags: ['ui', 'upload', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-upload'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-transfer',
        name: '穿梭框组件插件',
        category: 'other/ui_component',
        class_name: 'TransferComponentPlugin',
        description: '渲染穿梭框组件，支持数据在两个列表间移动。',
        tags: ['ui', 'transfer', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-transfer'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-timeline',
        name: '时间轴组件插件',
        category: 'other/ui_component',
        class_name: 'TimelineComponentPlugin',
        description: '渲染时间轴组件，支持时间线展示。',
        tags: ['ui', 'timeline', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-timeline'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-steps',
        name: '步骤条组件插件',
        category: 'other/ui_component',
        class_name: 'StepsComponentPlugin',
        description: '渲染步骤条组件，支持流程步骤展示。',
        tags: ['ui', 'steps', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-steps'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-collapse',
        name: '折叠面板组件插件',
        category: 'other/ui_component',
        class_name: 'CollapseComponentPlugin',
        description: '渲染折叠面板组件，支持内容折叠展开。',
        tags: ['ui', 'collapse', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-collapse'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-card',
        name: '卡片组件插件',
        category: 'other/ui_component',
        class_name: 'CardComponentPlugin',
        description: '渲染卡片组件，支持内容卡片展示。',
        tags: ['ui', 'card', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-card'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-list',
        name: '列表组件插件',
        category: 'other/ui_component',
        class_name: 'ListComponentPlugin',
        description: '渲染列表组件，支持列表数据展示。',
        tags: ['ui', 'list', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-list'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-descriptions',
        name: '描述列表组件插件',
        category: 'other/ui_component',
        class_name: 'DescriptionsComponentPlugin',
        description: '渲染描述列表组件，支持键值对展示。',
        tags: ['ui', 'descriptions', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-descriptions'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-empty',
        name: '空状态组件插件',
        category: 'other/ui_component',
        class_name: 'EmptyComponentPlugin',
        description: '渲染空状态组件，支持空数据展示。',
        tags: ['ui', 'empty', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-empty'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-skeleton',
        name: '骨架屏组件插件',
        category: 'other/ui_component',
        class_name: 'SkeletonComponentPlugin',
        description: '渲染骨架屏组件，支持加载占位。',
        tags: ['ui', 'skeleton', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-skeleton'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-spin',
        name: '加载中组件插件',
        category: 'other/ui_component',
        class_name: 'SpinComponentPlugin',
        description: '渲染加载中组件，支持加载状态展示。',
        tags: ['ui', 'spin', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-spin'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-alert',
        name: '警告提示组件插件',
        category: 'other/ui_component',
        class_name: 'AlertComponentPlugin',
        description: '渲染警告提示组件，支持多种提示类型。',
        tags: ['ui', 'alert', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-alert'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-message',
        name: '消息提示组件插件',
        category: 'other/ui_component',
        class_name: 'MessageComponentPlugin',
        description: '渲染消息提示组件，支持全局消息提示。',
        tags: ['ui', 'message', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-message'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-notification',
        name: '通知提醒组件插件',
        category: 'other/ui_component',
        class_name: 'NotificationComponentPlugin',
        description: '渲染通知提醒组件，支持通知消息展示。',
        tags: ['ui', 'notification', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-notification'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-drawer',
        name: '抽屉组件插件',
        category: 'other/ui_component',
        class_name: 'DrawerComponentPlugin',
        description: '渲染抽屉组件，支持侧边栏展示。',
        tags: ['ui', 'drawer', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-drawer'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-popover',
        name: '气泡卡片组件插件',
        category: 'other/ui_component',
        class_name: 'PopoverComponentPlugin',
        description: '渲染气泡卡片组件，支持悬浮卡片展示。',
        tags: ['ui', 'popover', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-popover'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-popconfirm',
        name: '气泡确认组件插件',
        category: 'other/ui_component',
        class_name: 'PopconfirmComponentPlugin',
        description: '渲染气泡确认组件，支持确认操作。',
        tags: ['ui', 'popconfirm', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-popconfirm'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-anchor',
        name: '锚点组件插件',
        category: 'other/ui_component',
        class_name: 'AnchorComponentPlugin',
        description: '渲染锚点组件，支持页面锚点导航。',
        tags: ['ui', 'anchor', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-anchor'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-backtop',
        name: '回到顶部组件插件',
        category: 'other/ui_component',
        class_name: 'BacktopComponentPlugin',
        description: '渲染回到顶部组件，支持快速返回顶部。',
        tags: ['ui', 'backtop', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-backtop'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-affix',
        name: '固钉组件插件',
        category: 'other/ui_component',
        class_name: 'AffixComponentPlugin',
        description: '渲染固钉组件，支持元素固定定位。',
        tags: ['ui', 'affix', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-affix'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-watermark',
        name: '水印组件插件',
        category: 'other/ui_component',
        class_name: 'WatermarkComponentPlugin',
        description: '渲染水印组件，支持页面水印展示。',
        tags: ['ui', 'watermark', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-watermark'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-divider',
        name: '分割线组件插件',
        category: 'other/ui_component',
        class_name: 'DividerComponentPlugin',
        description: '渲染分割线组件，支持内容分割。',
        tags: ['ui', 'divider', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-divider'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-space',
        name: '间距组件插件',
        category: 'other/ui_component',
        class_name: 'SpaceComponentPlugin',
        description: '渲染间距组件，支持元素间距控制。',
        tags: ['ui', 'space', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-space'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-layout',
        name: '布局组件插件',
        category: 'other/ui_component',
        class_name: 'LayoutComponentPlugin',
        description: '渲染布局组件，支持页面布局。',
        tags: ['ui', 'layout', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-layout'></div>"
        RUBY
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-grid',
        name: '栅格组件插件',
        category: 'other/ui_component',
        class_name: 'GridComponentPlugin',
        description: '渲染栅格组件，支持响应式布局。',
        tags: ['ui', 'grid', 'component'],
        render_logic: <<~'RUBY'
          return "<div class='kr-grid'></div>"
        RUBY
      },
      # 新增UI组件插件
      {
        type: 'ui_component',
        plugin_id: 'ui-component-badge',
        name: '徽章组件插件',
        category: 'other/ui_component',
        class_name: 'BadgeComponentPlugin',
        description: '渲染徽章组件，用于显示数字、状态等。',
        tags: ['ui', 'badge', 'component']
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-tag',
        name: '标签组件插件',
        category: 'other/ui_component',
        class_name: 'TagComponentPlugin',
        description: '渲染标签组件，用于分类、标记等。',
        tags: ['ui', 'tag', 'component']
      },
      {
        type: 'ui_component',
        plugin_id: 'ui-component-avatar',
        name: '头像组件插件',
        category: 'other/ui_component',
        class_name: 'AvatarComponentPlugin',
        description: '渲染头像组件，支持图片、文字、图标。',
        tags: ['ui', 'avatar', 'component']
      }
    ]
  end
  
  # 生成操作钩子插件配置模板
  def self.create_hook_plugin_configs
    [
      {
        type: 'hook',
        plugin_id: 'hook-before-save',
        name: '保存前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeSaveHookPlugin',
        description: '在保存前进行数据校验与清洗。',
        tags: ['hook', 'before_save'],
        hook_logic: <<~'RUBY'
          # 示例：剔除临时字段
          data.delete('_tmp')
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-save',
        name: '保存后钩子插件',
        category: 'other/hook',
        class_name: 'AfterSaveHookPlugin',
        description: '在保存后进行通知或二次处理。',
        tags: ['hook', 'after_save'],
        hook_logic: <<~'RUBY'
          # 示例：追加保存时间
          data['_saved_at'] = Time.now
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-before-delete',
        name: '删除前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeDeleteHookPlugin',
        description: '删除前执行校验或转移。',
        tags: ['hook', 'before_delete'],
        hook_logic: <<~'RUBY'
          # 示例：策略性阻止
          if options[:protect]
            raise "受保护的数据不可删除"
          end
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-delete',
        name: '删除后钩子插件',
        category: 'other/hook',
        class_name: 'AfterDeleteHookPlugin',
        description: '删除后执行审计或外部通知。',
        tags: ['hook', 'after_delete'],
        hook_logic: <<~'RUBY'
          # 示例：打审计标记
          data['_deleted'] = true
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-before-query',
        name: '查询前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeQueryHookPlugin',
        description: '查询前进行权限检查或参数处理。',
        tags: ['hook', 'before_query'],
        hook_logic: <<~'RUBY'
          # 示例：添加默认查询条件
          params[:filters] ||= {}
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-query',
        name: '查询后钩子插件',
        category: 'other/hook',
        class_name: 'AfterQueryHookPlugin',
        description: '查询后进行数据转换或统计。',
        tags: ['hook', 'after_query'],
        hook_logic: <<~'RUBY'
          # 示例：添加统计信息
          result[:total_count] = result[:data].size
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-before-update',
        name: '更新前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeUpdateHookPlugin',
        description: '更新前进行数据校验或权限检查。',
        tags: ['hook', 'before_update'],
        hook_logic: <<~'RUBY'
          # 示例：记录更新时间
          data['_updated_at'] = Time.now
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-update',
        name: '更新后钩子插件',
        category: 'other/hook',
        class_name: 'AfterUpdateHookPlugin',
        description: '更新后执行通知或缓存刷新。',
        tags: ['hook', 'after_update'],
        hook_logic: <<~'RUBY'
          # 示例：清除缓存
          # Cache.clear(key)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-before-submit',
        name: '提交前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeSubmitHookPlugin',
        description: '提交前进行最终校验或数据准备。',
        tags: ['hook', 'before_submit'],
        hook_logic: <<~'RUBY'
          # 示例：设置提交状态
          data['status'] = 'submitted'
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-submit',
        name: '提交后钩子插件',
        category: 'other/hook',
        class_name: 'AfterSubmitHookPlugin',
        description: '提交后触发工作流或通知。',
        tags: ['hook', 'after_submit'],
        hook_logic: <<~'RUBY'
          # 示例：触发工作流
          # Workflow.trigger(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-error',
        name: '错误处理钩子插件',
        category: 'other/hook',
        class_name: 'OnErrorHookPlugin',
        description: '发生错误时执行错误处理和日志记录。',
        tags: ['hook', 'error', 'logging'],
        hook_logic: <<~'RUBY'
          # 示例：记录错误日志
          # Logger.error(error.message)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-success',
        name: '成功处理钩子插件',
        category: 'other/hook',
        class_name: 'OnSuccessHookPlugin',
        description: '操作成功时执行后续处理。',
        tags: ['hook', 'success'],
        hook_logic: <<~'RUBY'
          # 示例：发送成功通知
          # Notification.send_success(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-validate',
        name: '验证钩子插件',
        category: 'other/hook',
        class_name: 'ValidateHookPlugin',
        description: '自定义验证逻辑钩子。',
        tags: ['hook', 'validate'],
        hook_logic: <<~'RUBY'
          # 示例：自定义验证
          # raise "验证失败" unless valid?
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-transform',
        name: '数据转换钩子插件',
        category: 'other/hook',
        class_name: 'TransformHookPlugin',
        description: '数据转换和格式化钩子。',
        tags: ['hook', 'transform'],
        hook_logic: <<~'RUBY'
          # 示例：数据格式化
          # data = format_data(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-before-create',
        name: '创建前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeCreateHookPlugin',
        description: '创建记录前执行预处理。',
        tags: ['hook', 'before_create'],
        hook_logic: <<~'RUBY'
          # 示例：设置创建时间
          data['created_at'] = Time.now
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-create',
        name: '创建后钩子插件',
        category: 'other/hook',
        class_name: 'AfterCreateHookPlugin',
        description: '创建记录后执行后处理。',
        tags: ['hook', 'after_create'],
        hook_logic: <<~'RUBY'
          # 示例：发送创建通知
          # Notification.send_created(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-before-validate',
        name: '验证前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeValidateHookPlugin',
        description: '验证前进行数据预处理。',
        tags: ['hook', 'before_validate'],
        hook_logic: <<~'RUBY'
          # 示例：数据清洗
          # data = sanitize_data(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-validate',
        name: '验证后钩子插件',
        category: 'other/hook',
        class_name: 'AfterValidateHookPlugin',
        description: '验证后执行后续处理。',
        tags: ['hook', 'after_validate'],
        hook_logic: <<~'RUBY'
          # 示例：记录验证结果
          # Log.validation_result(data, result)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-change',
        name: '变更钩子插件',
        category: 'other/hook',
        class_name: 'OnChangeHookPlugin',
        description: '数据变更时触发处理。',
        tags: ['hook', 'on_change'],
        hook_logic: <<~'RUBY'
          # 示例：记录变更历史
          # History.record_change(data, changes)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-load',
        name: '加载钩子插件',
        category: 'other/hook',
        class_name: 'OnLoadHookPlugin',
        description: '数据加载时执行处理。',
        tags: ['hook', 'on_load'],
        hook_logic: <<~'RUBY'
          # 示例：数据转换
          # data = transform_on_load(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-render',
        name: '渲染钩子插件',
        category: 'other/hook',
        class_name: 'OnRenderHookPlugin',
        description: '数据渲染时执行处理。',
        tags: ['hook', 'on_render'],
        hook_logic: <<~'RUBY'
          # 示例：格式化显示
          # data = format_for_display(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-export',
        name: '导出钩子插件',
        category: 'other/hook',
        class_name: 'OnExportHookPlugin',
        description: '数据导出时执行处理。',
        tags: ['hook', 'on_export'],
        hook_logic: <<~'RUBY'
          # 示例：数据格式化
          # data = format_for_export(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-import',
        name: '导入钩子插件',
        category: 'other/hook',
        class_name: 'OnImportHookPlugin',
        description: '数据导入时执行处理。',
        tags: ['hook', 'on_import'],
        hook_logic: <<~'RUBY'
          # 示例：数据验证和清洗
          # data = validate_and_clean(data)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-cache',
        name: '缓存钩子插件',
        category: 'other/hook',
        class_name: 'OnCacheHookPlugin',
        description: '缓存操作时执行处理。',
        tags: ['hook', 'on_cache'],
        hook_logic: <<~'RUBY'
          # 示例：缓存失效处理
          # Cache.invalidate(key)
        RUBY
      },
      {
        type: 'hook',
        plugin_id: 'hook-on-sync',
        name: '同步钩子插件',
        category: 'other/hook',
        class_name: 'OnSyncHookPlugin',
        description: '数据同步时执行处理。',
        tags: ['hook', 'on_sync'],
        hook_logic: <<~'RUBY'
          # 示例：同步到外部系统
          # ExternalSystem.sync(data)
        RUBY
      },
      # 新增操作钩子插件
      {
        type: 'hook',
        plugin_id: 'hook-before-update',
        name: '更新前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeUpdateHookPlugin',
        description: '数据更新前执行处理，可用于数据校验、转换等。',
        tags: ['hook', 'before_update', 'validation']
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-update',
        name: '更新后钩子插件',
        category: 'other/hook',
        class_name: 'AfterUpdateHookPlugin',
        description: '数据更新后执行处理，可用于日志记录、通知等。',
        tags: ['hook', 'after_update', 'notification']
      },
      {
        type: 'hook',
        plugin_id: 'hook-before-delete',
        name: '删除前钩子插件',
        category: 'other/hook',
        class_name: 'BeforeDeleteHookPlugin',
        description: '数据删除前执行处理，可用于权限检查、依赖检查等。',
        tags: ['hook', 'before_delete', 'validation']
      },
      {
        type: 'hook',
        plugin_id: 'hook-after-delete',
        name: '删除后钩子插件',
        category: 'other/hook',
        class_name: 'AfterDeleteHookPlugin',
        description: '数据删除后执行处理，可用于清理关联数据、记录日志等。',
        tags: ['hook', 'after_delete', 'cleanup']
      }
    ]
  end
  
  # 生成AI Prompt插件配置模板
  def self.create_ai_prompt_plugin_configs
    [
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-field-translation',
        name: '字段翻译插件',
        category: 'other/ai_prompt',
        class_name: 'FieldTranslationPlugin',
        description: '按配置对字段值进行多语言翻译。',
        tags: ['ai', 'prompt', 'translation'],
        ai_logic: <<~'RUBY'
          # 这里可对接 PromptTemplateService + LLMService
          return { success: true, output: "[translated] #{input}" }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-form-generation',
        name: '表单生成插件',
        category: 'other/ai_prompt',
        class_name: 'FormGenerationPlugin',
        description: '根据自然语言生成表单schema。',
        tags: ['ai', 'prompt', 'form'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { schema: { title: input, fields: [] } } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-code-generation',
        name: '代码生成插件',
        category: 'other/ai_prompt',
        class_name: 'CodeGenerationPlugin',
        description: '根据需求生成代码片段或模板。',
        tags: ['ai', 'prompt', 'code'],
        ai_logic: <<~'RUBY'
          return { success: true, output: "def hello; puts 'hello' end" }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-field-description',
        name: '字段描述生成插件',
        category: 'other/ai_prompt',
        class_name: 'FieldDescriptionPlugin',
        description: '根据字段名和类型自动生成字段描述。',
        tags: ['ai', 'prompt', 'field', 'description'],
        ai_logic: <<~'RUBY'
          return { success: true, output: "字段描述" }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-validation-rule',
        name: '验证规则生成插件',
        category: 'other/ai_prompt',
        class_name: 'ValidationRulePlugin',
        description: '根据字段类型和业务需求生成验证规则。',
        tags: ['ai', 'prompt', 'validation', 'rule'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { rules: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-api-doc',
        name: 'API文档生成插件',
        category: 'other/ai_prompt',
        class_name: 'ApiDocPlugin',
        description: '根据代码自动生成API文档。',
        tags: ['ai', 'prompt', 'api', 'doc'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { doc: "" } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-test-case',
        name: '测试用例生成插件',
        category: 'other/ai_prompt',
        class_name: 'TestCasePlugin',
        description: '根据功能描述自动生成测试用例。',
        tags: ['ai', 'prompt', 'test', 'case'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { cases: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-data-analysis',
        name: '数据分析插件',
        category: 'other/ai_prompt',
        class_name: 'DataAnalysisPlugin',
        description: '分析数据并生成分析报告。',
        tags: ['ai', 'prompt', 'analysis', 'data'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { analysis: "" } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-content-summary',
        name: '内容摘要插件',
        category: 'other/ai_prompt',
        class_name: 'ContentSummaryPlugin',
        description: '生成内容摘要和关键词提取。',
        tags: ['ai', 'prompt', 'summary', 'content'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { summary: "", keywords: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-query-optimization',
        name: '查询优化插件',
        category: 'other/ai_prompt',
        class_name: 'QueryOptimizationPlugin',
        description: '优化查询语句，提高查询效率。',
        tags: ['ai', 'prompt', 'query', 'optimization'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { optimized_query: "" } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-error-analysis',
        name: '错误分析插件',
        category: 'other/ai_prompt',
        class_name: 'ErrorAnalysisPlugin',
        description: '分析错误信息并提供解决方案。',
        tags: ['ai', 'prompt', 'error', 'analysis'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { analysis: "", solution: "" } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-code-review',
        name: '代码审查插件',
        category: 'other/ai_prompt',
        class_name: 'CodeReviewPlugin',
        description: '审查代码并提供改进建议。',
        tags: ['ai', 'prompt', 'code', 'review'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { review: "", suggestions: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-performance-analysis',
        name: '性能分析插件',
        category: 'other/ai_prompt',
        class_name: 'PerformanceAnalysisPlugin',
        description: '分析性能问题并提供优化建议。',
        tags: ['ai', 'prompt', 'performance', 'analysis'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { analysis: "", recommendations: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-security-audit',
        name: '安全审计插件',
        category: 'other/ai_prompt',
        class_name: 'SecurityAuditPlugin',
        description: '进行安全审计并识别潜在风险。',
        tags: ['ai', 'prompt', 'security', 'audit'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { risks: [], recommendations: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-documentation-generation',
        name: '文档生成插件',
        category: 'other/ai_prompt',
        class_name: 'DocumentationGenerationPlugin',
        description: '根据代码自动生成技术文档。',
        tags: ['ai', 'prompt', 'documentation', 'generation'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { documentation: "" } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-requirement-analysis',
        name: '需求分析插件',
        category: 'other/ai_prompt',
        class_name: 'RequirementAnalysisPlugin',
        description: '分析需求并生成功能规格说明。',
        tags: ['ai', 'prompt', 'requirement', 'analysis'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { specification: "", features: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-database-design',
        name: '数据库设计插件',
        category: 'other/ai_prompt',
        class_name: 'DatabaseDesignPlugin',
        description: '根据需求生成数据库设计方案。',
        tags: ['ai', 'prompt', 'database', 'design'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { schema: {}, tables: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-api-design',
        name: 'API设计插件',
        category: 'other/ai_prompt',
        class_name: 'ApiDesignPlugin',
        description: '根据需求生成API设计方案。',
        tags: ['ai', 'prompt', 'api', 'design'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { endpoints: [], schemas: {} } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-ui-design',
        name: 'UI设计插件',
        category: 'other/ai_prompt',
        class_name: 'UiDesignPlugin',
        description: '根据需求生成UI设计方案。',
        tags: ['ai', 'prompt', 'ui', 'design'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { layout: {}, components: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-test-plan',
        name: '测试计划生成插件',
        category: 'other/ai_prompt',
        class_name: 'TestPlanPlugin',
        description: '根据功能需求生成测试计划。',
        tags: ['ai', 'prompt', 'test', 'plan'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { plan: "", cases: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-deployment-plan',
        name: '部署计划生成插件',
        category: 'other/ai_prompt',
        class_name: 'DeploymentPlanPlugin',
        description: '生成系统部署计划。',
        tags: ['ai', 'prompt', 'deployment', 'plan'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { plan: "", steps: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-troubleshooting',
        name: '故障排查插件',
        category: 'other/ai_prompt',
        class_name: 'TroubleshootingPlugin',
        description: '根据错误信息提供故障排查建议。',
        tags: ['ai', 'prompt', 'troubleshooting', 'debug'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { diagnosis: "", steps: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-code-refactor',
        name: '代码重构插件',
        category: 'other/ai_prompt',
        class_name: 'CodeRefactorPlugin',
        description: '提供代码重构建议和方案。',
        tags: ['ai', 'prompt', 'code', 'refactor'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { refactored_code: "", suggestions: [] } }
        RUBY
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-config-generation',
        name: '配置生成插件',
        category: 'other/ai_prompt',
        class_name: 'ConfigGenerationPlugin',
        description: '根据需求生成配置文件。',
        tags: ['ai', 'prompt', 'config', 'generation'],
        ai_logic: <<~'RUBY'
          return { success: true, output: { config: {} } }
        RUBY
      },
      # 新增AI Prompt插件
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-data-migration',
        name: '数据迁移插件',
        category: 'other/ai_prompt',
        class_name: 'DataMigrationPlugin',
        description: '生成数据迁移脚本和方案。',
        tags: ['ai', 'prompt', 'migration', 'data']
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-api-integration',
        name: 'API集成插件',
        category: 'other/ai_prompt',
        class_name: 'ApiIntegrationPlugin',
        description: '生成API集成代码和配置。',
        tags: ['ai', 'prompt', 'api', 'integration']
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-data-modeling',
        name: '数据建模插件',
        category: 'other/ai_prompt',
        class_name: 'DataModelingPlugin',
        description: '根据业务需求生成数据模型设计。',
        tags: ['ai', 'prompt', 'data_modeling', 'design']
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-workflow-design',
        name: '工作流设计插件',
        category: 'other/ai_prompt',
        class_name: 'WorkflowDesignPlugin',
        description: '根据业务需求生成工作流设计。',
        tags: ['ai', 'prompt', 'workflow', 'design']
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-report-generation',
        name: '报表生成插件',
        category: 'other/ai_prompt',
        class_name: 'ReportGenerationPlugin',
        description: '根据需求生成报表配置和查询。',
        tags: ['ai', 'prompt', 'report', 'generation']
      },
      {
        type: 'ai_prompt',
        plugin_id: 'ai-prompt-dashboard-design',
        name: '仪表盘设计插件',
        category: 'other/ai_prompt',
        class_name: 'DashboardDesignPlugin',
        description: '根据需求生成仪表盘设计。',
        tags: ['ai', 'prompt', 'dashboard', 'design']
      }
    ]
  end
  
  # 生成数据源插件配置模板
  def self.create_data_source_plugin_configs
    [
      {
        type: 'data_source',
        plugin_id: 'data-source-mongodb',
        name: 'MongoDB数据源插件',
        category: 'data_source',
        class_name: 'MongodbDataSourcePlugin',
        description: 'MongoDB数据源插件，支持MongoDB数据库连接和查询。',
        tags: ['data_source', 'mongodb', 'database']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-mysql',
        name: 'MySQL数据源插件',
        category: 'data_source',
        class_name: 'MysqlDataSourcePlugin',
        description: 'MySQL数据源插件，支持MySQL数据库连接和查询。',
        tags: ['data_source', 'mysql', 'database']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-postgresql',
        name: 'PostgreSQL数据源插件',
        category: 'data_source',
        class_name: 'PostgresqlDataSourcePlugin',
        description: 'PostgreSQL数据源插件，支持PostgreSQL数据库连接和查询。',
        tags: ['data_source', 'postgresql', 'database']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-redis',
        name: 'Redis数据源插件',
        category: 'data_source',
        class_name: 'RedisDataSourcePlugin',
        description: 'Redis数据源插件，支持Redis缓存连接和操作。',
        tags: ['data_source', 'redis', 'cache']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-api',
        name: 'API数据源插件',
        category: 'data_source',
        class_name: 'ApiDataSourcePlugin',
        description: 'API数据源插件，支持通过HTTP/HTTPS接口获取数据。',
        tags: ['data_source', 'api', 'http']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-elasticsearch',
        name: 'Elasticsearch数据源插件',
        category: 'data_source',
        class_name: 'ElasticsearchDataSourcePlugin',
        description: 'Elasticsearch数据源插件，支持Elasticsearch搜索和查询。',
        tags: ['data_source', 'elasticsearch', 'search']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-file',
        name: '文件数据源插件',
        category: 'data_source',
        class_name: 'FileDataSourcePlugin',
        description: '文件数据源插件，支持从文件系统读取数据。',
        tags: ['data_source', 'file', 'filesystem']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-csv',
        name: 'CSV数据源插件',
        category: 'data_source',
        class_name: 'CsvDataSourcePlugin',
        description: 'CSV数据源插件，支持CSV文件读取和解析。',
        tags: ['data_source', 'csv', 'file']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-excel',
        name: 'Excel数据源插件',
        category: 'data_source',
        class_name: 'ExcelDataSourcePlugin',
        description: 'Excel数据源插件，支持Excel文件读取和解析。',
        tags: ['data_source', 'excel', 'file']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-json',
        name: 'JSON数据源插件',
        category: 'data_source',
        class_name: 'JsonDataSourcePlugin',
        description: 'JSON数据源插件，支持JSON文件读取和解析。',
        tags: ['data_source', 'json', 'file']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-xml',
        name: 'XML数据源插件',
        category: 'data_source',
        class_name: 'XmlDataSourcePlugin',
        description: 'XML数据源插件，支持XML文件读取和解析。',
        tags: ['data_source', 'xml', 'file']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-rest',
        name: 'REST API数据源插件',
        category: 'data_source',
        class_name: 'RestDataSourcePlugin',
        description: 'REST API数据源插件，支持RESTful接口数据获取。',
        tags: ['data_source', 'rest', 'api']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-graphql',
        name: 'GraphQL数据源插件',
        category: 'data_source',
        class_name: 'GraphqlDataSourcePlugin',
        description: 'GraphQL数据源插件，支持GraphQL查询。',
        tags: ['data_source', 'graphql', 'api']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-websocket',
        name: 'WebSocket数据源插件',
        category: 'data_source',
        class_name: 'WebsocketDataSourcePlugin',
        description: 'WebSocket数据源插件，支持实时数据推送。',
        tags: ['data_source', 'websocket', 'realtime']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-sftp',
        name: 'SFTP数据源插件',
        category: 'data_source',
        class_name: 'SftpDataSourcePlugin',
        description: 'SFTP数据源插件，支持SFTP文件传输。',
        tags: ['data_source', 'sftp', 'file']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-ftp',
        name: 'FTP数据源插件',
        category: 'data_source',
        class_name: 'FtpDataSourcePlugin',
        description: 'FTP数据源插件，支持FTP文件传输。',
        tags: ['data_source', 'ftp', 'file']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-s3',
        name: 'S3数据源插件',
        category: 'data_source',
        class_name: 'S3DataSourcePlugin',
        description: 'S3数据源插件，支持AWS S3对象存储。',
        tags: ['data_source', 's3', 'storage']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-oss',
        name: 'OSS数据源插件',
        category: 'data_source',
        class_name: 'OssDataSourcePlugin',
        description: 'OSS数据源插件，支持阿里云OSS对象存储。',
        tags: ['data_source', 'oss', 'storage']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-kafka',
        name: 'Kafka数据源插件',
        category: 'data_source',
        class_name: 'KafkaDataSourcePlugin',
        description: 'Kafka数据源插件，支持Kafka消息队列。',
        tags: ['data_source', 'kafka', 'message_queue']
      },
      {
        type: 'data_source',
        plugin_id: 'data-source-rabbitmq',
        name: 'RabbitMQ数据源插件',
        category: 'data_source',
        class_name: 'RabbitmqDataSourcePlugin',
        description: 'RabbitMQ数据源插件，支持RabbitMQ消息队列。',
        tags: ['data_source', 'rabbitmq', 'message_queue']
      }
    ]
  end
  
  private
  
  def generate_metadata(plugin_configs, code_results)
    successful_plugins = code_results.select { |r| r[:success] }
    
    successful_plugins.map do |result|
      config = plugin_configs.find { |c| c[:plugin_id] == result[:plugin_id] }
      next unless config
      
      # 读取生成的代码文件
      code = File.read(result[:output_path])
      
      # 生成元数据
      {
        plugin_id: config[:plugin_id],
        name: config[:name] || config[:class_name],
        category: config[:category],
        version: config[:version] || '1.0.0',
        author: config[:author] || 'kr_new_gen_team',
        description: config[:description] || generate_description(config),
        tags: config[:tags] || [],
        is_builtin: true,
        files: [{
          path: result[:output_path].gsub(File.join(Dir.pwd, ''), ''),
          is_builtin: true,
          content: code
        }],
        config_schema: config[:config_schema] || {},
        install_config: generate_install_config(config),
        examples: config[:examples] || []
      }
    end.compact
  end
  
  def generate_description(config)
    case config[:type]
    when 'strategy'
      "#{config[:action]}策略，上下文：#{config[:context]}"
    when 'field_type'
      "#{config[:field_type_name]}字段类型"
    else
      config[:class_name]
    end
  end
  
  def generate_install_config(config)
    return {} unless config[:type] == 'strategy'
    
    {
      strategy_yaml: {
        add: [{
          domain: config[:domain],
          action: config[:action],
          context: config[:context],
          class: "Plugins::Strategy::#{config[:category_module]}::#{config[:class_name]}"
        }]
      }
    }
  end
end

