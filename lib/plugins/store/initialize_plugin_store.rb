# frozen_string_literal: true

require_relative 'plugin_store'
require_relative 'generate_builtin_plugin_metadata'

# 插件商店初始化
# 系统启动时自动扫描并注册内置插件
module InitializePluginStore
  def self.init!
    store = PluginStore.instance
    
    # 生成内置插件的完整元数据
    begin
      GenerateBuiltinPluginMetadata.generate_all!
    rescue => e
      puts "生成内置插件元数据失败: #{e.message}" if dev?
      puts e.backtrace.first(3) if dev?
    end
    
    # 扫描内置插件（作为备用，如果元数据生成失败）
    begin
      builtin_plugins = store.scan_builtin_plugins
      puts "插件商店初始化完成，发现 #{builtin_plugins.size} 个内置插件" if dev?
    rescue => e
      puts "扫描内置插件失败: #{e.message}" if dev?
    end
    
    true
  end
  
  def self.dev?
    ENV['RACK_ENV'] != 'production'
  end
end

