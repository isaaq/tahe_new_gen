#!/usr/bin/env ruby

# 调试分离式布局生成问题
require_relative 'lib/ui/ui_impl/kr_layout_parser'
require_relative 'lib/ui/ui_impl/kr_content_parser'
require_relative 'lib/ui/ui_impl/kr_merged_layout_generator'

puts "=== 开始调试分离式布局生成 ==="

# 解析布局文件
layout_file = 'demo/project_registration_layout.json'
content_file = 'demo/project_registration_content.xml'

puts "布局文件: #{layout_file}"
puts "内容文件: #{content_file}"

begin
  # 解析布局配置
  layout_config = KrLayoutParser.parse_file(layout_file)
  puts "\n=== 布局配置解析结果 ==="
  puts "标题: #{layout_config[:title]}"
  puts "网格列数: #{layout_config[:columns]}"
  puts "项目数量: #{layout_config[:items]&.length || 0}"
  
  if layout_config[:items]
    puts "前5个项目:"
    layout_config[:items].first(5).each_with_index do |item, index|
      puts "  #{index + 1}. ID: #{item[:id]}, 位置: (#{item[:x]}, #{item[:y]}), 大小: #{item[:w]}x#{item[:h]}"
    end
  end
  
  # 解析内容映射
  content_map = KrContentParser.parse_file(content_file)
  puts "\n=== 内容映射解析结果 ==="
  puts "内容项数量: #{content_map.length}"
  puts "内容项ID列表: #{content_map.keys.join(', ')}"
  
  # 显示前3个内容项的内容长度
  content_map.first(3).each do |id, content|
    puts "  #{id}: #{content.length} 字符"
  end
  
  # 生成合并结果
  puts "\n=== 开始生成合并布局 ==="
  result = KrMergedLayoutGenerator.generate(layout_config, content_map)
  
  puts "HTML长度: #{result[:html].length}"
  puts "CSS长度: #{result[:css].length}"
  puts "JS长度: #{result[:js].length}"
  
  puts "\n=== HTML内容预览 (前1000字符) ==="
  puts result[:html][0..1000]
  
  puts "\n=== 调试完成 ==="
  
rescue => e
  puts "错误: #{e.message}"
  puts "堆栈跟踪:"
  puts e.backtrace.join("\n")
end
