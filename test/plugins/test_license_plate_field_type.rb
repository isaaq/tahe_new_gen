# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/license_plate_field_type'

class TestLicensePlateFieldType < Test::Unit::TestCase
  def setup
    @plugin = LicensePlateFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = LicensePlateFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
