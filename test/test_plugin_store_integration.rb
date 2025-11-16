# frozen_string_literal: true

# 插件商店集成测试
require_relative '../_system'
require_relative '../lib/plugins/store/plugin_store'
require_relative '../lib/plugins/store/initialize_plugin_store'

def test_plugin_store_integration
  puts "\n" + "="*80
  puts "插件商店集成测试"
  puts "="*80
  puts
  
  # 测试1: 初始化插件商店
  puts "测试1: 初始化插件商店"
  puts "-" * 40
  begin
    InitializePluginStore.init!
    puts "✅ 插件商店初始化成功"
  rescue => e
    puts "❌ 插件商店初始化失败: #{e.message}"
    puts e.backtrace.first(5)
  end
  puts
  
  # 测试2: 列出所有插件
  puts "测试2: 列出所有插件"
  puts "-" * 40
  begin
    store = PluginStore.instance
    plugins = store.list_plugins
    puts "✅ 找到 #{plugins.size} 个插件"
    
    if plugins.size > 0
      puts "\n插件列表："
      plugins.each do |plugin|
        status = plugin[:installed] ? "已安装" : "未安装"
        builtin = plugin[:is_builtin] ? " [内置]" : ""
        puts "  - #{plugin[:name]} (#{plugin[:plugin_id]}) - #{status}#{builtin}"
      end
    end
  rescue => e
    puts "❌ 列出插件失败: #{e.message}"
    puts e.backtrace.first(3)
  end
  puts
  
  # 测试3: 获取插件详情
  puts "测试3: 获取插件详情"
  puts "-" * 40
  begin
    store = PluginStore.instance
    plugin = store.get_plugin('strategy-save-draft')
    
    if plugin
      puts "✅ 获取插件详情成功"
      puts "  名称: #{plugin[:name]}"
      puts "  描述: #{plugin[:description]}"
      puts "  分类: #{plugin[:category]}"
      puts "  标签: #{plugin[:tags].join(', ')}"
      puts "  内置: #{plugin[:is_builtin]}"
      puts "  已安装: #{plugin[:installed]}"
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
    store = PluginStore.instance
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
    store = PluginStore.instance
    installed = store.installed?('strategy-save-draft')
    puts "✅ strategy-save-draft 已安装: #{installed}"
    
    installed_plugins = store.get_installed_plugins
    puts "✅ 已安装 #{installed_plugins.size} 个插件"
  rescue => e
    puts "❌ 检查安装状态失败: #{e.message}"
  end
  puts
  
  # 测试6: 验证策略注册
  puts "测试6: 验证策略注册"
  puts "-" * 40
  begin
    if defined?(Strategy) && defined?(Strategy::StrategyRegistry)
      registry = Strategy::StrategyRegistry.instance
      count = registry.strategies_count
      puts "✅ 策略系统已注册 #{count} 个策略"
      
      # 尝试解析一个策略
      begin
        strategy = Strategy.resolve(domain: 'document', action: 'save', context: 'draft')
        puts "✅ 成功解析策略: document/save/draft"
      rescue => e
        puts "⚠️  策略解析失败: #{e.message}"
      end
    else
      puts "⚠️  策略系统未加载"
    end
  rescue => e
    puts "❌ 验证策略注册失败: #{e.message}"
  end
  puts
  
  puts "="*80
  puts "集成测试完成"
  puts "="*80
end

# 运行测试
if __FILE__ == $0
  test_plugin_store_integration
end

