# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/credit_code_field_type'

class TestCreditCodeFieldType < Test::Unit::TestCase
  def setup
    @plugin = CreditCodeFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = CreditCodeFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
