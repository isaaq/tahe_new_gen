# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/basic/time_field_type'

class TestTimeFieldType < Test::Unit::TestCase
  def setup
    @plugin = TimeFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = TimeFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
