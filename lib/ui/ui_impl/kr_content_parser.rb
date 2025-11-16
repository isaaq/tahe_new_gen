# KR 内容解析器
# 解析XML格式的内容文件，提取带有layout属性的KR标签

require 'nokogiri'

class KrContentParser
  
  def self.parse_file(file_path)
    content = File.read(file_path)
    parse(content)
  end
  
  def self.parse(content)
    parser = new
    parser.parse(content)
  end
  
  def initialize
    @content_map = {}
  end
  
  def parse(content)
    # 解析XML格式的内容文件
    begin
      doc = Nokogiri::XML(content)
      
      # 查找所有带有layout属性的节点
      doc.xpath('//*[@layout]').each do |node|
        layout_id = node['layout']
        next unless layout_id
        
        # 提取节点内容
        @content_map[layout_id] = node.to_s
      end
      
    rescue => e
      puts "XML解析错误: #{e.message}"
    end
    
    @content_map
  end
end
