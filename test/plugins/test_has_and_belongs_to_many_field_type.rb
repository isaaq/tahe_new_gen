# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/relation/has_and_belongs_to_many_field_type'

class TestHasAndBelongsToManyFieldType < Test::Unit::TestCase
  def setup
    @plugin = HasAndBelongsToManyFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = HasAndBelongsToManyFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
