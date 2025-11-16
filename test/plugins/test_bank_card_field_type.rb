# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/bank_card_field_type'

class TestBankCardFieldType < Test::Unit::TestCase
  def setup
    @plugin = BankCardFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = BankCardFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
