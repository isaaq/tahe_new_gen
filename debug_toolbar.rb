#!/usr/bin/env ruby
# 调试分离式表单工具栏生成问题

require_relative '_system'
require_relative 'lib/ui/ui_impl/kr_layout_parser'
require_relative 'lib/ui/ui_impl/kr_content_parser'
require_relative 'lib/ui/ui_impl/kr_merged_layout_generator'

puts "=== 调试分离式表单工具栏 ==="

# 生成分离式表单的HTML
layout_config = KrLayoutParser.parse_file('demo/project_registration_layout.json')
content_map = KrContentParser.parse_file('demo/project_registration_content.xml')
result = KrMergedLayoutGenerator.generate(layout_config, content_map)
separated_html = result[:html]

puts "分离式表单HTML长度: #{separated_html.length}"

# 查找所有包含 toolbar 的部分
puts "\n=== 查找toolbar相关内容 ==="
toolbar_matches = separated_html.scan(/.*toolbar.*/)
toolbar_matches.each_with_index do |match, index|
  puts "匹配#{index+1}: #{match[0..200]}..."
end

# 查找所有包含 layui-btn 的部分
puts "\n=== 查找layui-btn相关内容 ==="
btn_matches = separated_html.scan(/.*layui-btn.*/)
btn_matches.each_with_index do |match, index|
  puts "匹配#{index+1}: #{match[0..200]}..."
end

# 查找第一个网格项的完整内容
puts "\n=== 第一个网格项完整内容 ==="
first_grid_item = separated_html.match(/<div class="kr-grid-item"[^>]*data-gs-id="toolbar"[^>]*>(.*?)<\/div>/m)
if first_grid_item
  puts "找到toolbar网格项:"
  puts first_grid_item[1][0..500] + "..."
else
  puts "未找到toolbar网格项"
end

# 输出前1000个字符用于调试
puts "\n=== 分离式表单HTML前1000字符 ==="
puts separated_html[0..1000]

puts "\n=== 调试完成 ==="
