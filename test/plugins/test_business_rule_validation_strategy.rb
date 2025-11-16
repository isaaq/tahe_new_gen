# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/validation/business_rule_validation_strategy'

class TestBusinessRuleValidationStrategy < Test::Unit::TestCase
  def setup
    @plugin = BusinessRuleValidationStrategy.new
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
      context: 'business_rule'
    )
    assert_not_nil strategy
    assert_instance_of BusinessRuleValidationStrategy, strategy
  end
  
end
