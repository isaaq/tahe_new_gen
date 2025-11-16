# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/permission/role_permission_strategy'

class TestRolePermissionStrategy < Test::Unit::TestCase
  def setup
    @plugin = RolePermissionStrategy.new
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
      context: 'role'
    )
    assert_not_nil strategy
    assert_instance_of RolePermissionStrategy, strategy
  end
  
end
