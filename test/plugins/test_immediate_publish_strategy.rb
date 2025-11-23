# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/submit/immediate_publish_strategy'

class TestImmediatePublishStrategy < Test::Unit::TestCase
  def setup
    @plugin = ImmediatePublishStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute({})
assert result[:success]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'document',
      action: 'submit',
      context: 'immediate'
    )
    assert_not_nil strategy
    assert_instance_of ImmediatePublishStrategy, strategy
  end
  
end
