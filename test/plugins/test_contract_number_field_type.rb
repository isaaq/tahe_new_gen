# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/contract_number_field_type'

class TestContractNumberFieldType < Test::Unit::TestCase
  def setup
    @plugin = ContractNumberFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = ContractNumberFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
