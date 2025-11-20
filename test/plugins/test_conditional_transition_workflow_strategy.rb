# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/workflow/conditional_transition_workflow_strategy'

class TestConditionalTransitionWorkflowStrategy < Test::Unit::TestCase
  def setup
    @plugin = ConditionalTransitionWorkflowStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute({})
assert result[:success]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'workflow',
      action: 'process',
      context: 'conditional_transition'
    )
    assert_not_nil strategy
    assert_instance_of ConditionalTransitionWorkflowStrategy, strategy
  end
  
end
