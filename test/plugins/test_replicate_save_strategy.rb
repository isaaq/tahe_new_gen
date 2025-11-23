# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/save/replicate_save_strategy'

class TestReplicateSaveStrategy < Test::Unit::TestCase
  def setup
    @plugin = ReplicateSaveStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute(
  data: { title: '测试', content: '内容' },
  collection: 'test_documents'
)
assert result[:success]
assert_not_nil result[:document_id]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'document',
      action: 'save',
      context: 'replicate'
    )
    assert_not_nil strategy
    assert_instance_of ReplicateSaveStrategy, strategy
  end
  
end
