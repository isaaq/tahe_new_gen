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

