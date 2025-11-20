# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/composite/name_field_type'

class TestNameFieldType < Test::Unit::TestCase
  def setup
    @plugin = NameFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = NameFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
