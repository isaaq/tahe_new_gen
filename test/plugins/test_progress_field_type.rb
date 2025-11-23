# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/special/progress_field_type'

class TestProgressFieldType < Test::Unit::TestCase
  def setup
    @plugin = ProgressFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = ProgressFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
