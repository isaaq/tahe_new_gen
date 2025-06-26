require 'singleton'
require 'yaml'

# 策略注册表初始化时不会立即加载所有策略文件
# 策略文件将在 Strategy.load_plugins 方法中加载

module Strategy
  class StrategyRegistry
    include Singleton
    
    def initialize
      @strategies = {}
    end
    
    # 返回已注册策略数量
    def strategies_count
      count = 0
      @strategies.each do |_, actions|
        actions.each do |_, contexts|
          count += contexts.size
        end
      end
      count
    end
    
    # 根据三维度查找策略
    def resolve(domain:, action:, context: 'default')
      key = [domain.to_s, action.to_s, context.to_s]
      strategy_class = @strategies.dig(*key)
      
      if strategy_class.nil?
        # 尝试查找默认策略
        strategy_class = @strategies.dig(domain.to_s, action.to_s, 'default')
      end
      
      raise "未找到策略: #{key.join('/')}" if strategy_class.nil?
      
      # 返回策略实例
      strategy_class.new
    end
    
    # 注册策略
    def register(domain, action, context, strategy_class)
      @strategies[domain.to_s] ||= {}
      @strategies[domain.to_s][action.to_s] ||= {}
      @strategies[domain.to_s][action.to_s][context.to_s] = strategy_class
    end

    # 从配置文件加载策略
    def load_strategies_from_config
      config_path = File.join(Dir.pwd, 'lib', 'dsl', 'config', 'strategy.yaml')
      return unless File.exist?(config_path)
      
      config = YAML.load_file(config_path)
      return unless config && config['strategies']
      
      config['strategies'].each do |strategy|
        domain = strategy['domain']
        action = strategy['action']
        context = strategy['context'] || 'default'
        class_name = strategy['class']
        
        # 动态加载策略类
        begin
          strategy_class = Object.const_get(class_name)
          register(domain, action, context, strategy_class)
        rescue NameError => e
          puts "警告: 无法加载策略类 #{class_name}: #{e.message}"
        end
      end
    end
  end
  
  # 便捷方法
  def self.registry
    StrategyRegistry.instance
  end
  
  def self.resolve(domain:, action:, context: 'default')
    registry.resolve(domain: domain, action: action, context: context)
  end
end
