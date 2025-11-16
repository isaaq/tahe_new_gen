# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/phone_field_type'

class TestPhoneFieldType < Test::Unit::TestCase
  def setup
    @plugin = PhoneFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = PhoneFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
