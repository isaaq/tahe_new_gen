# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/notification/dingtalk_notification_strategy'

class TestDingtalkNotificationStrategy < Test::Unit::TestCase
  def setup
    @plugin = DingtalkNotificationStrategy.new
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
      context: 'dingtalk'
    )
    assert_not_nil strategy
    assert_instance_of DingtalkNotificationStrategy, strategy
  end
  
end
