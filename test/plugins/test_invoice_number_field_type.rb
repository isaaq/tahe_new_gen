# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/invoice_number_field_type'

class TestInvoiceNumberFieldType < Test::Unit::TestCase
  def setup
    @plugin = InvoiceNumberFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = InvoiceNumberFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
