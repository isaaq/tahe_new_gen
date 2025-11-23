# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/query/fuzzy_match_query_strategy'

class TestFuzzyMatchQueryStrategy < Test::Unit::TestCase
  def setup
    @plugin = FuzzyMatchQueryStrategy.new
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
      context: 'fuzzy_match'
    )
    assert_not_nil strategy
    assert_instance_of FuzzyMatchQueryStrategy, strategy
  end
  
end
