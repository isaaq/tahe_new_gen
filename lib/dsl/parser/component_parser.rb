# Tahe DSL Parser - Component DSL Parser

module Tahe
  module DSL
    class ComponentParser
      attr_reader :content, :ast

      def initialize(content)
        @content = content
        @ast = {
          'page' => nil,
          'layout' => 'default',
          'theme' => 'default',
          'model' => nil,
          'components' => []
        }
      end

      def self.parse(content)
        parser = new(content)
        parser.parse
        parser.ast
      end

      def parse
        lines = @content.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }

        current_component = nil
        indent_stack = []

        lines.each do |line|
          indent = line[/\A */].size
          line = line.strip

          case line
          when /^page\s+"(.+)"$/
            @ast['page'] = $1
          when /^layout\s+(\w+)$/
            @ast['layout'] = $1
          when /^theme\s+(\w+)$/
            @ast['theme'] = $1
          when /^model\s+(\w+)$/
            @ast['model'] = $1
          when /^component\s+(\w+)$/
            current_component = {
              'type' => $1,
              'config' => {}
            }
            @ast['components'] << current_component
          when /^(\w+):\s*(.+)$/
            # 配置项
            key = $1
            value = parse_value($2)
            current_component['config'][key] = value if current_component
          end
        end

        self
      end

      private

      def parse_value(value_str)
        value_str = value_str.strip

        # 数组 - 使用JSON解析代替eval
        if value_str.start_with?('[') && value_str.end_with?(']')
          begin
            require 'json'
            return JSON.parse(value_str)
          rescue JSON::ParserError
            # 如果JSON解析失败，尝试简单的数组解析
            return parse_simple_array(value_str)
          end
        end

        # 字符串
        if value_str.start_with?('"') && value_str.end_with?('"')
          return value_str[1..-2]
        end

        # 数字
        if value_str =~ /^\d+$/
          return value_str.to_i
        end

        # 浮点数
        if value_str =~ /^\d+\.\d+$/
          return value_str.to_f
        end

        # 布尔值
        return true if value_str == 'true'
        return false if value_str == 'false'

        # null/nil
        return nil if value_str == 'null' || value_str == 'nil'

        # 默认返回字符串
        value_str
      end

      # 解析简单数组格式 (不使用eval)
      def parse_simple_array(array_str)
        # 移除首尾的方括号
        content = array_str[1..-2].strip
        return [] if content.empty?

        # 简单分割（不处理嵌套）
        elements = content.split(',').map(&:strip)

        # 解析每个元素
        elements.map { |elem| parse_value(elem) }
      end
    end
  end
end
