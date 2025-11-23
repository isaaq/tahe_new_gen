# frozen_string_literal: true

require_relative '../../../strategy/base_strategy'

module Plugins; end
module Plugins::Strategy; end
module Plugins::Strategy::Validation; end

module Plugins
  module Strategy
    module Validation
      class FormatValidationStrategy < ::Strategy::BaseStrategy
        # 自动注册策略
        strategy_for 'validation', 'validate', 'format'
        
        def before_execute(params = {})
          # 验证必要参数
          
          
          raise "缺少必要参数: data" unless params[:data]
          
          raise "缺少必要参数: field" unless params[:field]
          
          
          
          # 预处理逻辑
          
        end
        
        def perform(params = {})
          # 策略实现
          # 格式验证逻辑
          data = params[:data] || {}
          format_rules = params[:format_rules] || {}

          errors = []

          format_rules.each do |field, format_config|
            field_value = data[field.to_sym] || data[field.to_s]
            next if field_value.nil? || field_value.to_s.empty?

            pattern = format_config[:pattern]
            format_type = format_config[:type]

            if pattern
              unless field_value.to_s.match?(pattern)
                errors << { field: field, message: "#{field} 格式不正确" }
              end
            elsif format_type
              case format_type
              when 'email'
                unless field_value.to_s.match?(/A[w+-.]+@[a-zd-]+(.[a-zd-]+)*.[a-z]+z/i)
                  errors << { field: field, message: "#{field} 必须是有效的邮箱地址" }
                end
              when 'phone'
                unless field_value.to_s.match?(/^1[3-9]d{9}$/)
                  errors << { field: field, message: "#{field} 必须是有效的手机号码" }
                end
              when 'url'
                unless field_value.to_s.match?(/A(?x-mi:(?=(?-mix:http|https):)
                  ([a-zA-Z][\-+.a-zA-Z\d]*):                           (?# 1: scheme)
                  (?:
                     ((?:[\-_.!~*'()a-zA-Z\d;?:@&=+$,]|%[a-fA-F\d]{2})(?:[\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]|%[a-fA-F\d]{2})*)                    (?# 2: opaque)
                  |
                     (?:(?:
                       \/\/(?:
                           (?:(?:((?:[\-_.!~*'()a-zA-Z\d;:&=+$,]|%[a-fA-F\d]{2})*)@)?        (?# 3: userinfo)
                             (?:((?:(?:[a-zA-Z0-9\-.]|%\h\h)+|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\[(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|(?:(?:[a-fA-F\d]{1,4}:)*[a-fA-F\d]{1,4})?::(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))?)\]))(?::(\d*))?))? (?# 4: host, 5: port)
                         |
                           ((?:[\-_.!~*'()a-zA-Z\d$,;:@&=+]|%[a-fA-F\d]{2})+)                 (?# 6: registry)
                         )
                       |
                       (?!\/\/))                           (?# XXX: '\/\/' is the mark for hostport)
                       (\/(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*(?:;(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*)*(?:\/(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*(?:;(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*)*)*)?                    (?# 7: path)
                     )(?:\?((?:[\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]|%[a-fA-F\d]{2})*))?                 (?# 8: query)
                  )
                  (?:\#((?:[\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]|%[a-fA-F\d]{2})*))?                  (?# 9: fragment)
                )z/)
                  errors << { field: field, message: "#{field} 必须是有效的URL" }
                end
              when 'date'
                begin
                  Date.parse(field_value.to_s)
                rescue
                  errors << { field: field, message: "#{field} 必须是有效的日期格式" }
                end
              when 'datetime'
                begin
                  DateTime.parse(field_value.to_s)
                rescue
                  errors << { field: field, message: "#{field} 必须是有效的日期时间格式" }
                end
              end
            end
          end

          if errors.empty?
            { success: true, valid: true }
          else
            { success: false, valid: false, errors: errors }
          end
        end
        
        def after_execute(params = {}, result = nil)
          # 后处理逻辑
          
        end
      end
    end
  end
end

