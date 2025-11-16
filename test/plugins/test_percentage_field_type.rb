# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/percentage_field_type'

class TestPercentageFieldType < Test::Unit::TestCase
  def setup
    @plugin = PercentageFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = PercentageFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
