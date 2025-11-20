# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/composite/color_field_type'

class TestColorFieldType < Test::Unit::TestCase
  def setup
    @plugin = ColorFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = ColorFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
