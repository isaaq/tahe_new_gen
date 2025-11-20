# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/workflow/delegate_workflow_strategy'

class TestDelegateWorkflowStrategy < Test::Unit::TestCase
  def setup
    @plugin = DelegateWorkflowStrategy.new
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
      context: 'delegate'
    )
    assert_not_nil strategy
    assert_instance_of DelegateWorkflowStrategy, strategy
  end
  
end
