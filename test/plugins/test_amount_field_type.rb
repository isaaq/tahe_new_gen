# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/amount_field_type'

class TestAmountFieldType < Test::Unit::TestCase
  def setup
    @plugin = AmountFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = AmountFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
