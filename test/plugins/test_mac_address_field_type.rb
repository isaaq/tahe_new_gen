# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/mac_address_field_type'

class TestMacAddressFieldType < Test::Unit::TestCase
  def setup
    @plugin = MacAddressFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = MacAddressFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
