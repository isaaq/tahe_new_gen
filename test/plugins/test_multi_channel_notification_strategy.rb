# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/notification/multi_channel_notification_strategy'

class TestMultiChannelNotificationStrategy < Test::Unit::TestCase
  def setup
    @plugin = MultiChannelNotificationStrategy.new
  end
  
  def test_basic_functionality
    # 测试用例
    result = @plugin.execute({})
assert result[:success]

  end
  
  
  def test_strategy_registration
    # 验证策略已注册
    strategy = Strategy.resolve(
      domain: 'notification',
      action: 'notify',
      context: 'multi_channel'
    )
    assert_not_nil strategy
    assert_instance_of MultiChannelNotificationStrategy, strategy
  end
  
end
