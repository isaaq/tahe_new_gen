# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/ip_field_type'

class TestIpFieldType < Test::Unit::TestCase
  def setup
    @plugin = IpFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = IpFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
