# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/submit/batch_publish_strategy'

class TestBatchPublishStrategy < Test::Unit::TestCase
  def setup
    @plugin = BatchPublishStrategy.new
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
      context: 'batch'
    )
    assert_not_nil strategy
    assert_instance_of BatchPublishStrategy, strategy
  end
  
end
