# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/special/binary_field_type'

class TestBinaryFieldType < Test::Unit::TestCase
  def setup
    @plugin = BinaryFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = BinaryFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
