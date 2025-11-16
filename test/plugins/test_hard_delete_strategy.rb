# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/delete/hard_delete_strategy'

class TestHardDeleteStrategy < Test::Unit::TestCase
  def setup
    @plugin = HardDeleteStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute({})
assert result[:success]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'document',
      action: 'delete',
      context: 'hard'
    )
    assert_not_nil strategy
    assert_instance_of HardDeleteStrategy, strategy
  end
  
end
