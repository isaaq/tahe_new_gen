# KR 网格布局 DSL 解析器
# 简洁的网格布局描述，内容区域挂载 KR 标签

class KrGridDsl
  
  def self.parse(dsl_content)
    parser = new
    parser.parse(dsl_content)
  end
  
  def initialize
    @grid_config = {
      columns: 12,
      cellHeight: 60,
      margin: 10,
      items: []
    }
  end
  
  def parse(dsl_content)
    # 使用更智能的解析方式，支持多行内容
    content = dsl_content.strip
    
    # 解析全局配置
    content.scan(/^(grid|cell_height|margin)\s+(\d+)\s*$/m) do |key, value|
      case key
      when 'grid'
        @grid_config[:columns] = value.to_i
      when 'cell_height'
        @grid_config[:cellHeight] = value.to_i
      when 'margin'
        @grid_config[:margin] = value.to_i
      end
    end
    
    # 解析item块，支持多行内容
    content.scan(/^item\s+([^{]+)\{([^}]*)\}/m) do |attributes, content_block|
      parse_item_with_content(attributes.strip, content_block.strip)
    end
    
    @grid_config
  end
  
  private
  
  def parse_item_with_content(attributes_part, content_part)
    # 解析item属性和内容
    item = {
      id: extract_attribute(attributes_part, 'id'),
      x: extract_attribute(attributes_part, 'x')&.to_i || 0,
      y: extract_attribute(attributes_part, 'y')&.to_i || 0,
      w: extract_attribute(attributes_part, 'w')&.to_i || 1,
      h: extract_attribute(attributes_part, 'h')&.to_i || 1,
      content: content_part,
      css_class: extract_attribute(attributes_part, 'class') || '',
      resizable: extract_attribute(attributes_part, 'resizable') != 'false',
      draggable: extract_attribute(attributes_part, 'draggable') != 'false'
    }
    
    @grid_config[:items] << item
  end
  
  def extract_attribute(text, attr_name)
    match = text.match(/#{attr_name}=["']?([^"'\s]+)["']?/)
    match ? match[1] : nil
  end
end
