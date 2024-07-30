require_relative 'test_common'

class TestModel < Test::Unit::TestCase
  include Common
  def test_model
    M.load_model('test/data/dsl/model/伞流水.m')
    # p M[:伞流水].find().to_a
    p M[:伞流水].query().to_a
  end

  def test_para

  end

  def test_order
    M[:订单].add({test: 123})
    puts M[:订单].query.to_a
    M[:订单].update_one({test: 456} , {test: 333})
    puts M[:订单].query.to_a
    M[:订单].del({test: 123})
    puts M[:订单].query.to_a
  end

  def test_query_by_biz
    p M[:订单].query({name: ''}).to_a
  end

  def test_query_sys
    p M[:_页面].query({name: ''}).to_a
    p M[:_脚本].query(name: '/app/all_dept').to_a
  end

  def test_change_db
    t = M.change_db(:dc_matrix)[:sys_dict]
  end
end
