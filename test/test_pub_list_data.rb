require_relative 'test_common'
require_relative '../lib/biz/_config'

class TestPubListData < Test::Unit::TestCase
  include Common

  def test_pub_list
    dicts = M[:_设置].query.to_a
    p dicts
  end
end

