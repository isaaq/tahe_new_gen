# 网格布局演示
# 展示布局与内容分离的简洁方案
require_relative '../_system'
require_relative '../lib/util/common'
require_relative '../lib/ui/ui_impl/kr_grid_layout'
require_relative '../lib/ui/ui_impl/kr_grid_dsl'
require_relative '../lib/ui/ui_impl/kr_transformer'

class GridLayoutDemo
  def self.run
    puts "=== KR 网格布局演示 ==="
    
    # 1. 从DSL生成网格布局
    puts "\n1. 从DSL生成网格布局:"
    demo_dsl_parsing
    
    # 2. 直接配置生成
    puts "\n2. 直接配置生成网格:"
    demo_direct_config
    
    # 3. 展示设计器友好特性
    puts "\n3. 设计器友好特性:"
    demo_designer_features
  end
  
  def self.demo_dsl_parsing
    # 从DSL文件解析
    if File.exist?('demo/bidding_project_grid.krdsl')
      dsl_content = File.read('demo/bidding_project_grid.krdsl')
      grid_config = KrGridDsl.parse(dsl_content)
      
      puts "解析的网格配置:"
      puts "列数: #{grid_config[:columns]}"
      puts "单元格高度: #{grid_config[:cellHeight]}px"
      puts "网格项数量: #{grid_config[:items].length}"
      
      # 处理每个网格项中的KR标签
      grid_config[:items].each do |item|
        if item[:content] && !item[:content].empty?
          # 这里可以调用KrTransformer处理KR标签
          processed_content = process_kr_content(item[:content])
          item[:content] = processed_content
        end
      end
      
      # 生成最终HTML
      result = KrGridLayout.generate(grid_config)
      puts "\n生成的HTML结构:"
      puts result[:html][0..500] + "..."
      
      puts "\n生成的CSS样式:"
      puts result[:css][0..300] + "..."
    else
      puts "DSL文件不存在"
    end
  end
  
  def self.demo_direct_config
    # 直接通过配置生成
    config = {
      columns: 12,
      cellHeight: 80,
      margin: 10,
      items: [
        {
          id: 'form_section',
          x: 0, y: 0, w: 8, h: 4,
          content: '<kr:form><kr:input name="name" label="姓名" /></kr:form>'
        },
        {
          id: 'info_section', 
          x: 8, y: 0, w: 4, h: 4,
          content: '<kr:section title="信息"><kr:readonly_field name="status" label="状态" value="正常" /></kr:section>'
        },
        {
          id: 'table_section',
          x: 0, y: 4, w: 12, h: 3,
          content: '<kr:table source="/api/data" />'
        }
      ]
    }
    
    # 处理KR标签内容
    config[:items].each do |item|
      item[:content] = process_kr_content(item[:content])
    end
    
    result = KrGridLayout.generate(config)
    puts "直接配置生成的网格:"
    puts "网格项: #{config[:items].length} 个"
    puts "HTML长度: #{result[:html].length} 字符"
  end
  
  def self.demo_designer_features
    puts "设计器友好特性:"
    puts "1. 简洁的网格配置 - 只需要 x, y, w, h 四个参数"
    puts "2. 内容与布局分离 - 内容区域是纯KR标签"
    puts "3. 拖拽支持 - 通过 data-gs-* 属性支持拖拽"
    puts "4. 实时预览 - 修改配置立即看到效果"
    puts "5. 导出配置 - 可以导出为JSON或DSL格式"
    
    # 演示配置导出
    simple_config = {
      columns: 12,
      items: [
        {id: 'item1', x: 0, y: 0, w: 6, h: 2, content: '<kr:input name="test" />'},
        {id: 'item2', x: 6, y: 0, w: 6, h: 2, content: '<kr:select name="type" />'}
      ]
    }
    
    puts "\n导出的配置示例:"
    puts JSON.pretty_generate(simple_config)
  end
  
  private
  
  def self.process_kr_content(content)
    # 简化的KR标签处理 - 实际应该调用KrTransformer
    return content unless content.include?('<kr:')
    
    # 这里可以调用现有的KrTransformer处理
    # processed = KrTransformer.trans(content, {})
    # 为了演示，直接返回处理后的HTML
    content.gsub(/<kr:(\w+)([^>]*)>/, '<div class="kr-\1" \2>')
           .gsub(/<\/kr:(\w+)>/, '</div>')
  end
end

# 运行演示
GridLayoutDemo.run if __FILE__ == $0
