# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/special/rich_text_field_type'

class TestRichTextFieldType < Test::Unit::TestCase
  def setup
    @plugin = RichTextFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = RichTextFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
