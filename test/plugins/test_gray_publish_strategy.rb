# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/submit/gray_publish_strategy'

class TestGrayPublishStrategy < Test::Unit::TestCase
  def setup
    @plugin = GrayPublishStrategy.new
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
      context: 'gray'
    )
    assert_not_nil strategy
    assert_instance_of GrayPublishStrategy, strategy
  end
  
end
