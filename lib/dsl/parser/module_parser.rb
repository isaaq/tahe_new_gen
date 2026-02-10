# Tahe DSL Parser - Module DSL Parser

require 'json'
require_relative 'model_parser'

module Tahe
  module DSL
    class ModuleParser
      attr_reader :content, :ast

      def initialize(content)
        @content = content
        @ast = {}
      end

      # Parse .krmodule file (JSON format)
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
          unless @ast['module'] && @ast['model']
            raise ParseError.new("Module definition must include 'module' and 'model'")
          end

          # Parse embedded model
          if @ast['model']
            @ast['model'] = parse_embedded_model(@ast['model'])
          end

          # Normalize pages
          @ast['pages'] = normalize_pages(@ast['pages']) if @ast['pages']

          # Normalize API configuration
          @ast['api'] = normalize_api(@ast['api']) if @ast['api']

          self
        rescue JSON::ParserError => e
          raise ParseError.new("Invalid JSON: #{e.message}")
        end
      end

      # Extract model definition
      def model
        @ast['model']
      end

      # Extract page definitions
      def pages
        @ast['pages'] || []
      end

      # Extract API configuration
      def api
        @ast['api']
      end

      # Get page by type
      def page_by_type(type)
        pages.find { |p| p['type'] == type }
      end

      # Get API endpoint by action
      def endpoint_by_action(action)
        return nil unless api && api['endpoints']
        api['endpoints'].find { |e| e['action'] == action }
      end

      class ParseError < StandardError; end

      private

      # Parse embedded model definition
      def parse_embedded_model(model_data)
        # If model_data is already parsed, return it
        return model_data if model_data.is_a?(Hash) && model_data['fields']

        # Otherwise, parse it using ModelParser
        model_json = model_data.is_a?(String) ? model_data : model_data.to_json
        ModelParser.parse(model_json)
      end

      # Normalize page definitions
      def normalize_pages(pages)
        return [] unless pages

        pages.map do |page|
          normalized = page.dup

          # Set defaults
          normalized['layout'] ||= 'admin'
          normalized['permissions'] ||= []

          # Generate route if not provided
          unless normalized['route']
            normalized['route'] = generate_page_route(
              @ast['module'],
              normalized['type']
            )
          end

          # Normalize components if present
          if normalized['components']
            normalized['components'] = normalize_components(normalized['components'])
          end

          normalized
        end
      end

      # Normalize component definitions
      def normalize_components(components)
        return [] unless components

        components.map do |component|
          normalized = component.dup
          normalized['config'] ||= {}
          normalized
        end
      end

      # Normalize API configuration
      def normalize_api(api_config)
        return nil unless api_config

        normalized = api_config.dup

        # Generate base_path if not provided
        unless normalized['base_path']
          model_name = @ast['model']['model']
          normalized['base_path'] = generate_api_base_path(model_name)
        end

        # Set defaults
        normalized['authentication'] = true if normalized['authentication'].nil?

        # Normalize endpoints
        if normalized['endpoints']
          normalized['endpoints'] = normalize_endpoints(normalized['endpoints'])
        else
          # Generate default CRUD endpoints
          normalized['endpoints'] = generate_default_endpoints
        end

        # Normalize rate limiting
        if normalized['rate_limit']
          normalized['rate_limit']['enabled'] = false if normalized['rate_limit']['enabled'].nil?
        end

        normalized
      end

      # Normalize endpoint definitions
      def normalize_endpoints(endpoints)
        endpoints.map do |endpoint|
          normalized = endpoint.dup

          # Normalize parameters
          if normalized['parameters']
            normalized['parameters'] = normalize_parameters(normalized['parameters'])
          end

          # Normalize strategy
          if normalized['strategy']
            normalized['strategy'] = normalize_strategy(normalized['strategy'])
          end

          # Normalize response
          if normalized['response']
            normalized['response']['type'] ||= 'json'
          end

          normalized
        end
      end

      # Normalize parameter definitions
      def normalize_parameters(parameters)
        parameters.map do |param|
          normalized = param.dup
          normalized['in'] ||= 'query'
          normalized['required'] = false if normalized['required'].nil?
          normalized
        end
      end

      # Normalize strategy reference
      def normalize_strategy(strategy)
        normalized = strategy.dup
        normalized['config'] ||= {}
        normalized
      end

      # Generate page route from module name and page type
      def generate_page_route(module_name, page_type)
        base_route = module_name.gsub(/([A-Z]+)([A-Z][a-z])/,'\1-\2').
          gsub(/([a-z\d])([A-Z])/,'\1-\2').
          downcase

        case page_type
        when 'list'
          "/#{base_route}"
        when 'form'
          "/#{base_route}/form"
        when 'detail'
          "/#{base_route}/:id"
        when 'dashboard'
          "/#{base_route}/dashboard"
        else
          "/#{base_route}/#{page_type}"
        end
      end

      # Generate API base path from model name
      def generate_api_base_path(model_name)
        collection_name = model_name.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          downcase

        # Pluralize
        collection_name = pluralize(collection_name)

        "/api/#{collection_name}"
      end

      # Simple pluralization
      def pluralize(word)
        return word + 'es' if word.end_with?('s', 'x', 'z', 'ch', 'sh')
        return word[0..-2] + 'ies' if word.end_with?('y') && !%w[a e i o u].include?(word[-2])
        word + 's'
      end

      # Generate default CRUD endpoints
      def generate_default_endpoints
        [
          {
            'method' => 'GET',
            'path' => '/',
            'action' => 'list',
            'description' => 'List all records',
            'parameters' => [
              {'name' => 'page', 'type' => 'integer', 'in' => 'query', 'default' => 1},
              {'name' => 'page_size', 'type' => 'integer', 'in' => 'query', 'default' => 20}
            ],
            'strategy' => {'action' => 'query', 'context' => 'paginated'}
          },
          {
            'method' => 'POST',
            'path' => '/',
            'action' => 'create',
            'description' => 'Create a new record',
            'strategy' => {'action' => 'save', 'context' => 'normal'}
          },
          {
            'method' => 'GET',
            'path' => '/:id',
            'action' => 'show',
            'description' => 'Get a single record',
            'parameters' => [
              {'name' => 'id', 'type' => 'string', 'in' => 'path', 'required' => true}
            ],
            'strategy' => {'action' => 'query', 'context' => 'default'}
          },
          {
            'method' => 'PUT',
            'path' => '/:id',
            'action' => 'update',
            'description' => 'Update a record',
            'parameters' => [
              {'name' => 'id', 'type' => 'string', 'in' => 'path', 'required' => true}
            ],
            'strategy' => {'action' => 'save', 'context' => 'normal'}
          },
          {
            'method' => 'DELETE',
            'path' => '/:id',
            'action' => 'delete',
            'description' => 'Delete a record',
            'parameters' => [
              {'name' => 'id', 'type' => 'string', 'in' => 'path', 'required' => true}
            ],
            'strategy' => {'action' => 'delete', 'context' => 'soft'}
          }
        ]
      end
    end
  end
end
