# frozen_string_literal: true

require_relative 'batch_plugin_generator'
require_relative 'auto_metadata_generator'
require_relative 'plugin_test_generator'
require_relative 'plugin_doc_generator'
require_relative 'plugin_store'

# 主生成脚本：批量生成插件、元数据、测试和文档
class GeneratePlugins
  def self.run!
    generator = BatchPluginGenerator.new
    metadata_gen = AutoMetadataGenerator.new
    test_gen = PluginTestGenerator.new
    doc_gen = PluginDocGenerator.new
    
    puts "=" * 80
    puts "开始批量生成插件"
    puts "=" * 80
    puts
    
    # 1. 生成策略插件
    puts "步骤1: 生成策略插件..."
    strategy_configs = BatchPluginGenerator.create_strategy_plugin_configs
    strategy_results = generator.generate_plugins(strategy_configs)
    success_count = strategy_results[:code_generation].count { |r| r[:success] }
    puts "✅ 生成了 #{success_count}/#{strategy_configs.size} 个策略插件"
    if success_count < strategy_configs.size
      puts "⚠️  失败的插件："
      strategy_results[:code_generation].each do |r|
        puts "  - #{r[:plugin_id]}: #{r[:error]}" unless r[:success]
      end
    end
    puts
    
    # 2. 生成字段类型插件
    puts "步骤2: 生成字段类型插件..."
    field_type_configs = BatchPluginGenerator.create_field_type_plugin_configs
    field_type_results = generator.generate_plugins(field_type_configs)
    success_count = field_type_results[:code_generation].count { |r| r[:success] }
    puts "✅ 生成了 #{success_count}/#{field_type_configs.size} 个字段类型插件"
    if success_count < field_type_configs.size
      puts "⚠️  失败的插件："
      field_type_results[:code_generation].each do |r|
        puts "  - #{r[:plugin_id]}: #{r[:error]}" unless r[:success]
      end
    end
    puts
    
    # 3. 生成表单行为插件
    puts "步骤3: 生成表单行为插件..."
    form_behavior_configs = BatchPluginGenerator.create_form_behavior_plugin_configs
    form_behavior_results = generator.generate_plugins(form_behavior_configs)
    success_count = form_behavior_results[:code_generation].count { |r| r[:success] }
    puts "✅ 生成了 #{success_count}/#{form_behavior_configs.size} 个表单行为插件"
    if success_count < form_behavior_configs.size
      puts "⚠️  失败的插件："
      form_behavior_results[:code_generation].each do |r|
        puts "  - #{r[:plugin_id]}: #{r[:error]}" unless r[:success]
      end
    end
    puts
    
    # 4. 生成UI组件插件
    puts "步骤4: 生成UI组件插件..."
    ui_component_configs = BatchPluginGenerator.create_ui_component_plugin_configs
    ui_component_results = generator.generate_plugins(ui_component_configs)
    success_count = ui_component_results[:code_generation].count { |r| r[:success] }
    puts "✅ 生成了 #{success_count}/#{ui_component_configs.size} 个UI组件插件"
    if success_count < ui_component_configs.size
      puts "⚠️  失败的插件："
      ui_component_results[:code_generation].each do |r|
        puts "  - #{r[:plugin_id]}: #{r[:error]}" unless r[:success]
      end
    end
    puts
    
    # 5. 生成操作钩子插件
    puts "步骤5: 生成操作钩子插件..."
    hook_configs = BatchPluginGenerator.create_hook_plugin_configs
    hook_results = generator.generate_plugins(hook_configs)
    success_count = hook_results[:code_generation].count { |r| r[:success] }
    puts "✅ 生成了 #{success_count}/#{hook_configs.size} 个操作钩子插件"
    if success_count < hook_configs.size
      puts "⚠️  失败的插件："
      hook_results[:code_generation].each do |r|
        puts "  - #{r[:plugin_id]}: #{r[:error]}" unless r[:success]
      end
    end
    puts
    
    # 6. 生成AI Prompt插件
    puts "步骤6: 生成AI Prompt插件..."
    ai_prompt_configs = BatchPluginGenerator.create_ai_prompt_plugin_configs
    ai_prompt_results = generator.generate_plugins(ai_prompt_configs)
    success_count = ai_prompt_results[:code_generation].count { |r| r[:success] }
    puts "✅ 生成了 #{success_count}/#{ai_prompt_configs.size} 个AI Prompt插件"
    if success_count < ai_prompt_configs.size
      puts "⚠️  失败的插件："
      ai_prompt_results[:code_generation].each do |r|
        puts "  - #{r[:plugin_id]}: #{r[:error]}" unless r[:success]
      end
    end
    puts
    
    # 7. 生成数据源插件
    puts "步骤7: 生成数据源插件..."
    data_source_configs = BatchPluginGenerator.create_data_source_plugin_configs
    data_source_results = generator.generate_plugins(data_source_configs)
    success_count = data_source_results[:code_generation].count { |r| r[:success] }
    puts "✅ 生成了 #{success_count}/#{data_source_configs.size} 个数据源插件"
    if success_count < data_source_configs.size
      puts "⚠️  失败的插件："
      data_source_results[:code_generation].each do |r|
        puts "  - #{r[:plugin_id]}: #{r[:error]}" unless r[:success]
      end
    end
    puts
    
    # 8. 生成插件元数据并注册到商店
    puts "步骤8: 生成插件元数据并注册到商店..."
    store = PluginStore.instance
    
    all_configs = strategy_configs + field_type_configs + form_behavior_configs + ui_component_configs + hook_configs + ai_prompt_configs + data_source_configs
    metadata_count = 0
    
    all_configs.each do |config|
      begin
        # 读取生成的代码文件
        output_path = determine_output_path(config)
        next unless File.exist?(output_path)
        
        code = File.read(output_path, encoding: 'UTF-8')
        
        # 生成元数据
        metadata = {
          plugin_id: config[:plugin_id],
          name: config[:name] || config[:class_name],
          category: config[:category],
          version: config[:version] || '1.0.0',
          author: config[:author] || 'kr_new_gen_team',
          description: config[:description] || generate_description(config),
          tags: config[:tags] || [],
          is_builtin: true,
          files: [{
            path: output_path.gsub(File.join(Dir.pwd, '') + '/', ''),
            is_builtin: true,
            content: code
          }],
          config_schema: config[:config_schema] || {},
          install_config: generate_install_config(config),
          examples: config[:examples] || []
        }
        
        # 注册到商店
        if defined?(Common) && defined?(Common::M)
          existing = Common::M[PluginStore::STORE_COLLECTION].query(plugin_id: metadata[:plugin_id]).first
          if existing
            Common::M[PluginStore::STORE_COLLECTION].update(
              { plugin_id: metadata[:plugin_id] },
              metadata
            )
          else
            Common::M[PluginStore::STORE_COLLECTION].add(metadata)
          end
          metadata_count += 1
        end
      rescue => e
        puts "⚠️  生成元数据失败 #{config[:plugin_id]}: #{e.message}" if ENV['RACK_ENV'] != 'production'
      end
    end
    
    puts "✅ 已生成并注册 #{metadata_count} 个插件的元数据"
    puts
    
    # 9. 生成测试用例
    puts "步骤9: 生成测试用例..."
    all_configs = strategy_configs + field_type_configs + form_behavior_configs + ui_component_configs + hook_configs + ai_prompt_configs + data_source_configs
    test_dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'test', 'plugins')
    FileUtils.mkdir_p(test_dir)
    
    all_configs.each do |config|
      test_code = test_gen.generate_test(config)
      test_file = File.join(test_dir, "test_#{underscore(config[:class_name])}.rb")
      File.write(test_file, test_code)
    end
    puts "✅ 生成了 #{all_configs.size} 个测试文件"
    puts
    
    # 10. 生成文档
    puts "步骤10: 生成插件文档..."
    doc_dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'docs', 'plugins')
    FileUtils.mkdir_p(doc_dir)
    
    all_configs.each do |config|
      metadata = {
        plugin_id: config[:plugin_id],
        name: config[:name] || config[:class_name],
        category: config[:category],
        type: config[:type],
        class_name: config[:class_name],
        domain: config[:domain],
        action: config[:action],
        context: config[:context],
        field_type_name: config[:field_type_name],
        description: config[:description],
        config_schema: config[:config_schema] || {},
        examples: config[:examples] || []
      }
      
      doc_content = doc_gen.generate_doc(metadata)
      doc_file = File.join(doc_dir, "#{config[:plugin_id]}.md")
      File.write(doc_file, doc_content)
    end
    puts "✅ 生成了 #{all_configs.size} 个文档文件"
    puts
    
    puts "=" * 80
    puts "插件生成完成！"
    puts "=" * 80
    puts
    puts "统计："
    puts "  - 策略插件: #{strategy_configs.size} 个"
    puts "  - 字段类型插件: #{field_type_configs.size} 个"
    puts "  - 表单行为插件: #{form_behavior_configs.size} 个"
    puts "  - UI组件插件: #{ui_component_configs.size} 个"
    puts "  - 操作钩子插件: #{hook_configs.size} 个"
    puts "  - AI Prompt插件: #{ai_prompt_configs.size} 个"
    puts "  - 数据源插件: #{data_source_configs.size} 个"
    puts "  - 测试文件: #{all_configs.size} 个"
    puts "  - 文档文件: #{all_configs.size} 个"
  end
  
  def self.underscore(str)
    str.gsub(/::/, '/')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .tr('-', '_')
       .downcase
  end
  
  def self.determine_output_path(config)
    base_dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'plugins')
    category_path = config[:category].gsub('_', '/')
    file_name = underscore(config[:class_name]) + '.rb'
    File.join(base_dir, category_path, file_name)
  end
  
  def self.generate_description(config)
    case config[:type]
    when 'strategy'
      "#{config[:action]}策略，上下文：#{config[:context]}"
    when 'field_type'
      "#{config[:field_type_name]}字段类型"
    else
      config[:class_name]
    end
  end
  
  def self.generate_install_config(config)
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

# 如果直接运行此脚本
if __FILE__ == $0
  require 'fileutils'
  GeneratePlugins.run!
end

