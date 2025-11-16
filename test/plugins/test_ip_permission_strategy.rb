# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/permission/ip_permission_strategy'

class TestIpPermissionStrategy < Test::Unit::TestCase
  def setup
    @plugin = IpPermissionStrategy.new
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
      context: 'ip'
    )
    assert_not_nil strategy
    assert_instance_of IpPermissionStrategy, strategy
  end
  
end
