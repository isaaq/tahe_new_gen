# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/composite/array_field_type'

class TestArrayFieldType < Test::Unit::TestCase
  def setup
    @plugin = ArrayFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = ArrayFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
