#!/usr/bin/env ruby
# frozen_string_literal: true

# 产品管理功能完整示例
# 演示如何使用插件商店实现完整的产品管理功能

require_relative '../lib/plugins/store/plugin_store'
require_relative '../lib/ai_services/plugin_assistant'

class ProductManagerExample
  def initialize
    @store = PluginStore.instance
    @assistant = PluginAssistant.instance
  end
  
  # 步骤1: 推荐和安装插件
  def step1_recommend_and_install
    puts "=" * 60
    puts "步骤1: 使用AI推荐插件"
    puts "=" * 60
    
    requirement = "产品管理：保存草稿、验证数据、发布通知、图片上传"
    puts "\n需求描述: #{requirement}"
    puts "\n正在请求AI推荐..."
    
    begin
      result = @assistant.recommend_plugins(requirement)
      
      if result[:success] && result[:plugins]
        puts "\n✅ AI推荐了 #{result[:plugins].size} 个插件:"
        result[:plugins].each_with_index do |plugin, index|
          puts "\n#{index + 1}. #{plugin[:name]} (#{plugin[:plugin_id]})"
          puts "   描述: #{plugin[:description]}"
          puts "   推荐度: #{(plugin[:confidence] || 0.8) * 100}%"
        end
        
        # 询问是否安装（示例中自动安装前3个）
        puts "\n开始安装推荐的插件..."
        result[:plugins].first(3).each do |plugin|
          install_result = @store.install_plugin(plugin[:plugin_id])
          if install_result[:success]
            puts "   ✅ #{plugin[:name]} 安装成功"
          else
            puts "   ❌ #{plugin[:name]} 安装失败: #{install_result[:error]}"
          end
        end
      else
        puts "⚠️  AI推荐失败，使用手动选择插件"
        manual_install
      end
    rescue => e
      puts "⚠️  AI服务不可用: #{e.message}"
      puts "使用手动选择插件"
      manual_install
    end
  end
  
  # 手动安装插件
  def manual_install
    puts "\n正在查找可用的插件..."
    
    # 查找可用的保存策略插件
    save_plugins = @store.list_plugins(category: 'strategy/save')
    validation_plugins = @store.list_plugins(category: 'strategy/validation')
    notification_plugins = @store.list_plugins(category: 'strategy/notification')
    
    # 选择第一个可用的插件
    plugins_to_install = []
    
    if save_plugins.any?
      plugins_to_install << save_plugins.first[:plugin_id]
      puts "  找到保存策略: #{save_plugins.first[:name]} (#{save_plugins.first[:plugin_id]})"
    end
    
    if validation_plugins.any?
      plugins_to_install << validation_plugins.first[:plugin_id]
      puts "  找到验证策略: #{validation_plugins.first[:name]} (#{validation_plugins.first[:plugin_id]})"
    end
    
    if notification_plugins.any?
      plugins_to_install << notification_plugins.first[:plugin_id]
      puts "  找到通知策略: #{notification_plugins.first[:name]} (#{notification_plugins.first[:plugin_id]})"
    end
    
    if plugins_to_install.empty?
      puts "\n⚠️  未找到可用的插件，请先运行插件生成脚本："
      puts "   ruby -r ./lib/plugins/store/generate_plugins.rb -e \"GeneratePlugins.run!\""
      return
    end
    
    puts "\n开始安装插件:"
    plugins_to_install.each do |plugin_id|
      plugin = @store.get_plugin(plugin_id)
      if plugin
        # 检查是否已安装
        if @store.installed?(plugin_id)
          puts "   ℹ️  #{plugin[:name]} (#{plugin_id}) 已安装"
        elsif plugin[:is_builtin]
          # 内置插件，标记为已安装即可
          result = @store.install_plugin(plugin_id)
          if result[:success]
            puts "   ✅ #{plugin[:name]} (#{plugin_id}) 已内置，已标记为已安装"
          else
            puts "   ⚠️  #{plugin[:name]} (#{plugin_id}) 内置插件处理失败: #{result[:error]}"
          end
        else
          # 商城插件，需要安装
          result = @store.install_plugin(plugin_id)
          if result[:success]
            puts "   ✅ #{plugin[:name]} (#{plugin_id}) 安装成功"
          else
            puts "   ❌ #{plugin[:name]} (#{plugin_id}) 安装失败: #{result[:error]}"
          end
        end
      else
        puts "   ⚠️  插件 #{plugin_id} 未找到，跳过"
      end
    end
  end
  
  # 步骤2: 查看插件详情
  def step2_view_plugin_details
    puts "\n" + "=" * 60
    puts "步骤2: 查看插件详情"
    puts "=" * 60
    
    # 查找一个可用的保存策略插件
    save_plugins = @store.list_plugins(category: 'strategy/save')
    
    if save_plugins.any?
      plugin = save_plugins.first
      puts "\n插件: #{plugin[:name]}"
      puts "ID: #{plugin[:plugin_id]}"
      puts "分类: #{plugin[:category]}"
      puts "版本: #{plugin[:version]}"
      puts "描述: #{plugin[:description]}"
      puts "标签: #{plugin[:tags].join(', ')}"
      puts "是否内置: #{plugin[:is_builtin] ? '是' : '否'}"
    else
      puts "⚠️  未找到保存策略插件"
      puts "提示: 请先运行插件生成脚本生成插件"
    end
  end
  
  # 步骤3: 配置插件
  def step3_configure_plugins
    puts "\n" + "=" * 60
    puts "步骤3: 配置插件"
    puts "=" * 60
    
    # 查找一个可用的保存策略插件
    save_plugins = @store.list_plugins(category: 'strategy/save')
    
    if save_plugins.empty?
      puts "\n⚠️  未找到可用的保存策略插件"
      show_default_config
      return
    end
    
    plugin_id = save_plugins.first[:plugin_id]
    
    begin
      config_result = @assistant.configure_plugin(
        plugin_id,
        '保存到products集合，自动添加时间戳，支持版本控制'
      )
      
      if config_result[:success]
        puts "\n✅ AI生成的配置:"
        puts config_result[:config].to_yaml if config_result[:config]
      else
        puts "⚠️  配置生成失败，使用默认配置"
        show_default_config
      end
    rescue => e
      puts "⚠️  AI配置服务不可用: #{e.message}"
      show_default_config
    end
  end
  
  def show_default_config
    puts "\n默认配置示例:"
    puts <<~YAML
      # lib/dsl/config/strategy.yaml
      strategies:
        - domain: product
          action: save
          context: draft
          class: Plugins::Strategy::Save::DraftSaveStrategy
          config:
            collection: products
            auto_timestamp: true
            version_control: true
    YAML
  end
  
  # 步骤4: 查看已安装插件
  def step4_list_installed
    puts "\n" + "=" * 60
    puts "步骤4: 查看已安装的插件"
    puts "=" * 60
    
    installed = @store.list_plugins(installed: true)
    
    if installed.any?
      puts "\n已安装 #{installed.size} 个插件:"
      installed.each do |plugin|
        puts "  - #{plugin[:name]} (#{plugin[:plugin_id]})"
      end
    else
      puts "\n暂无已安装的插件"
    end
  end
  
  # 步骤5: 使用插件示例代码
  def step5_usage_example
    puts "\n" + "=" * 60
    puts "步骤5: 使用插件示例代码"
    puts "=" * 60
    
    puts <<~RUBY

    # 在控制器中使用保存策略
    require_relative 'lib/dsl/strategy'
    
    class ProductController
      def save_draft(product_data)
        # 根据domain、action、context选择策略
        # 注意：如果使用review策略，context应该是'review'
        strategy = Strategy.resolve(
          domain: 'product',
          action: 'save',
          context: 'review'  # 或使用其他已安装的策略context
        )
        
        # 执行策略
        result = strategy.execute(
          data: product_data,
          context: {
            user_id: current_user.id,
            collection: 'products'
          }
        )
        
        if result[:success]
          puts "产品草稿保存成功: \#{result[:document_id]}"
          return result
        else
          puts "保存失败: \#{result[:error]}"
          return nil
        end
      end
    end
    
    # 使用示例
    # controller = ProductController.new
    # product_data = {
    #   name: 'iPhone 15 Pro',
    #   price: 8999,
    #   stock: 100,
    #   category: '电子产品'
    # }
    # result = controller.save_draft(product_data)
    RUBY
  end
  
  # 步骤6: 完整工作流示例
  def step6_complete_workflow
    puts "\n" + "=" * 60
    puts "步骤6: 完整工作流示例"
    puts "=" * 60
    
    puts <<~WORKFLOW

    完整的产品管理流程：
    
    1. 创建产品表单
       - 使用字段类型插件：text, amount, number, image
       - 使用表单行为插件：field-validation, field-format
    
    2. 保存草稿
       - 使用策略：strategy-save-draft
       - 自动添加时间戳
       - 保存到products集合
    
    3. 验证数据
       - 使用策略：strategy-validation-form
       - 验证价格范围
       - 验证库存数量
    
    4. 发布产品
       - 使用策略：strategy-submit-publish
       - 更新状态为已发布
       - 触发通知
    
    5. 发送通知
       - 使用策略：strategy-notification-email
       - 发送邮件通知相关人员
    
    所有步骤都可以通过插件商店的插件来实现！
    WORKFLOW
  end
  
  # 运行所有步骤
  def run
    puts "\n"
    puts "╔" + "=" * 58 + "╗"
    puts "║" + " " * 10 + "插件商店使用示例 - 产品管理功能" + " " * 10 + "║"
    puts "╚" + "=" * 58 + "╝"
    puts
    
    step1_recommend_and_install
    step2_view_plugin_details
    step3_configure_plugins
    step4_list_installed
    step5_usage_example
    step6_complete_workflow
    
    puts "\n" + "=" * 60
    puts "示例演示完成！"
    puts "=" * 60
    puts "\n更多信息请查看:"
    puts "  - 使用指南: docs/plugin_store_user_guide.md"
    puts "  - 示例文档: docs/plugin_store_example_guide.md"
    puts "  - 插件文档: docs/plugins/"
    puts
  end
end

# 运行示例
if __FILE__ == $0
  begin
    example = ProductManagerExample.new
    example.run
  rescue => e
    puts "\n❌ 运行出错: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end
end

