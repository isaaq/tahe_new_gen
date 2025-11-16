# frozen_string_literal: true

require 'singleton'
require 'yaml'
require 'fileutils'
require_relative '../../util/common'

# 插件商店核心类
# 管理插件的存储、查询、安装等功能
class PluginStore
  include Singleton
  
  STORE_COLLECTION = 'plugin_store'
  INSTALLED_DIR = File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'plugins', 'store', 'installed')
  STRATEGY_CONFIG_PATH = File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'dsl', 'config', 'strategy.yaml')
  
  def initialize
    @memory_cache = {}  # 内存缓存
    ensure_installed_dir!
  end
  
  # ========== 插件查询 ==========
  
  # 列出所有插件
  def list_plugins(category: nil, tags: [], is_builtin: nil, installed: nil)
    query = {}
    query[:category] = category if category
    query[:tags] = { '$in' => tags } if tags.any?
    query[:is_builtin] = is_builtin unless is_builtin.nil?
    
    plugins = Common::M[STORE_COLLECTION].query(query).to_a
    
    # 如果指定了installed过滤，需要检查安装状态
    if !installed.nil?
      plugins = plugins.select do |plugin|
        is_installed = installed?(plugin['plugin_id'])
        installed ? is_installed : !is_installed
      end
    end
    
    plugins.map { |p| format_plugin(p) }
  end
  
  # 获取插件详情
  def get_plugin(plugin_id, version = nil)
    query = { plugin_id: plugin_id }
    query[:version] = version if version
    
    plugin = Common::M[STORE_COLLECTION].query(query).sort(version: -1).first
    return nil unless plugin
    
    format_plugin(plugin)
  end
  
  # 搜索插件
  def search_plugins(keyword)
    # MongoDB文本搜索（如果已创建索引）
    # 否则使用正则表达式搜索
    query = {
      '$or' => [
        { name: /#{keyword}/i },
        { description: /#{keyword}/i },
        { tags: /#{keyword}/i }
      ]
    }
    
    plugins = Common::M[STORE_COLLECTION].query(query).to_a
    plugins.map { |p| format_plugin(p) }
  end
  
  # ========== 插件安装 ==========
  
  # 安装插件
  def install_plugin(plugin_id, version = 'latest')
    plugin = get_plugin(plugin_id, version)
    return { success: false, error: 'Plugin not found' } unless plugin
    
    # 检查是否已安装
    if installed?(plugin_id)
      return { success: false, error: 'Plugin already installed' }
    end
    
    begin
      # 如果是内置插件，不需要安装文件
      if plugin[:is_builtin]
        # 内置插件不需要安装文件
      else
        # 商城插件：从MongoDB读取代码并写入文件系统
        install_result = install_plugin_files(plugin)
        return { success: false, error: install_result[:error] } unless install_result[:success]
      end
      
      # 更新配置文件
      update_strategy_config(plugin)
      
      # 如果是商城插件，需要加载插件文件
      unless plugin[:is_builtin]
        load_installed_plugin_files(plugin_id)
      end
      
      # 重新加载策略配置（如果配置文件已更新）
      reload_strategy_config if defined?(Strategy)
      
      # 标记为已安装
      mark_as_installed(plugin_id, plugin[:version])
      
      { success: true, plugin: plugin, message: 'Plugin installed successfully' }
    rescue => e
      { success: false, error: e.message, backtrace: e.backtrace.first(5) }
    end
  end
  
  # 卸载插件
  def uninstall_plugin(plugin_id)
    plugin = get_plugin(plugin_id)
    return { success: false, error: 'Plugin not found' } unless plugin
    
    # 内置插件不能卸载
    if plugin[:is_builtin]
      return { success: false, error: 'Builtin plugins cannot be uninstalled' }
    end
    
    begin
      # 删除安装的文件
      plugin_dir = File.join(INSTALLED_DIR, plugin_id)
      FileUtils.rm_rf(plugin_dir) if File.exist?(plugin_dir)
      
      # 从配置文件中移除
      remove_from_strategy_config(plugin)
      
      # 重新加载策略配置
      reload_strategy_config if defined?(Strategy)
      
      # 标记为未安装
      mark_as_uninstalled(plugin_id)
      
      { success: true, message: 'Plugin uninstalled successfully' }
    rescue => e
      { success: false, error: e.message }
    end
  end
  
  # 检查插件是否已安装
  def installed?(plugin_id)
    installed_plugins = get_installed_plugins
    installed_plugins.any? { |p| p['plugin_id'] == plugin_id }
  end
  
  # 获取已安装的插件列表
  def get_installed_plugins
    Common::M['installed_plugins'].query.to_a
  end
  
  # ========== 内置插件管理 ==========
  
  # 扫描并注册内置插件
  def scan_builtin_plugins
    builtin_dir = File.join(File.dirname(__FILE__), '..', 'strategy')
    plugins = []
    
    Dir.glob(File.join(builtin_dir, '**', '*.rb')).each do |file_path|
      next if file_path.include?('base_')
      
      plugin_meta = extract_plugin_metadata(file_path)
      next unless plugin_meta
      
      # 注册到商店（如果不存在）
      register_builtin_plugin(plugin_meta)
      plugins << plugin_meta
    end
    
    plugins
  end
  
  # ========== 私有方法 ==========
  
  private
  
  def format_plugin(plugin_doc)
    {
      plugin_id: plugin_doc['plugin_id'],
      name: plugin_doc['name'],
      category: plugin_doc['category'],
      version: plugin_doc['version'],
      author: plugin_doc['author'],
      description: plugin_doc['description'],
      tags: plugin_doc['tags'] || [],
      is_builtin: plugin_doc['is_builtin'] || false,
      config_schema: plugin_doc['config_schema'] || {},
      install_config: plugin_doc['install_config'] || {},
      examples: plugin_doc['examples'] || [],
      installed: installed?(plugin_doc['plugin_id'])
    }
  end
  
  def install_plugin_files(plugin)
    plugin_id = plugin[:plugin_id]
    plugin_dir = File.join(INSTALLED_DIR, plugin_id)
    FileUtils.mkdir_p(plugin_dir)
    
    # 从MongoDB读取插件文件
    plugin_doc = Common::M[STORE_COLLECTION].query(plugin_id: plugin_id).first
    return { success: false, error: 'Plugin files not found in store' } unless plugin_doc
    
    files = plugin_doc['files'] || []
    return { success: false, error: 'No files in plugin' } if files.empty?
    
    files.each do |file_info|
      # 保持相对路径结构
      relative_path = file_info['path']
      # 如果是绝对路径，只取文件名
      file_name = File.basename(relative_path)
      file_path = File.join(plugin_dir, file_name)
      
      File.write(file_path, file_info['content'])
      puts "已安装文件: #{file_path}" if dev?
    end
    
    { success: true, installed_files: files.map { |f| f['path'] } }
  end
  
  def update_strategy_config(plugin)
    return unless plugin[:install_config] && plugin[:install_config]['strategy_yaml']
    
    config = load_strategy_config
    strategies = config['strategies'] || []
    
    # 添加新的策略配置
    new_strategies = plugin[:install_config]['strategy_yaml']['add'] || []
    new_strategies.each do |strategy|
      # 检查是否已存在
      exists = strategies.any? do |s|
        s['domain'] == strategy['domain'] &&
        s['action'] == strategy['action'] &&
        s['context'] == strategy['context']
      end
      
      unless exists
        strategies << strategy
      end
    end
    
    # 保存配置文件
    save_strategy_config(config)
  end
  
  def remove_from_strategy_config(plugin)
    return unless plugin[:install_config] && plugin[:install_config]['strategy_yaml']
    
    config = load_strategy_config
    strategies = config['strategies'] || []
    
    # 移除策略配置
    remove_strategies = plugin[:install_config]['strategy_yaml']['remove'] || []
    remove_strategies.each do |strategy|
      strategies.reject! do |s|
        s['domain'] == strategy['domain'] &&
        s['action'] == strategy['action'] &&
        s['context'] == strategy['context']
      end
    end
    
    # 保存配置文件
    save_strategy_config(config)
  end
  
  def load_strategy_config
    return { 'strategies' => [] } unless File.exist?(STRATEGY_CONFIG_PATH)
    YAML.load_file(STRATEGY_CONFIG_PATH) || { 'strategies' => [] }
  end
  
  def save_strategy_config(config)
    FileUtils.mkdir_p(File.dirname(STRATEGY_CONFIG_PATH))
    File.write(STRATEGY_CONFIG_PATH, YAML.dump(config))
  end
  
  def mark_as_installed(plugin_id, version)
    Common::M['installed_plugins'].upsert(
      { plugin_id: plugin_id },
      {
        plugin_id: plugin_id,
        version: version,
        installed_at: Time.now
      }
    )
  end
  
  def mark_as_uninstalled(plugin_id)
    Common::M['installed_plugins'].delete_many(plugin_id: plugin_id)
  end
  
  def extract_plugin_metadata(file_path)
    content = File.read(file_path)
    
    # 尝试从文件内容提取元数据
    # 查找 strategy_for 调用
    strategy_match = content.match(/strategy_for\s+['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]/)
    return nil unless strategy_match
    
    domain = strategy_match[1]
    action = strategy_match[2]
    context = strategy_match[3]
    
    # 提取类名
    class_match = content.match(/class\s+(\w+)\s*</)
    class_name = class_match ? class_match[1] : File.basename(file_path, '.rb')
    
    # 构建插件ID
    plugin_id = "strategy-#{action}-#{context}"
    
    {
      plugin_id: plugin_id,
      name: "#{class_name}",
      category: "strategy/#{action}",
      version: '1.0.0',
      author: 'kr_new_gen_team',
      description: "内置策略：#{class_name}",
      tags: [action, context],
      is_builtin: true,
      files: [
        {
          path: file_path,
          content: content,
          is_builtin: true
        }
      ],
      install_config: {
        strategy_yaml: {
          add: [
            {
              domain: domain,
              action: action,
              context: context,
              class: extract_class_path(file_path)
            }
          ]
        }
      }
    }
  end
  
  def extract_class_path(file_path)
    # 从文件路径推断类路径
    # lib/plugins/strategy/save/draft_save_strategy.rb
    # => Plugins::Strategy::Save::DraftSaveStrategy
    
    relative_path = file_path.sub(/.*lib\/plugins\/strategy\//, '')
    parts = relative_path.sub(/\.rb$/, '').split('/')
    class_name = parts.last.split('_').map(&:capitalize).join
    
    namespace = parts[0..-2].map { |p| p.split('_').map(&:capitalize).join }
    full_path = ['Plugins', 'Strategy'] + namespace + [class_name]
    full_path.join('::')
  end
  
  def register_builtin_plugin(plugin_meta)
    # 检查是否已存在
    existing = Common::M[STORE_COLLECTION].query(plugin_id: plugin_meta[:plugin_id]).first
    return if existing
    
    # 注册到商店
    Common::M[STORE_COLLECTION].add(plugin_meta)
  end
  
  def ensure_installed_dir!
    FileUtils.mkdir_p(INSTALLED_DIR)
  end
  
  def load_installed_plugin_files(plugin_id)
    plugin_dir = File.join(INSTALLED_DIR, plugin_id)
    return unless File.exist?(plugin_dir)
    
    # 将插件目录添加到加载路径
    $LOAD_PATH.unshift(plugin_dir) unless $LOAD_PATH.include?(plugin_dir)
    
    # 加载插件目录下的所有Ruby文件
    Dir.glob(File.join(plugin_dir, '*.rb')).each do |file_path|
      begin
        # 使用相对路径require，避免路径问题
        file_name = File.basename(file_path, '.rb')
        require file_name
        puts "已加载插件文件: #{file_path}" if dev?
      rescue => _e
        # 如果相对路径失败，尝试绝对路径
        begin
          require file_path
          puts "已加载插件文件（绝对路径）: #{file_path}" if dev?
        rescue => e2
          puts "加载插件文件失败 #{file_path}: #{e2.message}" if dev?
        end
      end
    end
  end
  
  def reload_strategy_config
    return unless defined?(Strategy) && defined?(Strategy::StrategyRegistry)
    
    begin
      # 重新加载配置文件中的策略
      Strategy::StrategyRegistry.instance.load_strategies_from_config
      puts "已重新加载策略配置" if dev?
    rescue => e
      puts "重新加载策略配置失败: #{e.message}" if dev?
    end
  end
  
  def dev?
    ENV['RACK_ENV'] != 'production'
  end
end

