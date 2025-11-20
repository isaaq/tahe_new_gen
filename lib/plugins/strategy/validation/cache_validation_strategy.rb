# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class CacheValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'cache'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 缓存验证逻辑
          data = params[:data] || {}
          validation_rules = params[:validation_rules] || {}
          cache_key = params[:cache_key] || Digest::MD5.hexdigest(data.to_json)

          # 获取 MongoDB 客户端
          db = Common::M.database

          # 尝试从缓存获取验证结果
          cache_doc = db['validation_cache'].find_one({ key: cache_key })
          if cache_doc && cache_doc['expires_at'] > Time.now
            return cache_doc['result']
          end

          # 执行实际验证
          errors = []
          validation_rules.each do |field, rules|
            field_value = data[field]
            if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
              errors << { field: field, message: "#{field} 是必填字段" }
            end
          end

          result = errors.empty? ? { success: true, valid: true } : { success: false, valid: false, errors: errors }

          # 写入缓存
          db['validation_cache'].insert_one({
            key: cache_key,
            result: result,
            expires_at: Time.now + (params[:cache_ttl] || 3600),
            created_at: Time.now
          })

          result
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

