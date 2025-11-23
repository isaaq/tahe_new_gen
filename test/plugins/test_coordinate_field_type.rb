# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/composite/coordinate_field_type'

class TestCoordinateFieldType < Test::Unit::TestCase
  def setup
    @plugin = CoordinateFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = CoordinateFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
