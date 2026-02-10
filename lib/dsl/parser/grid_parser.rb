# Tahe DSL Parser - Grid DSL Parser

module Tahe
  module DSL
    class GridParser
      attr_reader :content, :ast

      def initialize(content)
        @content = content
        @ast = {
          'title' => nil,
          'description' => nil,
          'grid' => 12,
          'cell_height' => 80,
          'margin' => 10,
          'static_grid' => false,
          'disable_drag' => false,
          'disable_resize' => false,
          'animate' => true,
          'sections' => [],
          'items' => []
        }
      end

      def self.parse(content)
        parser = new(content)
        parser.parse
        parser.ast
      end

      def parse
        lines = @content.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }

        current_section = nil
        current_item = nil
        in_item_content = false
        item_content_buffer = []

        lines.each do |line|
          case line
          when /^title\s+"(.+)"$/
            @ast['title'] = $1
          when /^description\s+"(.+)"$/
            @ast['description'] = $1
          when /^grid\s+(\d+)$/
            @ast['grid'] = $1.to_i
          when /^cell_height\s+(\d+)$/
            @ast['cell_height'] = $1.to_i
          when /^margin\s+(\d+)$/
            @ast['margin'] = $1.to_i
          when /^static_grid\s+(true|false)$/
            @ast['static_grid'] = $1 == 'true'
          when /^disable_drag\s+(true|false)$/
            @ast['disable_drag'] = $1 == 'true'
          when /^disable_resize\s+(true|false)$/
            @ast['disable_resize'] = $1 == 'true'
          when /^animate\s+(true|false)$/
            @ast['animate'] = $1 == 'true'
          when /^section\s+"(.+)"$/
            current_section = {'name' => $1}
            @ast['sections'] << current_section
          when /^item\s+id="(\w+)"\s+x=(\d+)\s+y=(\d+)\s+w=(\d+)\s+h=(\d+)\s+\{$/
            # 保存之前的item
            if current_item && in_item_content
              current_item['content'] = item_content_buffer.join("\n")
              item_content_buffer = []
            end

            current_item = {
              'id' => $1,
              'x' => $2.to_i,
              'y' => $3.to_i,
              'w' => $4.to_i,
              'h' => $5.to_i
            }
            @ast['items'] << current_item
            in_item_content = true
          when /^\}$/
            # item结束
            if current_item && in_item_content
              current_item['content'] = item_content_buffer.join("\n").strip
              item_content_buffer = []
              in_item_content = false
            end
          else
            # item内容
            if in_item_content
              item_content_buffer << line
            end
          end
        end

        # 处理最后一个item
        if current_item && in_item_content && item_content_buffer.any?
          current_item['content'] = item_content_buffer.join("\n").strip
        end

        self
      end
    end
  end
end
