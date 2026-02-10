# Tahe DSL Validator

require 'json'
require 'json-schema'

module Tahe
  module DSL
    class Validator
      SCHEMA_DIR = File.expand_path('../schema', __dir__)

      # Schema文件映射
      SCHEMAS = {
        component_dsl: 'ui/component_dsl_schema.json',
        grid_dsl: 'ui/grid_dsl_schema.json',
        model_dsl: 'model/model_dsl_schema.json',
        module_dsl: 'module/module_dsl_schema.json',
        strategy_config: 'strategy/strategy_config_schema.json'
      }.freeze

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(format_errors(errors))
        end

        private

        def format_errors(errors)
          errors.map { |e| "  - #{e}" }.join("\n")
        end
      end

      # 验证DSL文件
      def self.validate_file(file_path, schema_type = nil)
        content = File.read(file_path)
        schema_type ||= detect_schema_type(file_path, content)

        case schema_type
        when :component_dsl, :grid_dsl
          validate_krdsl(content, schema_type)
        when :model_dsl
          validate_krmodel(content)
        when :module_dsl
          validate_krmodule(content)
        when :strategy_config
          validate_strategy_yaml(content)
        else
          raise ArgumentError, "Unknown schema type: #{schema_type}"
        end
      end

      # 验证JSON对象
      def self.validate_json(data, schema_type)
        schema = load_schema(schema_type)
        errors = JSON::Validator.fully_validate(schema, data)

        if errors.any?
          raise ValidationError.new(errors)
        end

        true
      end

      # 验证.krdsl文件（Component或Grid DSL）
      def self.validate_krdsl(content, schema_type)
        # 将DSL解析为JSON
        parser = schema_type == :component_dsl ? ComponentParser : GridParser
        data = parser.parse(content)

        validate_json(data, schema_type)
      end

      # 验证.krmodel文件
      def self.validate_krmodel(content)
        data = JSON.parse(content)
        validate_json(data, :model_dsl)
      end

      # 验证.krmodule文件
      def self.validate_krmodule(content)
        data = JSON.parse(content)
        validate_json(data, :module_dsl)
      end

      # 验证strategy.yaml
      def self.validate_strategy_yaml(content)
        require 'yaml'
        data = YAML.safe_load(content)
        validate_json(data, :strategy_config)
      end

      # 检测Schema类型
      def self.detect_schema_type(file_path, content)
        case File.extname(file_path)
        when '.krmodel'
          :model_dsl
        when '.krmodule'
          :module_dsl
        when '.krdsl'
          # 根据内容判断是Component还是Grid DSL
          if content.include?('grid ') && content.include?('item ')
            :grid_dsl
          else
            :component_dsl
          end
        when '.yaml', '.yml'
          if file_path.include?('strategy')
            :strategy_config
          end
        else
          nil
        end
      end

      # 加载Schema文件
      def self.load_schema(schema_type)
        schema_file = SCHEMAS[schema_type]
        raise ArgumentError, "Unknown schema type: #{schema_type}" unless schema_file

        schema_path = File.join(SCHEMA_DIR, schema_file)
        JSON.parse(File.read(schema_path))
      end

      # 批量验证目录下的所有DSL文件
      def self.validate_directory(dir_path, options = {})
        results = {
          valid: [],
          invalid: []
        }

        patterns = options[:patterns] || ['**/*.krdsl', '**/*.krmodel', '**/*.krmodule']

        patterns.each do |pattern|
          Dir.glob(File.join(dir_path, pattern)).each do |file|
            begin
              validate_file(file)
              results[:valid] << file
              puts "✓ #{file}" if options[:verbose]
            rescue ValidationError => e
              results[:invalid] << {file: file, errors: e.errors}
              puts "✗ #{file}" if options[:verbose]
              puts e.message if options[:verbose]
            end
          end
        end

        results
      end

      # 验证字段定义
      def self.validate_field(field_data)
        # 检查字段类型是否存在
        unless FieldRegistry.type_exists?(field_data['type'])
          raise ValidationError.new(["Unknown field type: #{field_data['type']}"])
        end

        # 检查关联字段的目标模型是否存在
        if field_data['type'].include?('relation')
          target = field_data.dig('options', 'target')
          unless target && model_exists?(target)
            raise ValidationError.new(["Relation target model not found: #{target}"])
          end
        end

        true
      end

      # 验证策略配置
      def self.validate_strategy(strategy_data)
        # 检查策略类是否存在
        strategy_class = strategy_data['class']
        unless strategy_class && class_exists?(strategy_class)
          raise ValidationError.new(["Strategy class not found: #{strategy_class}"])
        end

        true
      end

      private

      def self.model_exists?(model_name)
        # 检查模型文件是否存在
        model_file = "models/#{model_name.underscore}.krmodel"
        File.exist?(model_file) || defined?(model_name.constantize)
      rescue
        false
      end

      def self.class_exists?(class_name)
        # 检查类是否存在
        class_name.constantize
        true
      rescue NameError
        false
      end
    end
  end
end
