# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/workflow/auto_trigger_workflow_strategy'

class TestAutoTriggerWorkflowStrategy < Test::Unit::TestCase
  def setup
    @plugin = AutoTriggerWorkflowStrategy.new
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
      context: 'auto_trigger'
    )
    assert_not_nil strategy
    assert_instance_of AutoTriggerWorkflowStrategy, strategy
  end
  
end
