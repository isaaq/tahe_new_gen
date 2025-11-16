# KR 布局解析器
# 解析JSON格式的布局文件，提取布局信息

require 'json'

class KrLayoutParser
  
  def self.parse_file(file_path)
    content = File.read(file_path)
    parse(content)
  end
  
  def self.parse(content)
    parser = new
    parser.parse(content)
  end
  
  def initialize
    @layout_config = {
      columns: 12,
      cellHeight: 60,
      margin: 10,
      items: []
    }
  end
  
  def parse(content)
    # 解析JSON格式的布局文件
    begin
      json_data = JSON.parse(content)
      
      # 提取全局配置
      @layout_config[:title] = json_data['title'] if json_data['title']
      @layout_config[:description] = json_data['description'] if json_data['description']
      @layout_config[:columns] = json_data['grid'] if json_data['grid']
      @layout_config[:cellHeight] = json_data['cell_height'] if json_data['cell_height']
      @layout_config[:margin] = json_data['margin'] if json_data['margin']
      @layout_config[:staticGrid] = json_data['static_grid'] if json_data.key?('static_grid')
      @layout_config[:disableDrag] = json_data['disable_drag'] if json_data.key?('disable_drag')
      @layout_config[:disableResize] = json_data['disable_resize'] if json_data.key?('disable_resize')
      @layout_config[:animate] = json_data['animate'] if json_data.key?('animate')
      
      # 提取网格项
      if json_data['sections'] && json_data['sections'].is_a?(Array)
        json_data['sections'].each do |section|
          section_name = section['name']
          
          if section['items'] && section['items'].is_a?(Array)
            section['items'].each do |item|
              @layout_config[:items] << {
                id: item['id'],
                x: item['x'] || 0,
                y: item['y'] || 0,
                w: item['w'] || 1,
                h: item['h'] || 1,
                section: section_name,
                css_class: item['css_class'] || '',
                resizable: item['resizable'] != false,
                draggable: item['draggable'] != false
              }
            end
          end
        end
      end
      
    rescue JSON::ParserError => e
      puts "JSON解析错误: #{e.message}"
    end
    
    @layout_config
  end
end
