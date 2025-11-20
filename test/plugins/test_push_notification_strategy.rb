# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/notification/push_notification_strategy'

class TestPushNotificationStrategy < Test::Unit::TestCase
  def setup
    @plugin = PushNotificationStrategy.new
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
      context: 'push'
    )
    assert_not_nil strategy
    assert_instance_of PushNotificationStrategy, strategy
  end
  
end
