# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/special/formula_field_type'

class TestFormulaFieldType < Test::Unit::TestCase
  def setup
    @plugin = FormulaFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = FormulaFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
