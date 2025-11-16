# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/composite/json_object_field_type'

class TestJsonObjectFieldType < Test::Unit::TestCase
  def setup
    @plugin = JsonObjectFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = JsonObjectFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
