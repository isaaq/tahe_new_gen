# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/composite/date_range_field_type'

class TestDateRangeFieldType < Test::Unit::TestCase
  def setup
    @plugin = DateRangeFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = DateRangeFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
