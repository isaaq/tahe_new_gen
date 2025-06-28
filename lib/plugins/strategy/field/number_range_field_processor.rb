# lib/plugins/strategy/field/number_range_field_processor.rb
require_relative 'base_field_processor'
module Plugins
  module Strategy
    module Field
      class NumberRangeFieldProcessor < ::Plugins::Strategy::Field::BaseProcessor
        strategy_for 'field', 'number_range'
        
        def process(value, meta = {})
          # 实现具体的处理逻辑
          # 这里可以调用 NumberRangeField 的类方法
          if value.is_a?(Hash)
            NumberRangeField.process_data({}, 'value', value)['value']
          else
            value
          end
        end
      end
    end
  end
end