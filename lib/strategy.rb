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
  
  class << self
    # 获取策略注册表实例
    def registry
      @registry ||= StrategyRegistry.instance
    end
    
    # 加载所有策略插件
    def load_plugins
      # 查找并加载所有策略插件
      plugin_pattern = File.join(File.dirname(__FILE__), 'plugins', 'strategy', '**', '*.rb')
      Dir[plugin_pattern].each do |file|
        require file
      end
      # 加载权限策略插件（如果有单独目录）
      permission_pattern = File.join(File.dirname(__FILE__), 'plugins', 'strategy', 'permission', '**', '*.rb')
      Dir[permission_pattern].each do |file|
        require file
      end
    end
    
    # 初始化策略系统
    def init
      # 确保注册表已初始化
      registry
      # 加载所有插件
      load_plugins
      registry.load_strategies_from_config
      puts "策略系统已初始化，已加载 #{registry.strategies_count} 个策略"
    end
  end
end

# 确保注册表在加载策略前可用
Strategy.registry
