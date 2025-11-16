#!/usr/bin/env ruby
# 对比分离式和非分离式表单的输出差异

require_relative '_system'
require_relative 'lib/ui/ui_impl/kr_layout_parser'
require_relative 'lib/ui/ui_impl/kr_content_parser'
require_relative 'lib/ui/ui_impl/kr_merged_layout_generator'

puts "=== 开始对比分离式和非分离式表单 ==="

# 1. 读取非分离式表单的HTML
non_separated_html = File.read('demo/project_registration_form.html')
puts "非分离式表单HTML长度: #{non_separated_html.length}"

# 2. 生成分离式表单的HTML
layout_config = KrLayoutParser.parse_file('demo/project_registration_layout.json')
content_map = KrContentParser.parse_file('demo/project_registration_content.xml')
result = KrMergedLayoutGenerator.generate(layout_config, content_map)
separated_html = result[:html]
puts "分离式表单HTML长度: #{separated_html.length}"

# 3. 对比工具栏部分
puts "\n=== 工具栏对比 ==="

# 从非分离式表单中提取工具栏
non_sep_toolbar = non_separated_html.match(/<div class='layui-btn-container'>(.*?)<\/div>/m)
if non_sep_toolbar
  puts "非分离式工具栏:"
  puts non_sep_toolbar[1].strip
else
  puts "非分离式表单中未找到工具栏"
end

# 从分离式表单中提取工具栏
sep_toolbar = separated_html.match(/<div class='layui-btn-container'>(.*?)<\/div>/m)
if sep_toolbar
  puts "\n分离式工具栏:"
  puts sep_toolbar[1].strip
else
  puts "分离式表单中未找到工具栏"
  # 尝试查找任何包含button的div
  button_divs = separated_html.scan(/<div[^>]*>.*?<button.*?<\/div>/m)
  if button_divs.any?
    puts "找到包含按钮的div:"
    button_divs.first(2).each { |div| puts div[0..200] + "..." }
  end
end

# 4. 对比容器结构
puts "\n=== 容器结构对比 ==="

# 非分离式容器
non_sep_container = non_separated_html.match(/<body>\s*<div class="([^"]*)">/m)
if non_sep_container
  puts "非分离式容器类名: #{non_sep_container[1]}"
else
  puts "非分离式表单容器未找到"
end

# 分离式容器（从模板文件中读取）
template_content = File.read('web/views/separated_layout_page.erb')
sep_container = template_content.match(/<div class="([^"]*)"[^>]*>/m)
if sep_container
  puts "分离式容器类名: #{sep_container[1]}"
else
  puts "分离式表单容器未找到"
end

puts "\n=== 对比完成 ==="
