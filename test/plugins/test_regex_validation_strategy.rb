# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/validation/regex_validation_strategy'

class TestRegexValidationStrategy < Test::Unit::TestCase
  def setup
    @plugin = RegexValidationStrategy.new
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
      context: 'regex'
    )
    assert_not_nil strategy
    assert_instance_of RegexValidationStrategy, strategy
  end
  
end
