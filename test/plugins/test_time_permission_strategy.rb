# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/permission/time_permission_strategy'

class TestTimePermissionStrategy < Test::Unit::TestCase
  def setup
    @plugin = TimePermissionStrategy.new
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
      context: 'time'
    )
    assert_not_nil strategy
    assert_instance_of TimePermissionStrategy, strategy
  end
  
end
