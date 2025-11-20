# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/submit/conditional_review_publish_strategy'

class TestConditionalReviewPublishStrategy < Test::Unit::TestCase
  def setup
    @plugin = ConditionalReviewPublishStrategy.new
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
      context: 'conditional_review'
    )
    assert_not_nil strategy
    assert_instance_of ConditionalReviewPublishStrategy, strategy
  end
  
end
