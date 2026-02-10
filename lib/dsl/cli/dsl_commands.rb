# Tahe DSL CLI Commands

require 'thor'
require_relative '../validator/dsl_validator'
require_relative '../parser/model_parser'
require_relative '../parser/module_parser'
require_relative '../parser/component_parser'
require_relative '../parser/grid_parser'
require_relative '../generator/model_generator'
require_relative '../generator/api_generator'
require_relative '../generator/page_generator'
require_relative '../context/project_context'

module Tahe
  module DSL
    class CLI < Thor
      desc "validate FILE", "Validate a DSL file"
      option :type, type: :string, desc: "DSL type (model, component, grid, module, strategy)"
      option :verbose, type: :boolean, default: false, desc: "Show detailed validation errors"
      def validate(file)
        unless File.exist?(file)
          say "Error: File not found: #{file}", :red
          exit 1
        end

        begin
          schema_type = options[:type]&.to_sym || Validator.detect_schema_type(file, File.read(file))

          Validator.validate_file(file, schema_type)
          say "✓ #{file} is valid (#{schema_type})", :green
        rescue Validator::ValidationError => e
          say "✗ #{file} validation failed:", :red
          if options[:verbose]
            say e.message, :red
          else
            say "  #{e.errors.first}", :red
            say "  (Use --verbose to see all errors)", :yellow
          end
          exit 1
        rescue => e
          say "Error: #{e.message}", :red
          exit 1
        end
      end

      desc "validate-dir DIR", "Validate all DSL files in a directory"
      option :patterns, type: :array, default: ['**/*.krdsl', '**/*.krmodel', '**/*.krmodule'], desc: "File patterns to validate"
      option :verbose, type: :boolean, default: false, desc: "Show detailed output"
      def validate_dir(dir)
        unless Dir.exist?(dir)
          say "Error: Directory not found: #{dir}", :red
          exit 1
        end

        results = Validator.validate_directory(dir, patterns: options[:patterns], verbose: options[:verbose])

        say "\nValidation Results:", :bold
        say "  Valid files: #{results[:valid].length}", :green
        say "  Invalid files: #{results[:invalid].length}", :red

        if results[:invalid].any?
          say "\nInvalid files:", :red
          results[:invalid].each do |result|
            say "  - #{result[:file]}", :red
            if options[:verbose]
              result[:errors].each do |error|
                say "    #{error}", :yellow
              end
            end
          end
          exit 1
        end
      end

      desc "generate TYPE FILE", "Generate code from DSL file"
      option :output, type: :string, desc: "Output directory"
      option :force, type: :boolean, default: false, desc: "Overwrite existing files"
      def generate(type, file)
        unless File.exist?(file)
          say "Error: File not found: #{file}", :red
          exit 1
        end

        begin
          case type
          when 'model'
            generate_model(file)
          when 'api'
            generate_api(file)
          when 'page'
            generate_page(file)
          when 'module'
            generate_module(file)
          when 'all'
            generate_all(file)
          else
            say "Error: Unknown generation type: #{type}", :red
            say "Valid types: model, api, page, module, all", :yellow
            exit 1
          end
        rescue => e
          say "Error: #{e.message}", :red
          say e.backtrace.first(5).join("\n"), :yellow if options[:verbose]
          exit 1
        end
      end

      desc "context", "Generate project context for AI"
      option :output, type: :string, desc: "Output file path"
      option :compact, type: :boolean, default: false, desc: "Generate compact format"
      option :summary, type: :boolean, default: false, desc: "Show summary only"
      def context
        begin
          context = ProjectContext.new('.')

          if options[:summary]
            say context.summary
          elsif options[:output]
            context.export_to_file(options[:output], compact: options[:compact])
            say "Context exported to: #{options[:output]}", :green
          else
            json = ProjectContext.to_json('.', compact: options[:compact])
            say json
          end
        rescue => e
          say "Error: #{e.message}", :red
          exit 1
        end
      end

      desc "parse FILE", "Parse DSL file and show AST"
      option :format, type: :string, default: 'json', desc: "Output format (json, yaml)"
      def parse(file)
        unless File.exist?(file)
          say "Error: File not found: #{file}", :red
          exit 1
        end

        begin
          content = File.read(file)
          ext = File.extname(file)

          ast = case ext
          when '.krmodel'
            ModelParser.parse(content)
          when '.krmodule'
            ModuleParser.parse(content)
          when '.krdsl'
            if content.include?('grid ') && content.include?('item ')
              GridParser.parse(content)
            else
              ComponentParser.parse(content)
            end
          else
            say "Error: Unknown file type: #{ext}", :red
            exit 1
          end

          output = case options[:format]
          when 'yaml'
            require 'yaml'
            YAML.dump(ast)
          else
            require 'json'
            JSON.pretty_generate(ast)
          end

          say output
        rescue => e
          say "Error: #{e.message}", :red
          exit 1
        end
      end

      desc "new TYPE NAME", "Create a new DSL file from template"
      option :fields, type: :array, desc: "Model fields (name:type format)"
      option :output, type: :string, desc: "Output directory"
      def new(type, name)
        begin
          case type
          when 'model'
            create_model_template(name)
          when 'page'
            create_page_template(name)
          when 'module'
            create_module_template(name)
          else
            say "Error: Unknown type: #{type}", :red
            say "Valid types: model, page, module", :yellow
            exit 1
          end
        rescue => e
          say "Error: #{e.message}", :red
          exit 1
        end
      end

      desc "list TYPE", "List all DSL files of a type"
      option :details, type: :boolean, default: false, desc: "Show detailed information"
      def list(type)
        begin
          case type
          when 'models'
            list_models
          when 'pages'
            list_pages
          when 'modules'
            list_modules
          when 'all'
            list_models
            say ""
            list_pages
            say ""
            list_modules
          else
            say "Error: Unknown type: #{type}", :red
            say "Valid types: models, pages, modules, all", :yellow
            exit 1
          end
        rescue => e
          say "Error: #{e.message}", :red
          exit 1
        end
      end

      desc "version", "Show DSL version"
      def version
        say "Tahe DSL v0.1.0", :green
      end

      private

      def generate_model(file)
        output_dir = options[:output] || 'app/models'
        result = ModelGenerator.generate_from_file(file, output_dir)
        say "✓ Generated model: #{result}", :green
      end

      def generate_api(file)
        output_dir = options[:output] || 'app/api'
        result = ApiGenerator.generate_from_file(file, output_dir)
        say "✓ Generated API files:", :green
        say "  - Routes: #{result[:routes]}", :green
        say "  - Controller: #{result[:controller]}", :green
        say "  - Serializer: #{result[:serializer]}", :green
      end

      def generate_page(file)
        output_dir = options[:output] || 'app/views'
        result = PageGenerator.generate_from_file(file, output_dir)
        say "✓ Generated page: #{result}", :green
      end

      def generate_module(file)
        module_data = ModuleParser.parse_file(file)

        # Generate model
        model_output = options[:output] ? File.join(options[:output], 'models') : 'app/models'
        ModelGenerator.generate_from_model(module_data['model'], model_output)

        # Generate API
        api_output = options[:output] ? File.join(options[:output], 'api') : 'app/api'
        ApiGenerator.generate_from_module(module_data, api_output)

        # Generate pages
        page_output = options[:output] ? File.join(options[:output], 'views') : 'app/views'
        # TODO: Generate pages from module definition

        say "✓ Generated module: #{module_data['module']}", :green
      end

      def generate_all(file)
        ext = File.extname(file)

        case ext
        when '.krmodel'
          generate_model(file)
          generate_api(file)
        when '.krmodule'
          generate_module(file)
        when '.krdsl'
          generate_page(file)
        else
          say "Error: Cannot generate from file type: #{ext}", :red
          exit 1
        end
      end

      def create_model_template(name)
        require_relative '../utils'
        model_name = Tahe::DSL::Utils::StringHelpers.camelize(name)
        collection_name = Tahe::DSL::Utils::StringHelpers.pluralize(
          Tahe::DSL::Utils::StringHelpers.underscore(name)
        )

        fields = options[:fields] || ['name:text']
        field_definitions = fields.map do |field_spec|
          field_name, field_type = field_spec.split(':')
          {
            name: field_name,
            type: field_type || 'text',
            label: field_name.capitalize,
            required: false
          }
        end

        template = {
          model: model_name,
          collection: collection_name,
          description: "#{model_name} model",
          timestamps: true,
          soft_delete: false,
          fields: field_definitions,
          strategies: [
            {action: 'save', context: 'normal'},
            {action: 'query', context: 'paginated'},
            {action: 'delete', context: 'soft'}
          ]
        }

        output_dir = options[:output] || 'models'
        FileUtils.mkdir_p(output_dir)

        output_file = File.join(output_dir, "#{Tahe::DSL::Utils::StringHelpers.underscore(name)}.krmodel")

        File.write(output_file, JSON.pretty_generate(template))
        say "✓ Created model template: #{output_file}", :green
      end

      def create_page_template(name)
        require_relative '../utils'
        page_name = name.gsub('_', ' ').split.map(&:capitalize).join(' ')

        template = <<~DSL
          page "#{page_name}"
          layout admin
          theme default

          # CRUD Panel
          component crud_panel
            title: "#{page_name}"
            api_base: "/api/#{Tahe::DSL::Utils::StringHelpers.pluralize(Tahe::DSL::Utils::StringHelpers.underscore(name))}"
            columns: [
              {type: "checkbox", fixed: "left"},
              {field: "id", title: "ID", width: 80, sort: true},
              {field: "name", title: "名称", width: 200},
              {field: "created_at", title: "创建时间", width: 180},
              {fixed: "right", title: "操作", width: 150, toolbar: "#rowTools"}
            ]
        DSL

        output_dir = options[:output] || 'pages'
        FileUtils.mkdir_p(output_dir)

        output_file = File.join(output_dir, "#{Tahe::DSL::Utils::StringHelpers.underscore(name)}.krdsl")

        File.write(output_file, template)
        say "✓ Created page template: #{output_file}", :green
      end

      def create_module_template(name)
        require_relative '../utils'
        model_name = Tahe::DSL::Utils::StringHelpers.camelize(name)
        module_name = "#{model_name}Management"

        template = {
          module: module_name,
          description: "#{model_name} management module",
          model: {
            model: model_name,
            collection: Tahe::DSL::Utils::StringHelpers.pluralize(
              Tahe::DSL::Utils::StringHelpers.underscore(name)
            ),
            timestamps: true,
            soft_delete: true,
            fields: [
              {name: 'name', type: 'text', label: '名称', required: true}
            ],
            strategies: [
              {action: 'save', context: 'normal'},
              {action: 'query', context: 'paginated'},
              {action: 'delete', context: 'soft'}
            ]
          },
          pages: [
            {name: "#{model_name}列表", type: 'list', layout: 'admin'},
            {name: "#{model_name}表单", type: 'form', layout: 'default'}
          ],
          api: {
            authentication: true
          }
        }

        output_dir = options[:output] || 'modules'
        module_dir = File.join(output_dir, Tahe::DSL::Utils::StringHelpers.underscore(module_name))
        FileUtils.mkdir_p(module_dir)

        output_file = File.join(module_dir, "#{Tahe::DSL::Utils::StringHelpers.underscore(module_name)}.krmodule")

        File.write(output_file, JSON.pretty_generate(template))
        say "✓ Created module template: #{output_file}", :green
      end

      def list_models
        models = Dir.glob('models/**/*.krmodel')

        say "Models (#{models.length}):", :bold

        if models.empty?
          say "  No models found", :yellow
          return
        end

        models.each do |file|
          if options[:details]
            model_data = ModelParser.parse_file(file)
            say "  - #{model_data['model']} (#{file})", :green
            say "    Collection: #{model_data['collection']}", :cyan
            say "    Fields: #{model_data['fields'].length}", :cyan
          else
            say "  - #{file}", :green
          end
        end
      end

      def list_pages
        pages = Dir.glob('pages/**/*.krdsl')

        say "Pages (#{pages.length}):", :bold

        if pages.empty?
          say "  No pages found", :yellow
          return
        end

        pages.each do |file|
          if options[:details]
            content = File.read(file)
            if content.include?('grid ')
              type = 'grid'
            else
              type = 'component'
            end
            say "  - #{file} (#{type})", :green
          else
            say "  - #{file}", :green
          end
        end
      end

      def list_modules
        modules = Dir.glob('modules/**/*.krmodule')

        say "Modules (#{modules.length}):", :bold

        if modules.empty?
          say "  No modules found", :yellow
          return
        end

        modules.each do |file|
          if options[:details]
            module_data = ModuleParser.parse_file(file)
            say "  - #{module_data['module']} (#{file})", :green
            say "    Model: #{module_data['model']['model']}", :cyan
            say "    Pages: #{module_data['pages']&.length || 0}", :cyan
          else
            say "  - #{file}", :green
          end
        end
      end
    end
  end
end
