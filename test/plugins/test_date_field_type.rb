# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/basic/date_field_type'

class TestDateFieldType < Test::Unit::TestCase
  def setup
    @plugin = DateFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = DateFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
