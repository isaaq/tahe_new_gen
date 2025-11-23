# frozen_string_literal: true

require 'sinatra/base'
require_relative '../../lib/book/scroll_store'
require_relative '../../lib/book/scroll_package'

module ScrollStoreRoutes
  def self.registered(app)
    # 列出所有 scroll（从商店）
    app.get '/scroll-store/list' do
      content_type :json
      
      begin
        store = Book::ScrollStore.instance
        # 暂时返回已安装的，后续可以从商店集合查询
        scrolls = store.list_scrolls
        
        {
          status: 'success',
          count: scrolls.size,
          scrolls: scrolls
        }.to_json
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message,
          backtrace: e.backtrace.first(5)
        }.to_json
      end
    end
    
    # 搜索 scroll
    app.get '/scroll-store/search' do
      content_type :json
      
      begin
        keyword = params['keyword'] || params['q']
        return { status: 'error', error: 'Missing keyword parameter' }.to_json unless keyword
        
        store = Book::ScrollStore.instance
        scrolls = store.list_scrolls
        
        # 简单的关键词过滤
        filtered = scrolls.select do |scroll|
          name = scroll[:name] || ''
          desc = scroll[:description] || ''
          author = scroll[:author] || ''
          
          name.downcase.include?(keyword.downcase) ||
          desc.downcase.include?(keyword.downcase) ||
          author.downcase.include?(keyword.downcase)
        end
        
        {
          status: 'success',
          count: filtered.size,
          scrolls: filtered
        }.to_json
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 获取 scroll 详情
    app.get '/scroll-store/:id' do
      content_type :json
      
      begin
        scroll_id = params['id']
        
        store = Book::ScrollStore.instance
        scroll = store.get_scroll(scroll_id)
        
        if scroll
          {
            status: 'success',
            scroll: scroll
          }.to_json
        else
          status 404
          {
            status: 'error',
            error: 'Scroll not found'
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 上传并安装 scroll
    app.post '/scroll-store/install' do
      content_type :json
      
      begin
        if params[:file] && params[:file][:tempfile]
          # 处理文件上传
          uploaded_file = params[:file][:tempfile]
          original_filename = params[:file][:filename]
          
          unless original_filename.end_with?('.ss')
            return { status: 'error', error: 'Invalid file format. Only .ss files are allowed.' }.to_json
          end
          
          # 保存到临时位置
          temp_path = File.join(Dir.tmpdir, "scroll_upload_#{Time.now.to_i}_#{original_filename}")
          FileUtils.cp(uploaded_file.path, temp_path)
          
          # 安装 scroll
          store = Book::ScrollStore.instance
          result = store.install_scroll(temp_path)
          
          # 清理临时文件
          FileUtils.rm_f(temp_path) rescue nil
          
          if result[:success]
            {
              status: 'success',
              message: result[:message],
              scroll: result[:scroll]
            }.to_json
          else
            status 400
            {
              status: 'error',
              error: result[:error]
            }.to_json
          end
        else
          # 从路径安装
          body = JSON.parse(request.body.read) rescue {}
          scroll_path = body['scroll_path']
          
          unless scroll_path && File.exist?(scroll_path)
            return { status: 'error', error: 'Invalid scroll_path' }.to_json
          end
          
          store = Book::ScrollStore.instance
          result = store.install_scroll(scroll_path, body)
          
          if result[:success]
            {
              status: 'success',
              message: result[:message],
              scroll: result[:scroll]
            }.to_json
          else
            status 400
            {
              status: 'error',
              error: result[:error]
            }.to_json
          end
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message,
          backtrace: e.backtrace.first(5)
        }.to_json
      end
    end
    
    # 卸载 scroll
    app.post '/scroll-store/uninstall' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        scroll_id = body['scroll_id']
        
        return { status: 'error', error: 'Missing scroll_id' }.to_json unless scroll_id
        
        store = Book::ScrollStore.instance
        result = store.uninstall_scroll(scroll_id)
        
        if result[:success]
          {
            status: 'success',
            message: result[:message]
          }.to_json
        else
          status 400
          {
            status: 'error',
            error: result[:error]
          }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 获取已安装的 scroll 列表
    app.get '/scroll-store/installed' do
      content_type :json
      
      begin
        store = Book::ScrollStore.instance
        scrolls = store.list_scrolls
        
        {
          status: 'success',
          count: scrolls.size,
          scrolls: scrolls
        }.to_json
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 获取 scroll 的页面图片（用于在线阅读）
    app.get '/scroll-store/:id/page/:page_number' do
      begin
        scroll_id = params['id']
        page_number = params['page_number'].to_i
        
        store = Book::ScrollStore.instance
        scroll = store.get_scroll(scroll_id)
        
        unless scroll
          status 404
          return { status: 'error', error: 'Scroll not found' }.to_json
        end
        
        # 找到对应的页面信息
        page_info = scroll[:pages_info]&.find { |p| p[:page_number] == page_number }
        
        unless page_info
          status 404
          return { status: 'error', error: 'Page not found' }.to_json
        end
        
        # 从 .ss 文件中提取页面图片
        # 需要找到对应的 .ss 文件（可以从 scroll_store 集合中获取文件路径，或者从已安装的包中提取）
        # 这里先返回页面信息，实际图片数据需要从包中提取
        {
          status: 'success',
          page_info: page_info
        }.to_json
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 获取 scroll 的页面图片数据（二进制）
    app.get '/scroll-store/:id/page/:page_number/image' do
      begin
        scroll_id = params['id']
        page_number = params['page_number'].to_i
        
        store = Book::ScrollStore.instance
        
        # 获取页面图片数据
        image_data = store.get_page_image(scroll_id, page_number)
        
        unless image_data
          status 404
          return 'Page image not found'
        end
        
        # 设置正确的 content-type
        content_type 'image/png'
        
        # 返回图片数据
        image_data
      rescue => e
        status 500
        "Error: #{e.message}"
      end
    end
    
    # 从上传的 .ss 文件中提取页面图片（用于预览）
    app.post '/scroll-store/preview' do
      content_type :json
      
      begin
        if params[:file] && params[:file][:tempfile]
          uploaded_file = params[:file][:tempfile]
          original_filename = params[:file][:filename]
          
          unless original_filename.end_with?('.ss')
            return { status: 'error', error: 'Invalid file format. Only .ss files are allowed.' }.to_json
          end
          
          # 保存到临时位置
          temp_path = File.join(Dir.tmpdir, "scroll_preview_#{Time.now.to_i}_#{original_filename}")
          FileUtils.cp(uploaded_file.path, temp_path)
          
          # 加载 scroll 包
          package = Book::ScrollPackage.new(temp_path)
          if package.load
            # 返回页面信息
            pages_info = package.pages.map do |page|
              {
                page_number: page[:page_number],
                path: File.basename(page[:path]),
                components_count: (page[:component_files] || []).length
              }
            end
            
            # 清理临时文件
            FileUtils.rm_f(temp_path) rescue nil
            
            {
              status: 'success',
              config: package.config,
              pages: pages_info
            }.to_json
          else
            FileUtils.rm_f(temp_path) rescue nil
            { status: 'error', error: 'Failed to load scroll package' }.to_json
          end
        else
          { status: 'error', error: 'No file uploaded' }.to_json
        end
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message,
          backtrace: e.backtrace.first(5)
        }.to_json
      end
    end
  end
end

