# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/delete/archive_delete_strategy'

class TestArchiveDeleteStrategy < Test::Unit::TestCase
  def setup
    @plugin = ArchiveDeleteStrategy.new
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
      context: 'archive'
    )
    assert_not_nil strategy
    assert_instance_of ArchiveDeleteStrategy, strategy
  end
  
end
