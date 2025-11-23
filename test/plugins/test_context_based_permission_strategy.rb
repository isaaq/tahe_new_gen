# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/permission/context_based_permission_strategy'

class TestContextBasedPermissionStrategy < Test::Unit::TestCase
  def setup
    @plugin = ContextBasedPermissionStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute({})
assert result[:success]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'permission',
      action: 'filter',
      context: 'context_based'
    )
    assert_not_nil strategy
    assert_instance_of ContextBasedPermissionStrategy, strategy
  end
  
end
