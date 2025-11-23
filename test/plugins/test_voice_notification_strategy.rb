# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../plugins/strategy/notification/voice_notification_strategy'

class TestVoiceNotificationStrategy < Test::Unit::TestCase
  def setup
    @plugin = VoiceNotificationStrategy.new
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
      context: 'voice'
    )
    assert_not_nil strategy
    assert_instance_of VoiceNotificationStrategy, strategy
  end
  
end
