# frozen_string_literal: true

require_relative '../lib/plugins/store/plugin_generator'
require_relative '../lib/plugins/store/batch_plugin_generator'

def test_plugin_generator
  puts "\n" + "="*80
  puts "插件生成器测试"
  puts "="*80
  puts
  
  generator = PluginGenerator.new
  
  # 测试1: 生成策略插件
  puts "测试1: 生成策略插件"
  puts "-" * 40
  begin
    config = {
      type: 'strategy',
      category: 'strategy/save',
      category_module: 'Save',
      class_name: 'ReviewSaveStrategy',
      domain: 'document',
      action: 'save',
      context: 'review',
      required_params: ['data'],
      collection: 'documents',
      success_message: '文档已保存待审核'
    }
    
    code = generator.generate_strategy_plugin(config)
    puts "✅ 策略插件代码生成成功"
    puts "代码长度: #{code.length} 字符"
    puts "包含类名: #{code.include?('ReviewSaveStrategy')}"
    puts "包含策略注册: #{code.include?("strategy_for 'document', 'save', 'review'")}"
  rescue => e
    puts "❌ 策略插件生成失败: #{e.message}"
    puts e.backtrace.first(3)
  end
  puts
  
  # 测试2: 生成字段类型插件
  puts "测试2: 生成字段类型插件"
  puts "-" * 40
  begin
    config = {
      type: 'field_type',
      category: 'field_type/basic',
      category_module: 'Basic',
      class_name: 'TextFieldType',
      field_type_name: 'text'
    }
    
    code = generator.generate_field_type_plugin(config)
    puts "✅ 字段类型插件代码生成成功"
    puts "代码长度: #{code.length} 字符"
    puts "包含类名: #{code.include?('TextFieldType')}"
  rescue => e
    puts "❌ 字段类型插件生成失败: #{e.message}"
    puts e.backtrace.first(3)
  end
  puts
  
  # 测试3: 批量生成插件
  puts "测试3: 批量生成插件"
  puts "-" * 40
  begin
    batch_gen = BatchPluginGenerator.new
    configs = BatchPluginGenerator.create_strategy_plugin_configs.first(2)
    
    # 创建临时输出目录
    output_dir = File.join(Dir.pwd, 'tmp', 'generated_plugins')
    FileUtils.mkdir_p(output_dir)
    
    results = batch_gen.generate_plugins(configs)
    success_count = results[:code_generation].count { |r| r[:success] }
    
    puts "✅ 批量生成成功: #{success_count}/#{configs.size} 个插件"
    results[:code_generation].each do |result|
      if result[:success]
        puts "  - #{result[:plugin_id]}: #{result[:output_path]}"
      else
        puts "  - #{result[:plugin_id]}: 失败 - #{result[:error]}"
      end
    end
    
    # 清理临时文件
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
  rescue => e
    puts "❌ 批量生成失败: #{e.message}"
    puts e.backtrace.first(3)
  end
  puts
  
  puts "="*80
  puts "测试完成"
  puts "="*80
end

# 运行测试
if __FILE__ == $0
  require 'fileutils'
  test_plugin_generator
end

