# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/relation/through_field_type'

class TestThroughFieldType < Test::Unit::TestCase
  def setup
    @plugin = ThroughFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = ThroughFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
