# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/workflow/add_signer_workflow_strategy'

class TestAddSignerWorkflowStrategy < Test::Unit::TestCase
  def setup
    @plugin = AddSignerWorkflowStrategy.new
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
      context: 'add_signer'
    )
    assert_not_nil strategy
    assert_instance_of AddSignerWorkflowStrategy, strategy
  end
  
end
