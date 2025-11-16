#!/usr/bin/env ruby
require_relative 'scroll_package'
require 'optparse'
require 'fileutils'

module Book
  class ScrollCLI
    def initialize(args)
      @args = args
      @options = {}
      parse_options
    end

    def run
      command = @args.shift
      
      case command
      when 'create'
        create_package
      when 'extract'
        extract_package
      when 'list'
        list_package_contents
      when 'help', nil
        show_help
      else
        puts "未知命令: #{command}"
        show_help
      end
    end

    private

    def parse_options
      opt_parser = OptionParser.new do |opts|
        opts.banner = "用法: scroll [命令] [选项]"
        
        opts.on('-s', '--source DIRECTORY', '源目录') do |dir|
          @options[:source] = dir
        end
        
        opts.on('-o', '--output FILE', '输出文件') do |file|
          @options[:output] = file
        end
        
        opts.on('-c', '--cover FILE', '封面图片') do |file|
          @options[:cover] = file
        end
        
        opts.on('-n', '--name NAME', '包名称') do |name|
          @options[:name] = name
        end
        
        opts.on('-d', '--description DESC', '包描述') do |desc|
          @options[:description] = desc
        end
        
        opts.on('-v', '--version VERSION', '包版本') do |version|
          @options[:version] = version
        end
        
        opts.on('-a', '--author AUTHOR', '作者') do |author|
          @options[:author] = author
        end
        
        opts.on('-h', '--help', '显示帮助') do
          puts opts
          exit
        end
      end
      
      opt_parser.parse!(@args)
    end

    def show_help
      puts "Scroll 包管理工具"
      puts ""
      puts "命令:"
      puts "  create    创建新的 .ss 包"
      puts "  extract   解压 .ss 包"
      puts "  list      列出 .ss 包内容"
      puts "  help      显示此帮助信息"
      puts ""
      puts "选项:"
      puts "  -s, --source DIRECTORY   源目录（创建命令需要）"
      puts "  -o, --output FILE        输出文件（创建命令需要）"
      puts "  -c, --cover FILE         封面图片（可选）"
      puts "  -n, --name NAME          包名称（可选）"
      puts "  -d, --description DESC   包描述（可选）"
      puts "  -v, --version VERSION    包版本（可选）"
      puts "  -a, --author AUTHOR      作者（可选）"
      puts "  -h, --help               显示此帮助信息"
    end

    def create_package
      unless @options[:source] && @options[:output]
        puts "错误: 创建包需要指定源目录和输出文件"
        return
      end
      
      unless Dir.exist?(@options[:source])
        puts "错误: 源目录不存在"
        return
      end
      
      if @options[:cover] && !File.exist?(@options[:cover])
        puts "错误: 指定的封面图片不存在"
        return
      end
      
      # 准备配置信息
      config = {
        'name' => @options[:name] || File.basename(@options[:output], '.ss'),
        'description' => @options[:description] || '',
        'version' => @options[:version] || '1.0.0',
        'author' => @options[:author] || ENV['USER'] || 'unknown',
        'created_at' => Time.now.to_s,
        'contents' => []
      }
      
      # 添加文件列表到配置
      Dir.glob(File.join(@options[:source], '**', '*')).each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{@options[:source]}/", '')
        config['contents'] << {
          'path' => relative_path,
          'size' => File.size(file)
        }
      end
      
      # 创建包
      package = ScrollPackage.new
      if package.create(@options[:source], @options[:output], config, @options[:cover])
        puts "成功创建包: #{@options[:output]}"
      else
        puts "创建包失败"
      end
    end

    def extract_package
      package_path = @args.shift
      output_dir = @args.shift || '.'
      
      unless package_path && File.exist?(package_path)
        puts "错误: 请指定有效的包文件"
        return
      end
      
      FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
      
      package = ScrollPackage.new(package_path)
      if package.load
        puts "成功解压包到: #{output_dir}"
      else
        puts "解压包失败"
      end
    end

    def list_package_contents
      package_path = @args.shift
      
      unless package_path && File.exist?(package_path)
        puts "错误: 请指定有效的包文件"
        return
      end
      
      package = ScrollPackage.new(package_path)
      if package.load
        contents = package.list_contents
        
        puts "包名称: #{package.config['name']}"
        puts "描述: #{package.config['description']}"
        puts "版本: #{package.config['version']}"
        puts "作者: #{package.config['author']}"
        puts "创建时间: #{package.config['created_at']}"
        puts "文件列表:"
        
        contents.each do |item|
          puts "  #{item['path']} (#{format_size(item['size'])})"
        end
      else
        puts "无法加载包或包格式无效"
      end
    end

    def format_size(size_in_bytes)
      units = ['B', 'KB', 'MB', 'GB']
      size = size_in_bytes.to_f
      unit_index = 0
      
      while size > 1024 && unit_index < units.length - 1
        size /= 1024
        unit_index += 1
      end
      
      "#{size.round(2)} #{units[unit_index]}"
    end
  end
end

# 如果直接运行此脚本
if __FILE__ == $PROGRAM_NAME
  Book::ScrollCLI.new(ARGV).run
end
