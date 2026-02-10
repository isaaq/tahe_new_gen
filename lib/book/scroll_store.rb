require 'singleton'
require 'yaml'
require 'fileutils'
require_relative '../util/common'
require_relative 'scroll_package'

module Book
  class ScrollStore
    include Singleton
    
    STORE_COLLECTION = 'scroll_store'
    INSTALLED_COLLECTION = 'installed_scrolls'
    COMPONENTS_COLLECTION = 'scroll_components'
    
    def initialize
      @memory_cache = {}  # 内存缓存
    end
    
    # ========== Scroll 查询 ==========
    
    # 列出所有已安装的 scroll
    def list_scrolls
      installed_scrolls = Common::M[INSTALLED_COLLECTION].query.to_a
      
      installed_scrolls.map do |installed_scroll|
        scroll = get_scroll(installed_scroll['scroll_id'])
        scroll || format_installed_scroll(installed_scroll)
      end
    end
    
    # 获取 scroll 详情
    def get_scroll(scroll_id)
      scroll = Common::M[STORE_COLLECTION].query(scroll_id: scroll_id).first
      return nil unless scroll
      
      format_scroll(scroll)
    end
    
    # 检查 scroll 是否已安装
    def installed?(scroll_id)
      installed_scrolls = Common::M[INSTALLED_COLLECTION].query.to_a
      installed_scrolls.any? { |s| s['scroll_id'] == scroll_id }
    end
    
    # ========== Scroll 安装 ==========
    
    # 安装 scroll
    def install_scroll(scroll_path, options = {})
      begin
        puts "[调试] 开始安装 scroll: #{scroll_path}"
        
        # 验证文件存在
        unless File.exist?(scroll_path) && scroll_path.end_with?('.ss')
          return { success: false, error: '无效的 .ss 文件' }
        end
        
        # 加载 scroll 包
        package = ScrollPackage.new(scroll_path)
        unless package.load
          return { success: false, error: '无法加载 .ss 文件' }
        end
        
        # 生成 scroll_id
        scroll_id = options[:scroll_id] || generate_scroll_id(package.config)
        
        # 检查是否已安装
        if installed?(scroll_id)
          return { success: false, error: 'Scroll 已安装' }
        end
        
        # 准备 scroll 元数据
        # 保存 .ss 文件路径（如果是从文件系统安装的）
        file_path = nil
        if File.exist?(scroll_path)
          file_path = File.expand_path(scroll_path)
        end
        
        scroll_meta = {
          scroll_id: scroll_id,
          name: package.config['name'] || File.basename(scroll_path, '.ss'),
          description: package.config['description'] || '',
          version: package.config['version'] || '1.0.0',
          author: package.config['author'] || 'unknown',
          pages_count: package.pages.length,
          installed_at: Time.now,
          config: package.config,
          file_path: file_path,  # 保存文件路径用于后续访问
          pages_info: package.pages.map do |page|
            {
              page_number: page[:page_number],
              path: File.basename(page[:path]),
              components_count: (page[:component_files] || []).length
            }
          end
        }
        
        # 保存 scroll 元数据到数据库
        Common::M[STORE_COLLECTION].add(scroll_meta)
        puts "[调试] 保存 scroll 元数据: #{scroll_id}"
        
        # 提取并保存所有组件（从页面中提取的文件名列表，找到文件并安装到数据库）
        components_result = install_components(scroll_id, package)
        unless components_result[:success]
          # 如果组件安装失败，回滚 scroll 元数据
          Common::M[STORE_COLLECTION].del(scroll_id: scroll_id) if scroll_meta
          # 清理临时目录
          package.cleanup_temp_dir if package.respond_to?(:cleanup_temp_dir)
          return { success: false, error: components_result[:error] }
        end
        
        # 标记为已安装
        mark_as_installed(scroll_id, scroll_meta[:version])
        
        puts "[调试] Scroll 安装成功: #{scroll_id}"
        
        # 清理临时目录（可选，如果需要保留可以注释掉）
        # package.cleanup_temp_dir if package.respond_to?(:cleanup_temp_dir)
        
        { success: true, scroll: format_scroll(scroll_meta), message: 'Scroll 安装成功' }
      rescue => e
        puts "[调试] 安装 scroll 时发生异常: #{e.message}"
        puts e.backtrace.join("\n")
        # 清理临时目录
        package.cleanup_temp_dir if package.respond_to?(:cleanup_temp_dir) rescue nil
        { success: false, error: e.message, backtrace: e.backtrace.first(5) }
      end
    end
    
    # 卸载 scroll
    def uninstall_scroll(scroll_id)
      begin
        puts "[调试] 开始卸载 scroll: #{scroll_id}"
        
        scroll = get_scroll(scroll_id)
        unless scroll
          return { success: false, error: 'Scroll 不存在' }
        end
        
        unless installed?(scroll_id)
          return { success: false, error: 'Scroll 未安装' }
        end
        
        # 删除所有组件（按 scroll_id 组织，不影响其他 scroll）
        remove_components(scroll_id)
        puts "[调试] 删除 scroll 组件: #{scroll_id}"
        
        # 从已安装列表中移除
        mark_as_uninstalled(scroll_id)
        
        # 注意：不删除 scroll 元数据，保留历史记录
        
        puts "[调试] Scroll 卸载成功: #{scroll_id}"
        { success: true, message: 'Scroll 卸载成功' }
      rescue => e
        puts "[调试] 卸载 scroll 时发生异常: #{e.message}"
        puts e.backtrace.join("\n")
        { success: false, error: e.message }
      end
    end
    
    # 获取 scroll 的所有组件
    def get_scroll_components(scroll_id)
      Common::M[COMPONENTS_COLLECTION].query(scroll_id: scroll_id).to_a
    end
    
    # 获取 scroll 的页面图片数据（用于在线阅读）
    # 返回页面图片的二进制数据
    def get_page_image(scroll_id, page_number)
      # 从 scroll_store 集合获取 scroll 信息
      scroll_doc = Common::M[STORE_COLLECTION].query(scroll_id: scroll_id).first
      return nil unless scroll_doc
      
      file_path = scroll_doc['file_path']
      return nil unless file_path && File.exist?(file_path)
      
      # 加载 scroll 包
      package = ScrollPackage.new(file_path)
      return nil unless package.load
      
      # 找到对应的页面
      page = package.pages.find { |p| p[:page_number] == page_number }
      return nil unless page && page[:path] && File.exist?(page[:path])
      
      # 读取页面图片数据
      File.binread(page[:path])
    rescue => e
      puts "[调试] 获取页面图片失败: #{e.message}"
      nil
    end
    
    # ========== 私有方法 ==========
    
    private
    
    # 生成 scroll_id
    def generate_scroll_id(config)
      name = config['name'] || 'unknown'
      version = config['version'] || '1.0.0'
      
      # 使用名称和版本生成唯一 ID
      "#{name.downcase.gsub(/[^a-z0-9]/, '_')}_#{version.gsub(/[^a-z0-9]/, '_')}"
    end
    
    # 安装组件到数据库（从页面中提取的文件名列表，找到文件并安装）
    def install_components(scroll_id, package)
      begin
        require 'zip'
        require 'json'
        
        components_installed = []
        temp_dir = package.get_temp_dir
        
        unless temp_dir && Dir.exist?(temp_dir)
          return { success: false, error: '临时目录不存在' }
        end
        
        package.pages.each_with_index do |page, page_index|
          page_number = page[:page_number]
          component_files = page[:component_files] || []
          
          component_files.each_with_index do |file_info, comp_index|
            file_name = file_info['name']
            file_path = file_info['path'] || File.join(temp_dir, file_name)
            file_type = file_info['type'] || 'file'
            
            # 验证文件是否存在
            unless File.exist?(file_path)
              puts "[警告] 组件文件不存在: #{file_name}"
              next
            end
            
            # 为每个组件生成唯一 ID
            component_id = "#{scroll_id}_page#{page_number}_comp#{comp_index}"
            
            # 根据文件类型处理
            component_content = nil
            component_type = file_type
            
            if file_type == 'zip'
              # 如果是压缩包，解压并读取所有文件内容
              begin
                component_content = extract_zip_content(file_path)
                component_type = 'zip_package'
              rescue => e
                puts "[警告] 解压组件压缩包失败 #{file_name}: #{e.message}"
                next
              end
            else
              # 如果是普通文件，直接读取内容
              begin
                component_content = {
                  'file_name' => file_name,
                  'content' => File.read(file_path),
                  'size' => File.size(file_path)
                }
                component_type = File.extname(file_name).downcase.sub('.', '') || 'file'
              rescue => e
                puts "[警告] 读取组件文件失败 #{file_name}: #{e.message}"
                next
              end
            end
            
            component_data = {
              component_id: component_id,
              scroll_id: scroll_id,
              page_number: page_number,
              component_index: comp_index,
              component_type: component_type,
              file_name: file_name,
              component_data: component_content,
              installed_at: Time.now
            }
            
            # 保存组件到数据库（按 scroll_id 组织）
            Common::M[COMPONENTS_COLLECTION].add(component_data)
            components_installed << component_id
            puts "[调试] 安装组件: #{file_name} (#{component_type})"
          end
        end
        
        puts "[调试] 安装了 #{components_installed.length} 个组件"
        { success: true, components_count: components_installed.length }
      rescue => e
        puts "[调试] 安装组件时发生异常: #{e.message}"
        puts e.backtrace.join("\n")
        { success: false, error: e.message }
      end
    end
    
    # 解压 ZIP 文件并提取所有文件内容
    def extract_zip_content(zip_path)
      files_content = {}
      
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          # 跳过目录
          next if entry.directory?
          
          # 读取文件内容
          begin
            content = entry.get_input_stream.read
            files_content[entry.name] = {
              'content' => content,
              'size' => entry.size
            }
          rescue => e
            puts "[警告] 读取压缩包中的文件失败 #{entry.name}: #{e.message}"
          end
        end
      end
      
      {
        'zip_file' => File.basename(zip_path),
        'files' => files_content
      }
    end
    
    # 删除 scroll 的所有组件
    def remove_components(scroll_id)
      # 只删除属于该 scroll_id 的组件，不影响其他 scroll
      components = Common::M[COMPONENTS_COLLECTION].query(scroll_id: scroll_id).to_a
      deleted_count = components.length
      
      # 删除所有组件
      components.each do |component|
        Common::M[COMPONENTS_COLLECTION].del(component_id: component['component_id'])
      end
      
      puts "[调试] 删除了 #{deleted_count} 个组件"
    end
    
    # 标记为已安装
    def mark_as_installed(scroll_id, version)
      installed_data = {
        scroll_id: scroll_id,
        version: version,
        installed_at: Time.now
      }
      
      # 检查是否已存在
      existing = Common::M[INSTALLED_COLLECTION].query(scroll_id: scroll_id).first
      if existing
        Common::M[INSTALLED_COLLECTION].update({scroll_id: scroll_id}, installed_data)
      else
        Common::M[INSTALLED_COLLECTION].add(installed_data)
      end
    end
    
    # 标记为未安装
    def mark_as_uninstalled(scroll_id)
      # 删除已安装记录
      installed = Common::M[INSTALLED_COLLECTION].query(scroll_id: scroll_id).first
      Common::M[INSTALLED_COLLECTION].del(scroll_id: scroll_id) if installed
    end
    
    # 格式化 scroll 信息
    def format_scroll(scroll_doc)
      {
        scroll_id: scroll_doc['scroll_id'],
        name: scroll_doc['name'],
        description: scroll_doc['description'],
        version: scroll_doc['version'],
        author: scroll_doc['author'],
        pages_count: scroll_doc['pages_count'] || 0,
        installed_at: scroll_doc['installed_at'],
        config: scroll_doc['config'] || {},
        pages_info: scroll_doc['pages_info'] || [],
        installed: installed?(scroll_doc['scroll_id'])
      }
    end
    
    # 格式化已安装的 scroll 信息
    def format_installed_scroll(installed_doc)
      {
        scroll_id: installed_doc['scroll_id'],
        version: installed_doc['version'],
        installed_at: installed_doc['installed_at'],
        installed: true
      }
    end
  end
end

