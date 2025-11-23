# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/imei_field_type'

class TestImeiFieldType < Test::Unit::TestCase
  def setup
    @plugin = ImeiFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = ImeiFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
