# lib/plugins/strategy/field/base_field_processor.rb
module Plugins
  module Strategy
    module Field
      class BaseProcessor < ::Strategy::BaseStrategy
        def self.strategy_for(domain, context, action = 'process')
          ::Strategy.registry.register(domain, action, context, self)
        end
        
        def process(value, meta = {})
          # 默认实现
          value
        end
      end
    end
  end
end
