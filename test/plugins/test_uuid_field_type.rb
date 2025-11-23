# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/special/uuid_field_type'

class TestUuidFieldType < Test::Unit::TestCase
  def setup
    @plugin = UuidFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = UuidFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
