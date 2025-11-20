# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/company_code_field_type'

class TestCompanyCodeFieldType < Test::Unit::TestCase
  def setup
    @plugin = CompanyCodeFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = CompanyCodeFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
