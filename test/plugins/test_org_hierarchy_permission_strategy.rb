# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/permission/org_hierarchy_permission_strategy'

class TestOrgHierarchyPermissionStrategy < Test::Unit::TestCase
  def setup
    @plugin = OrgHierarchyPermissionStrategy.new
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
      context: 'org_hierarchy'
    )
    assert_not_nil strategy
    assert_instance_of OrgHierarchyPermissionStrategy, strategy
  end
  
end
