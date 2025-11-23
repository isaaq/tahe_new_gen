#!/usr/bin/env ruby
require_relative 'scroll_package'
require_relative 'scroll_store'
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
      when 'install'
        install_scroll
      when 'uninstall'
        uninstall_scroll
      when 'installed'
        list_installed
      when 'show'
        show_scroll
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
        
        opts.on('-p', '--pages DIRECTORY', '页面图片目录（魔法书页面）') do |dir|
          @options[:pages] = dir
        end
        
        opts.on('-i', '--id ID', 'Scroll ID（安装命令可选）') do |id|
          @options[:scroll_id] = id
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
      puts "  create     创建新的 .ss 包"
      puts "  extract    解压 .ss 包"
      puts "  list       列出 .ss 包内容"
      puts "  install    安装 .ss 包到数据库"
      puts "  uninstall  卸载已安装的 .ss 包"
      puts "  installed  列出所有已安装的 scroll"
      puts "  show       显示 scroll 详情"
      puts "  help       显示此帮助信息"
      puts ""
      puts "选项:"
      puts "  -s, --source DIRECTORY   源目录（创建命令需要）"
      puts "  -o, --output FILE        输出文件（创建命令需要）"
      puts "  -c, --cover FILE         封面图片（可选）"
      puts "  -n, --name NAME          包名称（可选）"
      puts "  -d, --description DESC   包描述（可选）"
      puts "  -v, --version VERSION    包版本（可选）"
      puts "  -a, --author AUTHOR      作者（可选）"
      puts "  -p, --pages DIRECTORY    页面图片目录（创建命令可选，魔法书页面）"
      puts "  -i, --id ID              Scroll ID（安装命令可选）"
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
      
      # 准备页面组件（如果有页面目录）
      components = []
      if @options[:pages] && Dir.exist?(@options[:pages])
        # 这里可以添加组件数据准备逻辑
        # components = prepare_components(@options[:pages])
      end
      
      # 创建包
      package = ScrollPackage.new
      if package.create(@options[:source], @options[:output], config, @options[:cover], @options[:pages], components)
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
    
    def install_scroll
      scroll_path = @args.shift
      
      unless scroll_path && File.exist?(scroll_path)
        puts "错误: 请指定有效的 .ss 文件"
        return
      end
      
      store = ScrollStore.instance
      options = {}
      options[:scroll_id] = @options[:scroll_id] if @options[:scroll_id]
      
      result = store.install_scroll(scroll_path, options)
      
      if result[:success]
        puts "成功安装 scroll: #{result[:scroll][:name]}"
        puts "  Scroll ID: #{result[:scroll][:scroll_id]}"
        puts "  版本: #{result[:scroll][:version]}"
        puts "  页面数: #{result[:scroll][:pages_count]}"
      else
        puts "安装 scroll 失败: #{result[:error]}"
      end
    end
    
    def uninstall_scroll
      scroll_id = @args.shift
      
      unless scroll_id
        puts "错误: 请指定 scroll_id"
        return
      end
      
      store = ScrollStore.instance
      result = store.uninstall_scroll(scroll_id)
      
      if result[:success]
        puts "成功卸载 scroll: #{scroll_id}"
      else
        puts "卸载 scroll 失败: #{result[:error]}"
      end
    end
    
    def list_installed
      store = ScrollStore.instance
      scrolls = store.list_scrolls
      
      if scrolls.empty?
        puts "没有已安装的 scroll"
        return
      end
      
      puts "已安装的 scroll (#{scrolls.length} 个):"
      puts ""
      
      scrolls.each do |scroll|
        puts "  Scroll ID: #{scroll[:scroll_id]}"
        puts "  名称: #{scroll[:name] || 'N/A'}"
        puts "  版本: #{scroll[:version] || 'N/A'}"
        puts "  作者: #{scroll[:author] || 'N/A'}"
        puts "  页面数: #{scroll[:pages_count] || 0}"
        puts "  安装时间: #{scroll[:installed_at] || 'N/A'}"
        puts ""
      end
    end
    
    def show_scroll
      scroll_id = @args.shift
      
      unless scroll_id
        puts "错误: 请指定 scroll_id"
        return
      end
      
      store = ScrollStore.instance
      scroll = store.get_scroll(scroll_id)
      
      unless scroll
        puts "错误: Scroll 不存在"
        return
      end
      
      puts "Scroll 详情:"
      puts "  Scroll ID: #{scroll[:scroll_id]}"
      puts "  名称: #{scroll[:name]}"
      puts "  描述: #{scroll[:description]}"
      puts "  版本: #{scroll[:version]}"
      puts "  作者: #{scroll[:author]}"
      puts "  页面数: #{scroll[:pages_count]}"
      puts "  安装状态: #{scroll[:installed] ? '已安装' : '未安装'}"
      puts "  安装时间: #{scroll[:installed_at] || 'N/A'}"
      puts ""
      
      if scroll[:pages_info] && !scroll[:pages_info].empty?
        puts "页面信息:"
        scroll[:pages_info].each do |page_info|
          puts "  页面 #{page_info[:page_number]}: #{page_info[:path]} (组件: #{page_info[:components_count]})"
        end
        puts ""
      end
      
      # 显示组件信息
      components = store.get_scroll_components(scroll_id)
      if components && !components.empty?
        puts "组件信息 (#{components.length} 个):"
        components.each do |component|
          puts "  组件 ID: #{component['component_id']}"
          puts "    页面: #{component['page_number']}"
          puts "    类型: #{component['component_type']}"
        end
      end
    end
  end
end

# 如果直接运行此脚本
if __FILE__ == $PROGRAM_NAME
  Book::ScrollCLI.new(ARGV).run
end
