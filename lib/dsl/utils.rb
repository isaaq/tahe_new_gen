# Tahe DSL Utilities

module Tahe
  module DSL
    module Utils
      # String manipulation utilities
      module StringHelpers
        # Convert PascalCase/camelCase to snake_case
        def self.underscore(str)
          str.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
            gsub(/([a-z\d])([A-Z])/,'\1_\2').
            tr("-", "_").
            downcase
        end

        # Convert snake_case to PascalCase
        def self.camelize(str)
          str.split('_').map(&:capitalize).join
        end

        # Convert snake_case to camelCase
        def self.camel_case(str)
          parts = str.split('_')
          parts[0] + parts[1..-1].map(&:capitalize).join
        end

        # Convert PascalCase/snake_case to kebab-case
        def self.dasherize(str)
          underscore(str).tr('_', '-')
        end

        # Simple pluralization
        def self.pluralize(word)
          return word + 'es' if word.end_with?('s', 'x', 'z', 'ch', 'sh')
          return word[0..-2] + 'ies' if word.end_with?('y') && !%w[a e i o u].include?(word[-2])
          word + 's'
        end

        # Simple singularization
        def self.singularize(word)
          return word[0..-3] if word.end_with?('ies')
          return word[0..-3] if word.end_with?('ses', 'xes', 'zes')
          return word[0..-4] if word.end_with?('ches', 'shes')
          return word[0..-2] if word.end_with?('s') && !word.end_with?('ss')
          word
        end
      end

      # File path utilities
      module PathHelpers
        # Generate model file path
        def self.model_path(model_name)
          "models/#{StringHelpers.underscore(model_name)}.krmodel"
        end

        # Generate page file path
        def self.page_path(page_name)
          "pages/#{StringHelpers.underscore(page_name)}.krdsl"
        end

        # Generate module directory path
        def self.module_dir(module_name)
          "modules/#{StringHelpers.underscore(module_name)}"
        end

        # Generate module file path
        def self.module_path(module_name)
          "#{module_dir(module_name)}/#{StringHelpers.underscore(module_name)}.krmodule"
        end

        # Generate API base path
        def self.api_base_path(model_name)
          collection = StringHelpers.pluralize(StringHelpers.underscore(model_name))
          "/api/#{collection}"
        end

        # Generate page route
        def self.page_route(module_name, page_type = nil)
          base = "/#{StringHelpers.dasherize(module_name)}"
          return base unless page_type

          case page_type
          when 'list'
            base
          when 'form'
            "#{base}/form"
          when 'detail'
            "#{base}/:id"
          else
            "#{base}/#{page_type}"
          end
        end
      end

      # Naming convention utilities
      module NamingHelpers
        # Generate collection name from model name
        def self.collection_name(model_name)
          StringHelpers.pluralize(StringHelpers.underscore(model_name))
        end

        # Generate model class name from collection name
        def self.model_name(collection_name)
          StringHelpers.camelize(StringHelpers.singularize(collection_name))
        end

        # Generate strategy class name
        def self.strategy_class_name(domain, action, context)
          domain_class = StringHelpers.camelize(domain)
          action_class = StringHelpers.camelize(action)
          context_class = StringHelpers.camelize(context)

          "Plugins::Strategy::#{action_class}::#{context_class}Strategy"
        end

        # Generate controller name from model name
        def self.controller_name(model_name)
          "#{StringHelpers.pluralize(model_name)}Controller"
        end

        # Generate API endpoint name
        def self.endpoint_name(model_name, action)
          collection = StringHelpers.pluralize(StringHelpers.underscore(model_name))
          "#{action}_#{collection}"
        end
      end

      # JSON/YAML parsing utilities
      module ParserHelpers
        # Safe JSON parse
        def self.parse_json(content)
          require 'json'
          JSON.parse(content)
        rescue JSON::ParserError => e
          raise ParseError.new("Invalid JSON: #{e.message}")
        end

        # Safe YAML parse
        def self.parse_yaml(content)
          require 'yaml'
          YAML.safe_load(content)
        rescue Psych::SyntaxError => e
          raise ParseError.new("Invalid YAML: #{e.message}")
        end

        # Parse value from string (safe alternative to eval)
        def self.parse_value(value_str)
          value_str = value_str.strip

          # JSON array or object
          if (value_str.start_with?('[') && value_str.end_with?(']')) ||
             (value_str.start_with?('{') && value_str.end_with?('}'))
            begin
              return parse_json(value_str)
            rescue ParseError
              # Fall through to other parsing methods
            end
          end

          # String (quoted)
          if value_str.start_with?('"') && value_str.end_with?('"')
            return value_str[1..-2]
          end

          if value_str.start_with?("'") && value_str.end_with?("'")
            return value_str[1..-2]
          end

          # Number (integer)
          if value_str =~ /^-?\d+$/
            return value_str.to_i
          end

          # Number (float)
          if value_str =~ /^-?\d+\.\d+$/
            return value_str.to_f
          end

          # Boolean
          return true if value_str == 'true'
          return false if value_str == 'false'

          # Null/nil
          return nil if value_str == 'null' || value_str == 'nil'

          # Default: return as string
          value_str
        end

        class ParseError < StandardError; end
      end

      # Template rendering utilities
      module TemplateHelpers
        # Render template with variables
        def self.render(template, variables = {})
          result = template.dup

          variables.each do |key, value|
            placeholder = "{{#{key}}}"
            result.gsub!(placeholder, value.to_s)
          end

          result
        end

        # Load template from file
        def self.load_template(template_path)
          File.read(template_path)
        end

        # Render template file
        def self.render_file(template_path, variables = {})
          template = load_template(template_path)
          render(template, variables)
        end
      end

      # Validation utilities
      module ValidationHelpers
        # Validate field name (snake_case)
        def self.valid_field_name?(name)
          name =~ /^[a-z_][a-z0-9_]*$/
        end

        # Validate model name (PascalCase)
        def self.valid_model_name?(name)
          name =~ /^[A-Z][a-zA-Z0-9]*$/
        end

        # Validate collection name (snake_case)
        def self.valid_collection_name?(name)
          name =~ /^[a-z_][a-z0-9_]*$/
        end

        # Validate API path
        def self.valid_api_path?(path)
          path =~ /^\/[a-z0-9\/_:-]*$/
        end

        # Validate route path
        def self.valid_route_path?(path)
          path =~ /^\/[a-z0-9\/_:-]*$/
        end
      end
    end
  end
end
