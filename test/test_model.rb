require_relative 'test_common'

class TestModel < Test::Unit::TestCase
  include Common
  def test_model
    M.load_model('test/data/dsl/model/伞流水.m')
    # p M[:伞流水].find().to_a
    p M[:伞流水].query.to_a
  end

  def test_para; end

  def test_order
    M[:订单].add({ test: 123 })
    puts M[:订单].query.to_a
    M[:订单].update_one({ test: 456 }, { test: 333 })
    puts M[:订单].query.to_a
    M[:订单].del({ test: 123 })
    puts M[:订单].query.to_a
  end

  def test_query_by_biz
    p M[:订单].query({ name: '' }).to_a
  end

  def test_query_sys
    p M[:_页面].query({ name: '' }).to_a
    p M[:_脚本].query(name: '/app/all_dept').to_a
  end

  def test_change_db
    t = M.change_db(:dc_matrix)[:sys_dict].query(name: '行业类型').to_a
    p t

    t2 = M.change_db(:appback_test,
                     { host: '112.74.62.46', user: 'admin', pass: 'Th2020.!',
                       db: 'admin' })[:b_dicts].query(name: 'logo').to_a
    p t2
  end

  def test_fk
    M.load_path = 'test/data/dsl/model'
    x = M[:店铺].query.to_all[0]
    __p x[:fk_b_contents][1][:content]
  end

  def test_article
    p M[:b_articles_hots].query({}).sort({ }).to_a
  end

  def test_role
    p M[:店铺].query.to_a
  end

  def test_global_search
    p M[:_组织].query(_global_search_str: '测试').to_a
  end

  def test_method_override
    # 在 MCOrg 类中定义一个测试方法
    MCOrg.define_singleton_method(:test_method) do
      "这是 MCOrg 类的测试方法"
    end
    
    # 调用测试方法
    result = M[:_组织].test_method
    p result  # 应该输出 "这是 MCOrg 类的测试方法"
  end
end
