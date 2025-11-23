# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/validation/dependency_validation_strategy'

class TestDependencyValidationStrategy < Test::Unit::TestCase
  def setup
    @plugin = DependencyValidationStrategy.new
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
      context: 'dependency'
    )
    assert_not_nil strategy
    assert_instance_of DependencyValidationStrategy, strategy
  end
  
end
