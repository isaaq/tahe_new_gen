# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/workflow/timeout_workflow_strategy'

class TestTimeoutWorkflowStrategy < Test::Unit::TestCase
  def setup
    @plugin = TimeoutWorkflowStrategy.new
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
      context: 'timeout'
    )
    assert_not_nil strategy
    assert_instance_of TimeoutWorkflowStrategy, strategy
  end
  
end
