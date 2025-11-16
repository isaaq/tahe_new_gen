# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/field/type/business/email_field_type'

class TestEmailFieldType < Test::Unit::TestCase
  def setup
    @plugin = EmailFieldType.new
  end
  
  def test_basic_functionality
    # 测试用例
    field = EmailFieldType.new('test_field')
valid, error = field.validate('test_value')
assert valid, error

  end
  
  
end
