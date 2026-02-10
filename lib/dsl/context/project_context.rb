# Tahe DSL Context - Project Context Provider

require 'json'
require 'yaml'
require_relative '../utils'

module Tahe
  module DSL
    class ProjectContext
      include Utils::StringHelpers
      include Utils::PathHelpers

      attr_reader :project_root

      def initialize(project_root = '.')
        @project_root = File.expand_path(project_root)
      end

      # Generate complete project context
      def self.generate(project_root = '.')
        context = new(project_root)
        context.generate
      end

      # Generate context as JSON
      def self.to_json(project_root = '.', compact: false)
        context = generate(project_root)

        if compact
          JSON.generate(context)
        else
          JSON.pretty_generate(context)
        end
      end

      # Generate context
      def generate
        {
          project: project_info,
          models: load_models,
          pages: load_pages,
          modules: load_modules,
          available_field_types: available_field_types,
          available_strategies: available_strategies,
          available_components: available_components,
          conventions: conventions
        }
      end

      # Project information
      def project_info
        {
          name: project_name,
          framework: 'Tahe',
          version: tahe_version,
          database: 'MongoDB',
          ui_framework: 'Layui',
          root: @project_root
        }
      end

      # Load all models
      def load_models
        model_files = Dir.glob(File.join(@project_root, 'models/**/*.krmodel'))

        model_files.map do |file|
          begin
            require_relative '../parser/model_parser'
            model_data = ModelParser.parse_file(file)

            {
              name: model_data['model'],
              collection: model_data['collection'],
              file: relative_path(file),
              fields: extract_field_summary(model_data['fields']),
              field_count: model_data['fields']&.length || 0,
              has_timestamps: model_data['timestamps'],
              has_soft_delete: model_data['soft_delete']
            }
          rescue => e
            puts "[Warning] Failed to parse model file #{file}: #{e.message}"
            nil
          end
        end.compact
      end

      # Load all pages
      def load_pages
        page_files = Dir.glob(File.join(@project_root, 'pages/**/*.krdsl'))

        page_files.map do |file|
          begin
            content = File.read(file)

            # Detect page type
            if content.include?('grid ') && content.include?('item ')
              type = 'grid'
              title = extract_grid_title(content)
            else
              type = 'component'
              title = extract_component_title(content)
            end

            {
              name: title || File.basename(file, '.krdsl'),
              type: type,
              file: relative_path(file),
              route: guess_route_from_filename(file)
            }
          rescue => e
            puts "[Warning] Failed to parse page file #{file}: #{e.message}"
            nil
          end
        end.compact
      end

      # Load all modules
      def load_modules
        module_files = Dir.glob(File.join(@project_root, 'modules/**/*.krmodule'))

        module_files.map do |file|
          begin
            require_relative '../parser/module_parser'
            module_data = ModuleParser.parse_file(file)

            {
              name: module_data['module'],
              description: module_data['description'],
              file: relative_path(file),
              model: module_data['model']['model'],
              pages_count: module_data['pages']&.length || 0,
              api_base: module_data['api']&.dig('base_path')
            }
          rescue => e
            puts "[Warning] Failed to parse module file #{file}: #{e.message}"
            nil
          end
        end.compact
      end

      # Available field types
      def available_field_types
        [
          # Basic types
          'text', 'textarea', 'number', 'boolean', 'date', 'time', 'datetime',

          # Special types
          'enum', 'file', 'image', 'json',

          # Business types
          'amount', 'email', 'phone', 'id_card', 'url',

          # Location types
          'address', 'coordinate', 'color',

          # Range types
          'number_range', 'date_range',

          # Relation types
          'single_relation', 'multiple_relation', 'tree_relation',

          # Rich content types
          'code_editor', 'markdown', 'rich_text',

          # Advanced types
          'encrypted', 'formula'
        ]
      end

      # Available strategies
      def available_strategies
        {
          save: ['draft', 'normal', 'async', 'batch', 'encrypted', 'version'],
          submit: ['publish', 'review', 'workflow'],
          query: ['default', 'paginated', 'cached', 'encrypted'],
          delete: ['soft', 'hard', 'cascade', 'archive'],
          validate: ['form', 'data', 'business'],
          notification: ['email', 'sms', 'webhook'],
          permission: ['role', 'field', 'data'],
          search: ['default', 'global', 'fuzzy'],
          workflow: ['approval', 'state_machine']
        }
      end

      # Available UI components
      def available_components
        [
          # Layout components
          'tree_table_layout',

          # Data components
          'search_table',
          'crud_panel',
          'table',

          # Form components
          'form',

          # Display components
          'chart',
          'card',
          'tabs',

          # Action components
          'toolbar',
          'button',
          'dialog',
          'drawer'
        ]
      end

      # Naming conventions
      def conventions
        {
          file_naming: 'snake_case',
          class_naming: 'PascalCase',
          field_naming: 'snake_case',
          collection_naming: 'snake_case_plural',
          api_base_path: '/api/{{model_plural}}',
          page_route: '/{{module_kebab}}',

          examples: {
            model_file: 'models/product.krmodel',
            model_class: 'Product',
            collection: 'products',
            api_path: '/api/products',
            page_file: 'pages/product_management.krdsl',
            page_route: '/product-management'
          }
        }
      end

      # Generate compact context (for token efficiency)
      def generate_compact
        {
          p: {
            n: project_name,
            f: 'Tahe',
            v: tahe_version
          },
          m: load_models.map { |m|
            {
              n: m[:name],
              c: m[:collection],
              fc: m[:field_count]
            }
          },
          pg: load_pages.map { |p|
            {
              n: p[:name],
              t: p[:type]
            }
          },
          ft: available_field_types.take(10), # Top 10 most common
          st: {
            save: available_strategies[:save].take(3),
            query: available_strategies[:query].take(3),
            delete: available_strategies[:delete].take(2)
          }
        }
      end

      # Export context to file
      def export_to_file(output_path, compact: false)
        context = compact ? generate_compact : generate

        File.write(output_path, JSON.pretty_generate(context))
        puts "Context exported to: #{output_path}"

        output_path
      end

      # Generate context summary (human-readable)
      def summary
        models = load_models
        pages = load_pages
        modules = load_modules

        <<~SUMMARY
          Project Context Summary
          =======================

          Project: #{project_name}
          Framework: Tahe #{tahe_version}
          Root: #{@project_root}

          Models: #{models.length}
          #{models.map { |m| "  - #{m[:name]} (#{m[:field_count]} fields)" }.join("\n")}

          Pages: #{pages.length}
          #{pages.map { |p| "  - #{p[:name]} (#{p[:type]})" }.join("\n")}

          Modules: #{modules.length}
          #{modules.map { |m| "  - #{m[:name]}" }.join("\n")}

          Available Field Types: #{available_field_types.length}
          Available Strategies: #{available_strategies.values.flatten.length}
          Available Components: #{available_components.length}
        SUMMARY
      end

      private

      # Get project name from directory or config
      def project_name
        # Try to read from config file
        config_file = File.join(@project_root, 'config', 'application.yml')
        if File.exist?(config_file)
          config = YAML.safe_load(File.read(config_file))
          return config['name'] if config['name']
        end

        # Fallback to directory name
        File.basename(@project_root)
      end

      # Get Tahe version
      def tahe_version
        version_file = File.join(@project_root, 'VERSION')
        if File.exist?(version_file)
          File.read(version_file).strip
        else
          '0.1.0'
        end
      end

      # Extract field summary
      def extract_field_summary(fields)
        return [] unless fields

        fields.map do |field|
          {
            name: field['name'],
            type: field['type'],
            required: field['required'] || false
          }
        end
      end

      # Extract component title from DSL
      def extract_component_title(content)
        match = content.match(/^page\s+"(.+)"/)
        match ? match[1] : nil
      end

      # Extract grid title from DSL
      def extract_grid_title(content)
        match = content.match(/^title\s+"(.+)"/)
        match ? match[1] : nil
      end

      # Guess route from filename
      def guess_route_from_filename(file)
        basename = File.basename(file, '.krdsl')
        "/#{Utils::StringHelpers.dasherize(basename)}"
      end

      # Get relative path from project root
      def relative_path(file)
        file.sub(@project_root + '/', '')
      end
    end
  end
end
