require_relative '../../../strategy/base_strategy'

module Plugins
  module Strategy
    module Permission
      class DefaultPermissionStrategy < ::PermissionStrategy
        # 自动注册为 permission/filter/default 策略
        strategy_for 'permission', 'filter', 'default'

        def perform(params = {})
          user = params[:user] || {}
          meta = params[:meta] || {}
          # 原 util 里的权限判断逻辑
          return true if user[:role] == 'admin'
          meta[:access_rules] ||= {}
          meta[:created_by] == user[:_id] ||
            meta[:access_rules][:public] ||
            (meta[:access_rules][:department_visible] && user[:department_id] == meta[:department_id]) ||
            (meta[:access_rules][:allowed_users] || []).include?(user[:_id]) ||
            ((meta[:access_rules][:allowed_groups] || []) & (user[:groups] || [])).any?
        end
      end
    end
  end
end 