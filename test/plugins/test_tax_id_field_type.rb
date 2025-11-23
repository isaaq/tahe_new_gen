# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/tax_id_field_type'

class TestTaxIdFieldType < Test::Unit::TestCase
  def setup
    @plugin = TaxIdFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = TaxIdFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
