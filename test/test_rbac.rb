require_relative 'test_common'

class TestRbac < Test::Unit::TestCase
  include Common

  def test_rbac
    M.load_path = 'test/data/dsl/model'
    u = {_id: "671765994f64647c7584c5cd", 'roles' => ['admin']}
    M.user = u
    r = M[:订单].query.to_a
    p r
  end
end