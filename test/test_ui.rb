require_relative 'test_common'

class TestModel < Test::Unit::TestCase
  include Common

  def test_input
    puts UIPage.new(:layui).parse()
  end
end