require_relative 'test_common'
require_relative '../lib/biz/_config'

class TestAuth < Test::Unit::TestCase
  include Common

  def test_role; end

  def test_org
    orgs = BAuth.get_org_list
    p orgs
  end
end
