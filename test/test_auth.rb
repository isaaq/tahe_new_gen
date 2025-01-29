require_relative 'test_common'
require_relative '../lib/biz/_config'
require_relative '../lib/util/auth'

class TestAuth < Test::Unit::TestCase
  include Common
  include Auth

  def test_role; end

  def test_org
    M.load_path = 'test/data/dsl/model'
    orgs = BAuth.get_org_list
    p orgs
  end

  def test_gen_token
    M.load_path = 'test/data/dsl/model'
    puts fetch_token({uid: '671765994f64647c7584c5cd'})
  end
end
