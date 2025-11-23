# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/order_number_field_type'

class TestOrderNumberFieldType < Test::Unit::TestCase
  def setup
    @plugin = OrderNumberFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = OrderNumberFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
