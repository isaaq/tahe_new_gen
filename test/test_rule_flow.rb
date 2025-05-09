require_relative 'test_common'

class TestRuleFlow < Test::Unit::TestCase
  include Common

  ##
  # 一般具体执行代码策略比如执行函数的时候, 有很多代码段处理不同的业务
  # 代码段经常频繁变更, 又无法制作成配置, 所以采用规则引擎的方式
  # 目前代码都放在数据库中sys_func, 那么代码也可以拆成代码段, 然后再组合起来(此时该数据条目的type = 'flow')
  # 会有对应的Editor编辑组装这些代码段
  # 代码段组装后变成函数体
  # sys_funcs 得有版本控制 得搞个sys_funcs_archive表存一下特意保存的版本
  def test_rule_flow
    make_flow_test_data
    M.load_path = 'test/data/dsl/model'
    sample = M[:sys_funcs].query(type: 'flow').to_a.sample
    # 如果type = flow, 那么content是待解析代码, 多一个字段codes, 每个元素都是一个代码段
    # 代码段格式是 { _id: ObjectId, code: '...', enabled: true, comment: '...', sort_order: 1, yield: '...'}
    # yield是代码段的输出, 会替换content中的代码
    codes = sample[:content].split("\n").map do |line|
      sample[:codes].find { |c| c[:yield] == line.strip }
    end
    out_code = codes.map { |c| c[:code] }.join("\n")
    puts out_code
    eval(out_code)
  end

  def make_flow_test_data
    M[:sys_funcs].del_many(type: 'flow')
    data = {
      name: "/testflow/test",
      file_name: "",
      content: "##111##\n##222##\n",
      codes: [
        { code: "p 123", yield: "##111##" },
        { code: "p 456", yield: "##222##" }
      ],
      type: "flow"
    }
    M[:sys_funcs].add(data)
  end
end