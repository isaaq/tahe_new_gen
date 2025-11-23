# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/relation/self_referencing_field_type'

class TestSelfReferencingFieldType < Test::Unit::TestCase
  def setup
    @plugin = SelfReferencingFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = SelfReferencingFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
