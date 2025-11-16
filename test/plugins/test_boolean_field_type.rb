# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/basic/boolean_field_type'

class TestBooleanFieldType < Test::Unit::TestCase
  def setup
    @plugin = BooleanFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = BooleanFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
