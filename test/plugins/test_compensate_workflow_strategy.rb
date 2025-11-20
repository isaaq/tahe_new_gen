# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/workflow/compensate_workflow_strategy'

class TestCompensateWorkflowStrategy < Test::Unit::TestCase
  def setup
    @plugin = CompensateWorkflowStrategy.new
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
      context: 'compensate'
    )
    assert_not_nil strategy
    assert_instance_of CompensateWorkflowStrategy, strategy
  end
  
end
