# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/query/advanced_filter_query_strategy'

class TestAdvancedFilterQueryStrategy < Test::Unit::TestCase
  def setup
    @plugin = AdvancedFilterQueryStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute(
  query: {},
  collection: 'test_documents'
)
assert result[:success]
assert_kind_of Array, result[:data]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'document',
      action: 'query',
      context: 'advanced_filter'
    )
    assert_not_nil strategy
    assert_instance_of AdvancedFilterQueryStrategy, strategy
  end
  
end
