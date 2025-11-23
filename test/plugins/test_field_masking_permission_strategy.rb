# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/permission/field_masking_permission_strategy'

class TestFieldMaskingPermissionStrategy < Test::Unit::TestCase
  def setup
    @plugin = FieldMaskingPermissionStrategy.new
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
      context: 'field_masking'
    )
    assert_not_nil strategy
    assert_instance_of FieldMaskingPermissionStrategy, strategy
  end
  
end
