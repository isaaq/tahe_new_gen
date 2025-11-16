require 'yaml'
require 'zip'
require 'fileutils'
require 'securerandom'
require_relative 'steganography'

module Book
  class ScrollPackage
    attr_reader :package_path, :config

    # 初始化包对象
    def initialize(package_path = nil)
      @package_path = package_path
      @config = nil
    end

    # 从现有的 .ss 文件加载包
    def load
      begin
        puts "[调试] 开始加载包: #{@package_path}"
        return false unless File.exist?(@package_path) && @package_path.end_with?('.ss')
        
        temp_dir = create_temp_dir
        puts "[调试] 创建临时目录: #{temp_dir}"
        
        extract_to_temp(temp_dir)
        puts "[调试] 解压到临时目录完成"
        
        # 列出解压后的文件
        puts "[调试] 解压后的文件列表:"
        Dir.glob(File.join(temp_dir, "**/*")).each do |file|
          puts "  - #{file} #{File.directory?(file) ? '(目录)' : "(文件, #{File.size(file)} 字节)"}"
        end
        
        cover_path = find_cover(temp_dir)
        puts "[调试] 封面路径: #{cover_path || '未找到'}"
        return false unless cover_path
        
        # 从封面图片中提取密码
        begin
          password = Book::Steganography.extract(cover_path)
          puts "[调试] 密码提取成功: #{password[0..3]}..."
        rescue => e
          puts "[调试] 密码提取失败: #{e.message}"
          return false
        end
        
        # 从封面图片中提取配置文件
        extract_config_from_cover(cover_path)
        puts "[调试] 配置提取结果: #{@config ? '成功' : '失败'}"
        
        # 使用密码解压 scroll 文件
        # 检查可能的文件名称
        possible_names = ['scroll', 'scroll.zip']
        scroll_path = nil
        
        possible_names.each do |name|
          path = File.join(temp_dir, name)
          puts "[调试] 检查 #{name} 文件: #{File.exist?(path) ? '存在' : '不存在'}"
          if File.exist?(path)
            scroll_path = path
            break
          end
        end
        
        if scroll_path
          extract_result = extract_scroll(scroll_path, password, temp_dir)
          puts "[调试] 解压 scroll 结果: #{extract_result ? '成功' : '失败'}"
          extract_result
        else
          puts "[调试] 未找到 scroll 文件"
          false
        end
      rescue => e
        puts "[调试] 加载包时发生异常: #{e.message}"
        puts e.backtrace.join("\n")
        false
      ensure
        if temp_dir && Dir.exist?(temp_dir)
          puts "[调试] 清理临时目录: #{temp_dir}"
          FileUtils.remove_entry(temp_dir)
        end
      end
    end

    # 创建新的 .ss 包
    def create(source_dir, output_path, config = {}, cover_path = nil)
      # 生成随机密码
      password = SecureRandom.hex(16)
      
      temp_dir = create_temp_dir
      scroll_path = File.join(temp_dir, 'scroll')
      
      # 收集文件内容信息
      contents = []
      Dir.glob(File.join(source_dir, "**/*")).each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{source_dir}/", '')
        contents << {
          'path' => relative_path,
          'size' => File.size(file)
        }
      end
      
      # 将文件内容信息添加到配置中
      config['contents'] = contents
      
      # 创建带密码的内部压缩包
      create_scroll(source_dir, scroll_path, password)
      
      # 处理封面图片
      process_cover(cover_path, config, password, temp_dir)
      
      # 创建最终的 .ss 包
      create_ss_package(temp_dir, output_path)
      
      true
    ensure
      FileUtils.remove_entry(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end

    # 获取包内容列表
    def list_contents
      return [] unless @config
      
      @config['contents'] || []
    end

    private

    # 创建临时目录
    def create_temp_dir
      temp_dir = File.join(Dir.tmpdir, "scroll_package_#{SecureRandom.hex(8)}")
      FileUtils.mkdir_p(temp_dir)
      temp_dir
    end

    # 将 .ss 文件解压到临时目录
    def extract_to_temp(temp_dir)
      Zip::File.open(@package_path) do |zip_file|
        zip_file.each do |entry|
          entry_path = File.join(temp_dir, entry.name)
          FileUtils.mkdir_p(File.dirname(entry_path))
          zip_file.extract(entry, entry_path)
        end
      end
    end

    # 查找封面图片
    def find_cover(dir)
      puts "[调试] 在目录中查找封面图片: #{dir}"
      
      # 先查找根目录下的 cover.* 文件
      cover_patterns = ['cover.*', 'cover/*.{jpg,jpeg,png}', '*/cover.{jpg,jpeg,png}']
      
      cover_patterns.each do |pattern|
        puts "[调试] 使用模式查找: #{pattern}"
        files = Dir.glob(File.join(dir, pattern))
        puts "[调试] 找到文件: #{files.join(', ')}" if !files.empty?
        
        cover_file = files.find do |file|
          file.downcase.end_with?('.jpg', '.jpeg', '.png')
        end
        
        if cover_file
          puts "[调试] 找到封面图片: #{cover_file}"
          return cover_file
        end
      end
      
      # 如果没有找到，尝试递归查找所有图片文件
      puts "[调试] 递归查找所有图片文件"
      image_files = Dir.glob(File.join(dir, '**/*.{jpg,jpeg,png}'))
      puts "[调试] 找到图片文件: #{image_files.join(', ')}" if !image_files.empty?
      
      # 如果有图片文件，使用第一个
      if !image_files.empty?
        puts "[调试] 使用第一个图片文件作为封面: #{image_files.first}"
        return image_files.first
      end
      
      puts "[调试] 未找到封面图片"
      nil
    end

    # 从封面图片中提取配置文件
    def extract_config_from_cover(cover_path)
      # 读取图片文件
      data = File.binread(cover_path)
      
      # 查找 YAML 配置的开始标记
      yaml_start = data.index('---')
      
      if yaml_start
        # 提取 YAML 部分
        yaml_data = data[yaml_start..-1]
        begin
          @config = YAML.safe_load(yaml_data)
        rescue
          @config = {}
        end
      else
        @config = {}
      end
    end

    # 使用密码解压 scroll 文件
    def extract_scroll(scroll_path, password, output_dir)
      # 创建内容目录
      content_dir = File.join(output_dir, 'content')
      FileUtils.mkdir_p(content_dir) unless Dir.exist?(content_dir)
      
      puts "[调试] 尝试解压 scroll 文件: #{scroll_path}"
      puts "[调试] 密码: #{password[0..3]}..."
      puts "[调试] 输出目录: #{content_dir}"
      
      # 这里使用系统的 unzip 命令，因为 rubyzip 不支持密码
      cmd = "unzip -P \"#{password}\" -o \"#{scroll_path}\" -d \"#{content_dir}\""
      puts "[调试] 执行命令: #{cmd}"
      
      result = system(cmd)
      puts "[调试] unzip 命令返回结果: #{result}"
      
      # 检查解压后的文件
      if result && Dir.exist?(content_dir)
        puts "[调试] 解压后的文件列表:"
        Dir.glob(File.join(content_dir, "**/*")).each do |file|
          puts "  - #{file} #{File.directory?(file) ? '(目录)' : "(文件, #{File.size(file)} 字节)"}"
        end
      end
      
      result
    end

    # 创建默认封面图片
    def create_default_cover(temp_dir)
      default_cover_path = File.join(temp_dir, 'cover.png')
      
      # 创建一个简单的 PNG 图片
      image = ChunkyPNG::Image.new(800, 600, ChunkyPNG::Color::WHITE)
      
      # 添加一些简单的图形
      400.times do |i|
        x = i * 2
        image[x, 300] = ChunkyPNG::Color.rgba(0, 0, 255, 255)
      end
      
      image.save(default_cover_path)
      default_cover_path
    end

    # 将配置文件嵌入到封面图片中
    def embed_config_to_cover(cover_path, config, temp_dir)
      config_yaml = config.to_yaml.force_encoding('ASCII-8BIT')
      cover_data = File.binread(cover_path)
      
      # 创建新的封面文件，将配置追加到图片后面
      output_cover_path = File.join(temp_dir, 'cover.png')
      File.binwrite(output_cover_path, cover_data + config_yaml)
      
      output_cover_path
    end

    # 使用隐写术将密码隐藏在图片中
    def embed_password_to_cover(cover_path, password, temp_dir)
      image = Book::Steganography.hide(cover_path, password)
      output_path = File.join(temp_dir, 'cover.png')
      image.save(output_path)
      output_path
    end
    
    # 处理封面图片：如果没有提供，则使用默认图片
    def process_cover(cover_path, config, password, temp_dir)
      # 如果没有提供封面图片，则创建默认封面
      if cover_path.nil? || !File.exist?(cover_path)
        cover_path = create_default_cover(temp_dir)
      else
        # 复制封面图片到临时目录
        final_cover_path = File.join(temp_dir, 'cover.png')
        FileUtils.cp(cover_path, final_cover_path)
        cover_path = final_cover_path
      end
      
      # 先使用隐写术将密码隐藏在图片中
      password_cover = embed_password_to_cover(cover_path, password, temp_dir)
      
      # 然后将配置文件嵌入到封面图片中
      embed_config_to_cover(password_cover, config, temp_dir)
      
      File.join(temp_dir, 'cover.png')
    end

    # 创建带密码的内部压缩包
    def create_scroll(source_dir, output_path, password)
      puts "[调试] 创建带密码的内部压缩包"
      puts "[调试] 源目录: #{source_dir}"
      puts "[调试] 输出路径: #{output_path}"
      puts "[调试] 密码: #{password[0..3]}..."
      
      # 检查源目录内容
      puts "[调试] 源目录文件列表:"
      Dir.glob(File.join(source_dir, "**/*")).each do |file|
        puts "  - #{file} #{File.directory?(file) ? '(目录)' : "(文件, #{File.size(file)} 字节)"}"
      end
      
      # 使用系统的 zip 命令，因为 rubyzip 不支持密码
      cmd = "cd \"#{source_dir}\" && zip -r -P \"#{password}\" \"#{output_path}\" ."
      puts "[调试] 执行命令: #{cmd}"
      
      result = system(cmd)
      puts "[调试] zip 命令返回结果: #{result}"
      
      # 检查生成的文件
      if File.exist?(output_path)
        puts "[调试] 成功创建 scroll 文件: #{output_path} (#{File.size(output_path)} 字节)"
      else
        puts "[调试] 创建 scroll 文件失败"
      end
      
      result
    end

    # 创建最终的 .ss 包
    def create_ss_package(temp_dir, output_path)
      puts "[调试] 创建最终的 .ss 包"
      puts "[调试] 临时目录: #{temp_dir}"
      puts "[调试] 输出路径: #{output_path}"
      
      # 确保 scroll 文件被正确命名为 scroll.zip
      scroll_path = File.join(temp_dir, 'scroll')
      if File.exist?(scroll_path)
        scroll_zip_path = File.join(temp_dir, 'scroll.zip')
        puts "[调试] 重命名 scroll 文件为 scroll.zip"
        FileUtils.mv(scroll_path, scroll_zip_path)
      end
      
      # 列出要添加到包中的文件
      puts "[调试] 要添加到包中的文件:"
      Dir.glob(File.join(temp_dir, '**', '*')).each do |file|
        next if File.directory?(file) || file.include?('/content/')
        puts "  - #{file} (#{File.size(file)} 字节)"
      end
      
      Zip::File.open(output_path, Zip::File::CREATE) do |zipfile|
        Dir.glob(File.join(temp_dir, '**', '*')).each do |file|
          next if File.directory?(file) || file.include?('/content/')
          
          # 计算相对路径
          relative_path = file.sub("#{temp_dir}/", '')
          puts "[调试] 添加到包: #{relative_path}"
          zipfile.add(relative_path, file)
        end
      end
      
      puts "[调试] 创建包完成: #{output_path} (#{File.size(output_path)} 字节)"
    end
  end
end
