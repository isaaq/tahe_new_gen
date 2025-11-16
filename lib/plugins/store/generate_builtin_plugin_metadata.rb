# frozen_string_literal: true

require_relative '../../util/common'
require_relative 'plugin_store'

# 为内置插件生成完整元数据的脚本
class GenerateBuiltinPluginMetadata
  def self.generate_all!
    # 定义所有内置插件的完整元数据
    plugins_metadata = [
      {
        plugin_id: 'strategy-save-draft',
        name: '草稿保存策略',
        category: 'strategy/save',
        version: '1.0.0',
        author: 'kr_new_gen_team',
        description: '支持保存草稿数据，自动添加草稿标记和时间戳。适用于需要临时保存、后续编辑的场景。',
        tags: ['save', 'draft', 'document', 'temporary'],
        is_builtin: true,
        files: [
          {
            path: 'lib/plugins/strategy/save/draft_save_strategy.rb',
            is_builtin: true
          }
        ],
        config_schema: {
          fields: [
            {
              name: 'collection',
              type: 'string',
              default: 'drafts',
              description: '草稿存储集合名',
              required: false
            }
          ]
        },
        install_config: {
          strategy_yaml: {
            add: [
              {
                domain: 'document',
                action: 'save',
                context: 'draft',
                class: 'Plugins::Strategy::Save::DraftSaveStrategy'
              }
            ]
          }
        },
        examples: [
          {
            title: '基本使用',
            code: "strategy = Strategy.resolve(\n  domain: 'document',\n  action: 'save',\n  context: 'draft'\n)\nresult = strategy.execute(data: { title: '草稿标题', content: '草稿内容' })"
          }
        ]
      },
      {
        plugin_id: 'strategy-save-normal',
        name: '正式保存策略',
        category: 'strategy/save',
        version: '1.0.0',
        author: 'kr_new_gen_team',
        description: '支持正式保存数据，支持新增和更新操作。自动添加更新时间戳。',
        tags: ['save', 'normal', 'document', 'create', 'update'],
        is_builtin: true,
        files: [
          {
            path: 'lib/plugins/strategy/save/normal_save_strategy.rb',
            is_builtin: true
          }
        ],
        config_schema: {
          fields: [
            {
              name: 'collection',
              type: 'string',
              default: 'documents',
              description: '文档存储集合名',
              required: false
            }
          ]
        },
        install_config: {
          strategy_yaml: {
            add: [
              {
                domain: 'document',
                action: 'save',
                context: 'normal',
                class: 'Plugins::Strategy::Save::NormalSaveStrategy'
              }
            ]
          }
        },
        examples: [
          {
            title: '基本使用',
            code: "strategy = Strategy.resolve(\n  domain: 'document',\n  action: 'save',\n  context: 'normal'\n)\nresult = strategy.execute(data: { title: '文档标题', content: '文档内容' })"
          }
        ]
      },
      {
        plugin_id: 'strategy-submit-publish',
        name: '发布策略',
        category: 'strategy/submit',
        version: '1.0.0',
        author: 'kr_new_gen_team',
        description: '将文档状态更新为已发布，添加发布时间戳。适用于内容发布流程。',
        tags: ['submit', 'publish', 'document', 'workflow'],
        is_builtin: true,
        files: [
          {
            path: 'lib/plugins/strategy/submit/publish_strategy.rb',
            is_builtin: true
          }
        ],
        config_schema: {
          fields: [
            {
              name: 'collection',
              type: 'string',
              default: 'documents',
              description: '文档集合名',
              required: false
            }
          ]
        },
        install_config: {
          strategy_yaml: {
            add: [
              {
                domain: 'document',
                action: 'submit',
                context: 'publish',
                class: 'Plugins::Strategy::Submit::PublishStrategy'
              }
            ]
          }
        },
        examples: [
          {
            title: '发布文档',
            code: "strategy = Strategy.resolve(\n  domain: 'document',\n  action: 'submit',\n  context: 'publish'\n)\nresult = strategy.execute(document_id: '507f1f77bcf86cd799439011')"
          }
        ]
      },
      {
        plugin_id: 'strategy-submit-draft',
        name: '草稿提交策略',
        category: 'strategy/submit',
        version: '1.0.0',
        author: 'kr_new_gen_team',
        description: '将草稿提交并转为正式文档，从草稿集合移动到正式集合。',
        tags: ['submit', 'draft', 'document', 'workflow'],
        is_builtin: true,
        files: [
          {
            path: 'lib/plugins/strategy/submit/draft_strategy.rb',
            is_builtin: true
          }
        ],
        config_schema: {
          fields: [
            {
              name: 'draft_collection',
              type: 'string',
              default: 'drafts',
              description: '草稿集合名',
              required: false
            },
            {
              name: 'target_collection',
              type: 'string',
              default: 'documents',
              description: '目标集合名',
              required: false
            }
          ]
        },
        install_config: {
          strategy_yaml: {
            add: [
              {
                domain: 'document',
                action: 'submit',
                context: 'draft',
                class: 'Plugins::Strategy::Submit::DraftStrategy'
              }
            ]
          }
        },
        examples: [
          {
            title: '提交草稿',
            code: "strategy = Strategy.resolve(\n  domain: 'document',\n  action: 'submit',\n  context: 'draft'\n)\nresult = strategy.execute(draft_id: '507f1f77bcf86cd799439011')"
          }
        ]
      },
      {
        plugin_id: 'strategy-permission-default',
        name: '默认权限策略',
        category: 'strategy/permission',
        version: '1.0.0',
        author: 'kr_new_gen_team',
        description: '默认的权限过滤策略，支持基于角色、部门、用户组、公开访问等多种权限控制。',
        tags: ['permission', 'filter', 'security', 'access-control'],
        is_builtin: true,
        files: [
          {
            path: 'lib/plugins/strategy/permission/default_permission_strategy.rb',
            is_builtin: true
          }
        ],
        config_schema: {
          fields: []
        },
        install_config: {
          strategy_yaml: {
            add: [
              {
                domain: 'permission',
                action: 'filter',
                context: 'default',
                class: 'Plugins::Strategy::Permission::DefaultPermissionStrategy'
              }
            ]
          }
        },
        examples: [
          {
            title: '权限检查',
            code: "strategy = Strategy.resolve(\n  domain: 'permission',\n  action: 'filter',\n  context: 'default'\n)\nhas_access = strategy.execute(\n  user: { _id: 'user123', role: 'user', department_id: 'dept1' },\n  meta: { created_by: 'user123', access_rules: { public: true } }\n)"
          }
        ]
      },
      {
        plugin_id: 'strategy-field-number-range',
        name: '数值范围字段处理器',
        category: 'strategy/field',
        version: '1.0.0',
        author: 'kr_new_gen_team',
        description: '处理数值范围类型的字段，支持最小值、最大值的验证和转换。',
        tags: ['field', 'number', 'range', 'validation'],
        is_builtin: true,
        files: [
          {
            path: 'lib/plugins/strategy/field/number_range_field_processor.rb',
            is_builtin: true
          }
        ],
        config_schema: {
          fields: []
        },
        install_config: {
          strategy_yaml: {
            add: [
              {
                domain: 'field',
                action: 'process',
                context: 'number_range',
                class: 'Plugins::Strategy::Field::NumberRangeFieldProcessor'
              }
            ]
          }
        },
        examples: [
          {
            title: '处理数值范围',
            code: "strategy = Strategy.resolve(\n  domain: 'field',\n  action: 'process',\n  context: 'number_range'\n)\nresult = strategy.execute(\n  value: { min: 10, max: 100 },\n  meta: {}\n)"
          }
        ]
      }
    ]
    
    # 读取文件内容并添加到元数据中
    plugins_metadata.each do |plugin_meta|
      plugin_meta[:files].each do |file_info|
        # 构建绝对路径
        base_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
        file_path = File.join(base_dir, file_info[:path])
        if File.exist?(file_path)
          file_info[:content] = File.read(file_path)
        else
          puts "警告: 文件不存在: #{file_path}" if dev?
        end
      end
      
      # 注册到商店（如果不存在则添加，存在则更新）
      if defined?(Common) && defined?(Common::M)
        existing = Common::M[PluginStore::STORE_COLLECTION].query(plugin_id: plugin_meta[:plugin_id]).first
        if existing
          Common::M[PluginStore::STORE_COLLECTION].update(
            { plugin_id: plugin_meta[:plugin_id] },
            plugin_meta
          )
          puts "已更新插件元数据: #{plugin_meta[:plugin_id]}" if dev?
        else
          Common::M[PluginStore::STORE_COLLECTION].add(plugin_meta)
          puts "已添加插件元数据: #{plugin_meta[:plugin_id]}" if dev?
        end
      else
        puts "警告: MongoDB未初始化，无法保存插件元数据" if dev?
      end
    end
    
    puts "✅ 已完成 #{plugins_metadata.size} 个内置插件的元数据生成" if dev?
    plugins_metadata
  end
  
  def self.dev?
    ENV['RACK_ENV'] != 'production'
  end
end

