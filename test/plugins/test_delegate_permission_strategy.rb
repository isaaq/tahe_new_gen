# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/permission/delegate_permission_strategy'

class TestDelegatePermissionStrategy < Test::Unit::TestCase
  def setup
    @plugin = DelegatePermissionStrategy.new
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
      context: 'delegate'
    )
    assert_not_nil strategy
    assert_instance_of DelegatePermissionStrategy, strategy
  end
  
end
