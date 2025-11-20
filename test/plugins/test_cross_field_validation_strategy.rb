# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/validation/cross_field_validation_strategy'

class TestCrossFieldValidationStrategy < Test::Unit::TestCase
  def setup
    @plugin = CrossFieldValidationStrategy.new
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
      context: 'cross_field'
    )
    assert_not_nil strategy
    assert_instance_of CrossFieldValidationStrategy, strategy
  end
  
end
