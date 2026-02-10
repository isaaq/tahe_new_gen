# Tahe DSL Parser - Model DSL Parser

require 'json'

module Tahe
  module DSL
    class ModelParser
      attr_reader :content, :ast

      def initialize(content)
        @content = content
        @ast = {}
      end

      # Parse .krmodel file (JSON format)
      def self.parse(content)
        parser = new(content)
        parser.parse
        parser.ast
      end

      # Parse from file
      def self.parse_file(file_path)
        content = File.read(file_path)
        parse(content)
      end

      def parse
        begin
          @ast = JSON.parse(@content)

          # Validate required fields
          unless @ast['model'] && @ast['fields']
            raise ParseError.new("Model definition must include 'model' and 'fields'")
          end

          # Set defaults
          @ast['collection'] ||= default_collection_name(@ast['model'])
          @ast['timestamps'] = true if @ast['timestamps'].nil?
          @ast['soft_delete'] = false if @ast['soft_delete'].nil?

          # Normalize fields
          @ast['fields'] = normalize_fields(@ast['fields'])

          # Normalize indexes
          @ast['indexes'] = normalize_indexes(@ast['indexes']) if @ast['indexes']

          # Normalize strategies
          @ast['strategies'] = normalize_strategies(@ast['strategies']) if @ast['strategies']

          self
        rescue JSON::ParserError => e
          raise ParseError.new("Invalid JSON: #{e.message}")
        end
      end

      # Extract field names
      def field_names
        @ast['fields'].map { |f| f['name'] }
      end

      # Extract required fields
      def required_fields
        @ast['fields'].select { |f| f['required'] }.map { |f| f['name'] }
      end

      # Extract relation fields
      def relation_fields
        @ast['fields'].select { |f| f['type'].include?('relation') }
      end

      # Extract enum fields
      def enum_fields
        @ast['fields'].select { |f| f['type'] == 'enum' }
      end

      # Get field by name
      def field(name)
        @ast['fields'].find { |f| f['name'] == name }
      end

      class ParseError < StandardError; end

      private

      # Generate default collection name (pluralized snake_case)
      def default_collection_name(model_name)
        snake_case = model_name.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase

        pluralize(snake_case)
      end

      # Simple pluralization
      def pluralize(word)
        return word + 'es' if word.end_with?('s', 'x', 'z', 'ch', 'sh')
        return word[0..-2] + 'ies' if word.end_with?('y') && !%w[a e i o u].include?(word[-2])
        word + 's'
      end

      # Normalize field definitions
      def normalize_fields(fields)
        fields.map do |field|
          normalized = field.dup

          # Ensure required keys
          normalized['required'] = false if normalized['required'].nil?
          normalized['unique'] = false if normalized['unique'].nil?

          # Normalize options
          if normalized['options']
            normalized['options'] = normalize_field_options(normalized['options'], normalized['type'])
          end

          # Normalize UI config
          if normalized['ui']
            normalized['ui']['hidden'] = false if normalized['ui']['hidden'].nil?
            normalized['ui']['readonly'] = false if normalized['ui']['readonly'].nil?
            normalized['ui']['show_in_list'] = true if normalized['ui']['show_in_list'].nil?
            normalized['ui']['show_in_form'] = true if normalized['ui']['show_in_form'].nil?
            normalized['ui']['show_in_detail'] = true if normalized['ui']['show_in_detail'].nil?
          end

          normalized
        end
      end

      # Normalize field options based on type
      def normalize_field_options(options, field_type)
        normalized = options.dup

        case field_type
        when 'single_relation', 'multiple_relation', 'tree_relation'
          # Ensure relation fields have required options
          normalized['display_field'] ||= 'name'
          normalized['cascade_delete'] = false if normalized['cascade_delete'].nil?
        when 'enum'
          # Ensure enum has values
          if normalized['enum_values'] && normalized['enum_values'].is_a?(Array)
            normalized['enum_values'] = normalized['enum_values'].map do |val|
              if val.is_a?(Hash)
                val
              else
                {'value' => val, 'label' => val.to_s}
              end
            end
          end
        when 'amount'
          # Set default currency and precision
          normalized['currency'] ||= 'CNY'
          normalized['precision'] ||= 2
        when 'number', 'number_range'
          # Ensure min/max are numbers
          normalized['min'] = normalized['min'].to_f if normalized['min']
          normalized['max'] = normalized['max'].to_f if normalized['max']
        end

        normalized
      end

      # Normalize index definitions
      def normalize_indexes(indexes)
        return [] unless indexes

        indexes.map do |index|
          normalized = index.dup
          normalized['unique'] = false if normalized['unique'].nil?
          normalized['sparse'] = false if normalized['sparse'].nil?

          # Normalize fields
          if normalized['fields']
            normalized['fields'] = normalized['fields'].map do |field|
              if field.is_a?(String)
                {'field' => field, 'order' => 1}
              else
                field['order'] ||= 1
                field
              end
            end
          end

          normalized
        end
      end

      # Normalize strategy definitions
      def normalize_strategies(strategies)
        return [] unless strategies

        strategies.map do |strategy|
          normalized = strategy.dup

          # Generate class name if not provided
          unless normalized['class']
            normalized['class'] = generate_strategy_class_name(
              normalized['action'],
              normalized['context']
            )
          end

          normalized['config'] ||= {}

          normalized
        end
      end

      # Generate strategy class name from action and context
      def generate_strategy_class_name(action, context)
        action_class = action.split('_').map(&:capitalize).join
        context_class = context.split('_').map(&:capitalize).join

        "Plugins::Strategy::#{action_class}::#{context_class}Strategy"
      end
    end
  end
end
