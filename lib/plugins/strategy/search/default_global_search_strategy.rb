require_relative '../../../strategy/base_strategy'

module Plugins
  module Strategy
    module Search
      class DefaultGlobalSearchStrategy < ::Strategy::BaseStrategy
        # 自动注册为 search/global/default 策略
        strategy_for 'search', 'global', 'default'

        def perform(params = {})
          qry = params[:qry]
          db = params[:db]
          search_text = params[:search_text]
          if db && db.model && db.model.respond_to?(:_fields)
            global_search_fields = db.model._fields.select { |f| f.is_a?(Hash) && f[:is_global_search] }
            if global_search_fields && !global_search_fields.empty?
              or_conditions = global_search_fields.map do |field|
                field_name = field[:name] || field['name']
                next if field_name.nil?
                { field_name => { '$regex' => search_text, '$options' => 'i' } }
              end.compact
              qry['$or'] = or_conditions if or_conditions.any?
            else
              qry['name'] = { '$regex' => search_text, '$options' => 'i' }
            end
          else
            qry['name'] = { '$regex' => search_text, '$options' => 'i' }
          end
          qry
        end
      end
    end
  end
end 