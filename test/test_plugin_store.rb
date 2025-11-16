# frozen_string_literal: true

# 插件商店测试脚本
require_relative '../_system'
require_relative '../lib/plugins/store/plugin_store'
require_relative '../lib/plugins/store/initialize_plugin_store'

def test_plugin_store
  puts "\n" + "="*80
  puts "插件商店功能测试"
  puts "="*80
  puts
  
  store = PluginStore.instance
  
  # 测试1: 初始化插件商店
  puts "测试1: 初始化插件商店"
  puts "-" * 40
  begin
    InitializePluginStore.init!
    puts "✅ 插件商店初始化成功"
  rescue => e
    puts "❌ 插件商店初始化失败: #{e.message}"
    puts e.backtrace.first(3)
  end
  puts
  
  # 测试2: 列出所有插件
  puts "测试2: 列出所有插件"
  puts "-" * 40
  begin
    plugins = store.list_plugins
    puts "✅ 找到 #{plugins.size} 个插件"
    plugins.first(3).each do |plugin|
      puts "  - #{plugin[:name]} (#{plugin[:plugin_id]}) - #{plugin[:category]}"
    end
  rescue => e
    puts "❌ 列出插件失败: #{e.message}"
  end
  puts
  
  # 测试3: 获取插件详情
  puts "测试3: 获取插件详情"
  puts "-" * 40
  begin
    plugin = store.get_plugin('strategy-save-draft')
    if plugin
      puts "✅ 获取插件详情成功"
      puts "  名称: #{plugin[:name]}"
      puts "  描述: #{plugin[:description]}"
      puts "  标签: #{plugin[:tags].join(', ')}"
      puts "  内置: #{plugin[:is_builtin]}"
    else
      puts "❌ 插件不存在"
    end
  rescue => e
    puts "❌ 获取插件详情失败: #{e.message}"
  end
  puts
  
  # 测试4: 搜索插件
  puts "测试4: 搜索插件"
  puts "-" * 40
  begin
    results = store.search_plugins('save')
    puts "✅ 搜索到 #{results.size} 个相关插件"
    results.each do |plugin|
      puts "  - #{plugin[:name]} (#{plugin[:plugin_id]})"
    end
  rescue => e
    puts "❌ 搜索插件失败: #{e.message}"
  end
  puts
  
  # 测试5: 检查安装状态
  puts "测试5: 检查插件安装状态"
  puts "-" * 40
  begin
    installed = store.installed?('strategy-save-draft')
    puts "✅ 插件安装状态检查成功"
    puts "  strategy-save-draft 已安装: #{installed}"
  rescue => e
    puts "❌ 检查安装状态失败: #{e.message}"
  end
  puts
  
  # 测试6: 获取已安装插件列表
  puts "测试6: 获取已安装插件列表"
  puts "-" * 40
  begin
    installed_plugins = store.get_installed_plugins
    puts "✅ 已安装 #{installed_plugins.size} 个插件"
    installed_plugins.each do |p|
      puts "  - #{p['plugin_id']} (版本: #{p['version']})"
    end
  rescue => e
    puts "❌ 获取已安装插件列表失败: #{e.message}"
  end
  puts
  
  puts "="*80
  puts "测试完成"
  puts "="*80
end

# 运行测试
if __FILE__ == $0
  test_plugin_store
end

