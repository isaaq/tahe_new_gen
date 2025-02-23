require_relative 'test_common'

class TestGen < Test::Unit::TestCase
  include Common

  def test_gen_func
    
  end

  def test_gen_meta
    M.load_path = 'test/data/dsl/model'
    M[:订单].query.to_a.each do |e|
      e[:_meta] = build_meta
      M[:订单].update({_id: e[:_id]}, e)
    end
  end

  def build_meta
    {
      roles: ["admin"]
    }
  end
end