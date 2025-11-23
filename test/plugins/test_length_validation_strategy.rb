# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/validation/length_validation_strategy'

class TestLengthValidationStrategy < Test::Unit::TestCase
  def setup
    @plugin = LengthValidationStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute({})
assert result[:success]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'validation',
      action: 'validate',
      context: 'length'
    )
    assert_not_nil strategy
    assert_instance_of LengthValidationStrategy, strategy
  end
  
end
