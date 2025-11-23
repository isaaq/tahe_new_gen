# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/composite/map_field_type'

class TestMapFieldType < Test::Unit::TestCase
  def setup
    @plugin = MapFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = MapFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
