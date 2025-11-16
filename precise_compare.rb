#!/usr/bin/env ruby
# 精确对比分离式和非分离式表单的HTML输出

require_relative '_system'
require_relative 'lib/ui/ui_impl/kr_layout_parser'
require_relative 'lib/ui/ui_impl/kr_content_parser'
require_relative 'lib/ui/ui_impl/kr_merged_layout_generator'

puts "=== 精确对比分离式和非分离式表单 ==="

# 1. 读取非分离式表单的HTML
non_separated_html = File.read('demo/project_registration_form.html')

# 2. 生成分离式表单的HTML
layout_config = KrLayoutParser.parse_file('demo/project_registration_layout.json')
content_map = KrContentParser.parse_file('demo/project_registration_content.xml')
result = KrMergedLayoutGenerator.generate(layout_config, content_map)
separated_html = result[:html]

puts "非分离式表单HTML长度: #{non_separated_html.length}"
puts "分离式表单HTML长度: #{separated_html.length}"

# 3. 提取并对比工具栏HTML
puts "\n=== 工具栏HTML对比 ==="

# 非分离式工具栏
non_sep_toolbar_match = non_separated_html.match(/<div class='layui-btn-container'>(.*?)<\/div>/m)
non_sep_toolbar = non_sep_toolbar_match ? non_sep_toolbar_match[1].strip : "未找到"

# 分离式工具栏 - 在网格项内容中查找
sep_toolbar_match = separated_html.match(/<div class='layui-btn-container'>(.*?)<\/div>/m)
sep_toolbar = sep_toolbar_match ? sep_toolbar_match[1].strip : "未找到"

puts "非分离式工具栏HTML:"
puts non_sep_toolbar
puts "\n分离式工具栏HTML:"
puts sep_toolbar

# 4. 对比按钮内容
puts "\n=== 按钮内容对比 ==="
non_sep_buttons = non_sep_toolbar.scan(/<button[^>]*>(.*?)<\/button>/)
sep_buttons = sep_toolbar.scan(/<button[^>]*>(.*?)<\/button>/)

puts "非分离式按钮数量: #{non_sep_buttons.length}"
puts "分离式按钮数量: #{sep_buttons.length}"

if non_sep_buttons.length == sep_buttons.length
  puts "✓ 按钮数量一致"
  
  non_sep_buttons.each_with_index do |button, index|
    if button[0] == sep_buttons[index][0]
      puts "✓ 按钮#{index+1}内容一致: #{button[0]}"
    else
      puts "✗ 按钮#{index+1}内容不一致:"
      puts "  非分离式: #{button[0]}"
      puts "  分离式: #{sep_buttons[index][0]}"
    end
  end
else
  puts "✗ 按钮数量不一致"
end

# 5. 对比容器类名
puts "\n=== 容器类名对比 ==="
non_sep_container = non_separated_html.match(/<div class="([^"]*layui-form[^"]*)"/)
non_sep_container_class = non_sep_container ? non_sep_container[1] : "未找到"

# 从模板文件读取分离式容器类名
template_content = File.read('web/views/separated_layout_page.erb')
sep_container = template_content.match(/<div class="([^"]*)"[^>]*>/)
sep_container_class = sep_container ? sep_container[1] : "未找到"

puts "非分离式容器类名: #{non_sep_container_class}"
puts "分离式容器类名: #{sep_container_class}"

if non_sep_container_class == sep_container_class
  puts "✓ 容器类名一致"
else
  puts "✗ 容器类名不一致"
end

puts "\n=== 对比完成 ==="
