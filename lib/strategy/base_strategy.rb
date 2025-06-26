module Strategy
  class BaseStrategy
    # 策略执行前的钩子
    def before_execute(params = {})
      # 子类可重写
    end
    
    # 策略执行
    def execute(params = {})
      before_execute(params)
      result = perform(params)
      after_execute(params, result)
      result
    end
    
    # 策略执行后的钩子
    def after_execute(params = {}, result = nil)
      # 子类可重写
    end
    
    # 具体策略实现（子类必须重写）
    def perform(params = {})
      raise NotImplementedError, "#{self.class} 必须实现 perform 方法"
    end
    
    # 策略自注册方法
    def self.register(domain, action, context = 'default')
      Strategy.registry.register(domain, action, context, self)
    end
    
    # 当类被继承时自动添加类方法
    def self.inherited(subclass)
      subclass.extend(ClassMethods)
    end
    
    module ClassMethods
      def strategy_for(domain, action, context = 'default')
        # 使用 Strategy.registry 方法注册策略
        registry = defined?(Strategy.registry) ? Strategy.registry : StrategyRegistry.instance
        registry.register(domain, action, context, self)
      end
    end
  end
end

# 权限策略基类
class PermissionStrategy < Strategy::BaseStrategy
  # 子类需实现 perform(user:, meta:)
end
