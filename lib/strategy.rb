require_relative 'strategy/strategy_registry'
require_relative 'strategy/base_strategy'

# 策略模块入口文件
module Strategy
  # 策略模块版本
  VERSION = '0.1.0'
  
  # 预定义所有策略类的命名空间，避免加载顺序问题
  module ::Plugins; end
  module ::Plugins::Strategy; end
  module ::Plugins::Strategy::Save; end
  module ::Plugins::Strategy::Submit; end
  module ::Plugins::Strategy::Search; end
  module ::Plugins::Strategy::Permission; end
  module ::Plugins::Strategy::Field; end
  
  class << self
    # 获取策略注册表实例
    def registry
      @registry ||= StrategyRegistry.instance
    end
    
    # 加载所有策略插件
    def load_plugins
      # 查找并加载所有策略插件（内置插件）
      plugin_pattern = File.join(File.dirname(__FILE__), 'plugins', 'strategy', '**', '*.rb')
      Dir[plugin_pattern].each do |file|
        p "装载插件#{file}" if dev
        require file
      end
      # 加载权限策略插件（如果有单独目录）
      permission_pattern = File.join(File.dirname(__FILE__), 'plugins', 'strategy', 'permission', '**', '*.rb')
      Dir[permission_pattern].each do |file|
        require file
      end
      
      # 加载已安装的商城插件
      load_installed_store_plugins
    end
    
    # 加载已安装的商城插件
    def load_installed_store_plugins
      installed_dir = File.join(File.dirname(__FILE__), 'plugins', 'store', 'installed')
      return unless File.exist?(installed_dir)
      
      # 遍历每个插件目录
      Dir.glob(File.join(installed_dir, '*')).each do |plugin_dir|
        next unless File.directory?(plugin_dir)
        
        # 将插件目录添加到加载路径
        $LOAD_PATH.unshift(plugin_dir) unless $LOAD_PATH.include?(plugin_dir)
        
        # 加载插件目录下的所有Ruby文件
        Dir.glob(File.join(plugin_dir, '*.rb')).each do |file|
          begin
            file_name = File.basename(file, '.rb')
            require file_name
            p "装载商城插件#{file}" if dev
          rescue => _e
            # 如果相对路径失败，尝试绝对路径
            begin
              require file
              p "装载商城插件（绝对路径）#{file}" if dev
            rescue => e2
              puts "加载商城插件失败 #{file}: #{e2.message}" if dev
            end
          end
        end
      end
    end
    
    # 初始化策略系统
    def init
      # 确保注册表已初始化
      registry
      # 加载所有插件
      load_plugins
      # registry.load_strategies_from_config

      # 添加调试信息
      # puts "已注册的策略:"
      # registry.strategies.each do |domain, actions|
      #   actions.each do |action, contexts|
      #     contexts.each do |context, klass|
      #       puts "#{domain}.#{action}.#{context} => #{klass}"
      #     end
      #   end
      # end

      puts "策略系统已初始化，已加载 #{registry.strategies_count} 个策略"
    end
  end
end

# 确保注册表在加载策略前可用
Strategy.registry
