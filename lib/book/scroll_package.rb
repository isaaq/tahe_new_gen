require 'yaml'
require 'zip'
require 'fileutils'
require 'securerandom'
require_relative 'steganography'

module Book
  class ScrollPackage
    attr_reader :package_path, :config, :pages

    # 初始化包对象
    def initialize(package_path = nil)
      @package_path = package_path
      @config = nil
      @pages = []
    end

    # 从现有的 .ss 文件加载包
    def load
      begin
        puts "[调试] 开始加载包: #{@package_path}"
        return false unless File.exist?(@package_path) && @package_path.end_with?('.ss')
        
        @temp_dir = create_temp_dir
        puts "[调试] 创建临时目录: #{@temp_dir}"
        
        extract_to_temp(@temp_dir)
        puts "[调试] 解压到临时目录完成"
        
        # 列出解压后的文件
        puts "[调试] 解压后的文件列表:"
        Dir.glob(File.join(temp_dir, "**/*")).each do |file|
          puts "  - #{file} #{File.directory?(file) ? '(目录)' : "(文件, #{File.size(file)} 字节)"}"
        end
        
        cover_path = find_cover(@temp_dir)
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
        
        # 提取所有页面图片（魔法书概念：页面与项目无关）
        @pages = extract_pages(@temp_dir)
        puts "[调试] 找到 #{@pages.length} 个页面"
        
        # 从每个页面提取组件文件名列表（使用隐写术）
        # 页面中存储的是组件压缩包/文件的文件名列表
        @pages.each_with_index do |page_path, index|
          puts "[调试] 处理页面 #{index + 1}: #{File.basename(page_path)}"
          extract_component_files_from_page(page_path, index, @temp_dir)
        end
        
        # 使用密码解压 scroll 文件（包含实际项目内容，可选）
        # 检查可能的文件名称
        possible_names = ['scroll', 'scroll.zip']
        scroll_path = nil
        
        possible_names.each do |name|
          path = File.join(@temp_dir, name)
          puts "[调试] 检查 #{name} 文件: #{File.exist?(path) ? '存在' : '不存在'}"
          if File.exist?(path)
            scroll_path = path
            break
          end
        end
        
        if scroll_path
          extract_result = extract_scroll(scroll_path, password, @temp_dir)
          puts "[调试] 解压 scroll 结果: #{extract_result ? '成功' : '失败'}"
          # 即使解压失败，如果页面已提取，仍然返回true
          extract_result || true
        else
          puts "[调试] 未找到 scroll 文件（这是正常的，如果scroll只是魔法书页面）"
          true  # 如果没有scroll文件，仍然返回true，因为页面已经提取了
        end
      rescue => e
        puts "[调试] 加载包时发生异常: #{e.message}"
        puts e.backtrace.join("\n")
        false
      end
    end
    
    # 清理临时目录（安装完成后调用）
    def cleanup_temp_dir
      if @temp_dir && Dir.exist?(@temp_dir)
        puts "[调试] 清理临时目录: #{@temp_dir}"
        FileUtils.remove_entry(@temp_dir)
        @temp_dir = nil
      end
    end

    # 创建新的 .ss 包
    # pages_dir: 页面图片目录（可选，魔法书页面）
    # component_files_dir: 组件文件目录（可选，包含要嵌入的压缩包和文件）
    # component_files_map: 可选的组件文件映射 { 0 => ['comp1.zip', 'file1.txt'], 1 => [...] }
    def create(source_dir, output_path, config = {}, cover_path = nil, pages_dir = nil, component_files_dir = nil, component_files_map = {})
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
      
      # 复制组件文件到临时目录（如果提供）
      components_dest = nil
      if component_files_dir && Dir.exist?(component_files_dir)
        components_dest = File.join(temp_dir, 'components')
        FileUtils.mkdir_p(components_dest)
        
        # 复制所有组件文件
        Dir.glob(File.join(component_files_dir, '*')).each do |file|
          dest = File.join(components_dest, File.basename(file))
          if File.directory?(file)
            FileUtils.cp_r(file, dest)
          else
            FileUtils.cp(file, dest)
          end
        end
        puts "[调试] 复制组件文件到临时目录: #{components_dest}"
      end
      
      # 处理页面图片（魔法书概念）
      # 如果提供了 component_files_map，需要将文件名映射为相对路径（相对于 .ss 包根目录）
      if pages_dir && Dir.exist?(pages_dir)
        # 如果组件文件在 components 目录中，需要调整文件名映射
        adjusted_map = {}
        if components_dest
          component_files_map.each do |page_index, files_list|
            # 将文件名转换为 components/ 开头的路径
            adjusted_map[page_index] = files_list.map do |file_name|
              if file_name.start_with?('components/')
                file_name
              else
                "components/#{file_name}"
              end
            end
          end
        else
          adjusted_map = component_files_map
        end
        
        process_pages(pages_dir, temp_dir, adjusted_map)
      end
      
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
    
    # 获取所有组件文件（从页面中提取的文件名列表对应的文件）
    def get_component_files
      all_files = []
      @pages.each do |page|
        all_files.concat(page[:component_files] || [])
      end
      all_files
    end
    
    # 获取临时目录路径（用于安装时访问文件）
    def get_temp_dir
      @temp_dir
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
    
    # 提取所有页面图片
    def extract_pages(temp_dir)
      pages = []
      
      # 查找所有 page_*.{jpg,jpeg,png} 文件
      page_files = Dir.glob(File.join(temp_dir, 'page_*.{jpg,jpeg,png}'))
        .sort_by { |f| 
          # 按页面编号排序
          match = File.basename(f).match(/page_(\d+)/)
          match ? match[1].to_i : 999
        }
      
      page_files.each do |page_file|
        pages << {
          path: page_file,
          page_number: extract_page_number(page_file),
          component_files: []
        }
      end
      
      pages
    end
    
    # 从文件名提取页面编号
    def extract_page_number(file_path)
      match = File.basename(file_path).match(/page_(\d+)/)
      match ? match[1].to_i : 0
    end
    
    # 从页面图片中提取组件文件名列表（使用隐写术）
    # 页面中存储的是组件压缩包/文件的文件名列表
    def extract_component_files_from_page(page_path, index, temp_dir)
      begin
        # 使用隐写术提取文件名列表
        files_data = Book::Steganography.extract(page_path)
        
        # 如果提取到数据，尝试解析为文件名列表
        if files_data && !files_data.empty?
          begin
            require 'json'
            # 尝试解析为 JSON 或 YAML
            if files_data.start_with?('---')
              # YAML 格式
              files_list = YAML.safe_load(files_data)
            elsif files_data.start_with?('{') || files_data.start_with?('[')
              # JSON 格式
              files_list = JSON.parse(files_data)
            else
              # 可能是换行分隔的文件名列表
              files_list = files_data.split("\n").map(&:strip).reject(&:empty?)
            end
            
            # 确保 files_list 是数组
            files_list = [files_list] unless files_list.is_a?(Array)
            
            # 验证文件是否存在，并收集文件信息
            component_files = []
            files_list.each do |file_name|
              # 尝试多种可能的路径
              possible_paths = [
                File.join(temp_dir, file_name),
                File.join(temp_dir, 'components', File.basename(file_name)),
                File.join(temp_dir, File.basename(file_name))
              ]
              
              file_path = possible_paths.find { |path| File.exist?(path) }
              
              if file_path
                component_files << {
                  'name' => file_name,
                  'path' => file_path,
                  'type' => File.directory?(file_path) ? 'directory' : File.extname(file_name).downcase == '.zip' ? 'zip' : 'file',
                  'size' => File.file?(file_path) ? File.size(file_path) : 0
                }
              else
                puts "[警告] 页面 #{index + 1} 中引用的文件不存在: #{file_name} (尝试了 #{possible_paths.join(', ')})"
              end
            end
            
            @pages[index][:component_files] = component_files
            puts "[调试] 从页面 #{index + 1} 提取到 #{component_files.length} 个组件文件"
          rescue => e
            puts "[调试] 解析页面 #{index + 1} 的文件列表失败: #{e.message}"
            @pages[index][:component_files] = []
          end
        else
          puts "[调试] 页面 #{index + 1} 未包含组件文件列表"
          @pages[index][:component_files] = []
        end
      rescue => e
        puts "[调试] 提取页面 #{index + 1} 的文件列表时发生异常: #{e.message}"
        @pages[index][:component_files] = []
      end
    end
    
    # 处理页面图片：复制并嵌入组件文件名列表
    # component_files_map: 每个页面对应的组件文件列表 { 0 => ['comp1.zip', 'file1.txt'], 1 => [...] }
    def process_pages(pages_dir, temp_dir, component_files_map = {})
      # 收集页面图片
      page_files = Dir.glob(File.join(pages_dir, "**/*.{jpg,jpeg,png}"))
        .select { |f| File.file?(f) }
        .sort_by { |f| File.basename(f) }
      
      puts "[调试] 找到 #{page_files.length} 个页面文件"
      
      # 复制页面文件到临时目录，并按顺序命名
      # 如果提供了组件文件列表，使用隐写术将文件名列表嵌入到页面中
      page_files.each_with_index do |page_file, index|
        ext = File.extname(page_file)
        page_name = "page_#{index + 1}#{ext}"
        dest_path = File.join(temp_dir, page_name)
        
        # 如果有对应页面的组件文件列表，使用隐写术嵌入文件名列表
        files_list = component_files_map[index] || []
        if !files_list.empty?
          puts "[调试] 为页面 #{index + 1} 嵌入 #{files_list.length} 个组件文件名"
          embed_components_to_page(page_file, dest_path, files_list)
        else
          FileUtils.cp(page_file, dest_path)
        end
        
        puts "[调试] 处理页面: #{File.basename(page_file)} -> #{page_name}"
      end
    end
    
    # 将组件文件名列表嵌入到页面图片中（使用隐写术）
    # files_list: 组件压缩包/文件的文件名数组
    def embed_components_to_page(page_path, output_path, files_list)
      begin
        require 'json'
        
        # 将文件名列表转换为 JSON 格式
        files_json = files_list.to_json
        
        # 使用隐写术将文件名列表隐藏在图片中
        image = Book::Steganography.hide(page_path, files_json)
        
        # 保存处理后的图片
        image.save(output_path)
      rescue => e
        puts "[调试] 嵌入文件列表到页面失败: #{e.message}"
        # 如果失败，直接复制原图片
        FileUtils.cp(page_path, output_path)
      end
    end
  end
end
