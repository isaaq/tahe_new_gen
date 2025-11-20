# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/workflow/sequential_approval_workflow_strategy'

class TestSequentialApprovalWorkflowStrategy < Test::Unit::TestCase
  def setup
    @plugin = SequentialApprovalWorkflowStrategy.new
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
      context: 'sequential_approval'
    )
    assert_not_nil strategy
    assert_instance_of SequentialApprovalWorkflowStrategy, strategy
  end
  
end
