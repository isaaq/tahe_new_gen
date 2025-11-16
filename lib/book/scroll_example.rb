#!/usr/bin/env ruby
require_relative 'scroll_package'
require 'fileutils'

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
  
  # 返回创建的路径
  {
    test_dir: test_dir,
    source_dir: source_dir,
    cover_path: cover_path,
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
  
  # 创建包
  puts "\n创建包..."
  package = Book::ScrollPackage.new
  if package.create(paths[:source_dir], paths[:output_path], config, paths[:cover_path])
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
  else
    puts "加载包失败"
  end
  
  puts "\n示例完成。"
  puts "包文件位置: #{paths[:output_path]}"
  puts "你可以使用以下命令来查看包内容:"
  puts "  ruby lib/book/scroll_cli.rb list #{paths[:output_path]}"
end

# 如果直接运行此脚本
if __FILE__ == $PROGRAM_NAME
  run_example
end
