#!/usr/bin/env ruby
require_relative 'scroll_package'
require_relative 'scroll_store'
require 'fileutils'
require 'chunky_png'

# 创建示例目录结构
def setup_example
  # 创建测试目录
  test_dir = File.join(Dir.tmpdir, 'scroll_example')
  FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
  FileUtils.mkdir_p(test_dir)
  
  # 创建源文件目录
  source_dir = File.join(test_dir, 'source')
  FileUtils.mkdir_p(source_dir)
  
  # 创建一些示例文件
  File.write(File.join(source_dir, 'hello.txt'), "你好，这是一个测试文件！\n")
  File.write(File.join(source_dir, 'config.json'), '{"name": "测试配置", "version": "1.0.0"}')
  
  # 创建子目录
  sub_dir = File.join(source_dir, 'subdir')
  FileUtils.mkdir_p(sub_dir)
  File.write(File.join(sub_dir, 'subfile.txt'), "这是子目录中的文件\n")
  
  # 创建示例封面图片
  cover_path = File.join(test_dir, 'cover.png')
  create_example_cover(cover_path)
  
  # 创建页面目录（魔法书页面）
  pages_dir = File.join(test_dir, 'pages')
  FileUtils.mkdir_p(pages_dir)
  
  # 创建示例页面图片（10页童话书）
  pages = []
  components = []
  
  10.times do |i|
    page_num = i + 1
    
    # 创建页面图片
    page_path = File.join(pages_dir, "page_#{page_num}.png")
    create_page_image(page_path, page_num)
    pages << page_path
    
    # 为每页创建示例组件（这些组件会被嵌入到图片中）
    page_components = create_page_components(page_num)
    components << page_components
  end
  
  # 返回创建的路径
  {
    test_dir: test_dir,
    source_dir: source_dir,
    cover_path: cover_path,
    pages_dir: pages_dir,
    components: components,
    output_path: File.join(test_dir, 'example.ss')
  }
end

# 创建示例封面图片
def create_example_cover(path)
  require 'chunky_png'
  
  # 创建一个简单的 PNG 图片
  image = ChunkyPNG::Image.new(400, 300, ChunkyPNG::Color::WHITE)
  
  # 添加一些简单的图形
  200.times do |i|
    x = i * 2
    image[x, 150] = ChunkyPNG::Color.rgba(255, 0, 0, 255)
  end
  
  image.save(path)
end

# 创建页面图片
def create_page_image(path, page_num)
  image = ChunkyPNG::Image.new(800, 600, ChunkyPNG::Color::WHITE)
  
  # 添加一些图形
  color = ChunkyPNG::Color.rgb(100 + page_num * 15, 150, 200)
  
  # 绘制一些简单的图形
  50.times do |i|
    x = (i * 16) % 800
    y = (i * 12) % 600
    image[x, y] = color
  end
  
  image.save(path)
end

# 为页面创建示例组件
def create_page_components(page_num)
  components = []
  
  # 每页创建 1-3 个组件
  component_count = (page_num % 3) + 1
  
  component_count.times do |i|
    component = {
      'type' => "component_type_#{page_num}_#{i + 1}",
      'name' => "页面 #{page_num} 的组件 #{i + 1}",
      'data' => {
        'page' => page_num,
        'index' => i + 1,
        'content' => "这是页面 #{page_num} 的第 #{i + 1} 个组件的示例数据"
      }
    }
    components << component
  end
  
  components
end

# 运行示例
def run_example
  puts "开始运行 ScrollPackage 示例..."
  paths = setup_example
  
  puts "创建测试目录: #{paths[:test_dir]}"
  puts "源文件目录: #{paths[:source_dir]}"
  puts "封面图片: #{paths[:cover_path]}"
  puts "输出文件: #{paths[:output_path]}"
  
  # 配置信息
  config = {
    'name' => '示例包',
    'description' => '这是一个示例包，用于演示 ScrollPackage 的功能',
    'version' => '1.0.0',
    'author' => 'ScrollPackage 示例'
  }
  
  # 创建包（包含页面和组件）
  puts "\n创建包..."
  package = Book::ScrollPackage.new
  if package.create(paths[:source_dir], paths[:output_path], config, paths[:cover_path], paths[:pages_dir], paths[:components])
    puts "成功创建包: #{paths[:output_path]}"
  else
    puts "创建包失败"
    return
  end
  
  # 加载包
  puts "\n加载包..."
  loaded_package = Book::ScrollPackage.new(paths[:output_path])
  if loaded_package.load
    puts "成功加载包"
    puts "包配置:"
    puts "  名称: #{loaded_package.config['name']}"
    puts "  描述: #{loaded_package.config['description']}"
    puts "  版本: #{loaded_package.config['version']}"
    puts "  作者: #{loaded_package.config['author']}"
    
    puts "\n包内容:"
    loaded_package.list_contents.each do |item|
      puts "  #{item['path']} (#{item['size']} 字节)"
    end
    
    # 显示页面和组件信息
    if loaded_package.pages && !loaded_package.pages.empty?
      puts "\n页面信息:"
      loaded_package.pages.each do |page|
        components_count = (page[:components] || []).length
        puts "  页面 #{page[:page_number]}: #{File.basename(page[:path])} (组件: #{components_count})"
      end
      
      # 显示所有组件
      all_components = loaded_package.get_components
      if all_components && !all_components.empty?
        puts "\n组件总数: #{all_components.length}"
      end
    end
  else
    puts "加载包失败"
    return
  end
  
  # 安装包到数据库
  puts "\n安装包到数据库..."
  store = Book::ScrollStore.instance
  install_result = store.install_scroll(paths[:output_path])
  
  if install_result[:success]
    scroll_id = install_result[:scroll][:scroll_id]
    puts "成功安装 scroll: #{install_result[:scroll][:name]}"
    puts "  Scroll ID: #{scroll_id}"
    puts "  页面数: #{install_result[:scroll][:pages_count]}"
    
    # 显示组件信息
    components = store.get_scroll_components(scroll_id)
    if components && !components.empty?
      puts "  安装的组件数: #{components.length}"
    end
    
    # 列出已安装的 scroll
    puts "\n已安装的 scroll:"
    installed_scrolls = store.list_scrolls
    installed_scrolls.each do |scroll|
      puts "  - #{scroll[:name] || scroll[:scroll_id]} (#{scroll[:scroll_id]})"
    end
  else
    puts "安装失败: #{install_result[:error]}"
  end
  
  puts "\n示例完成。"
  puts "包文件位置: #{paths[:output_path]}"
  puts "你可以使用以下命令:"
  puts "  ruby lib/book/scroll_cli.rb list #{paths[:output_path]}"
  puts "  ruby lib/book/scroll_cli.rb installed"
end

# 如果直接运行此脚本
if __FILE__ == $PROGRAM_NAME
  run_example
end
