# frozen_string_literal: true

require 'sinatra/base'
require_relative '../models/kr_tag_generator_parser'
require_relative '../models/schema_generator_parser'
require_relative '../../lib/ui/ui_impl/schema_to_kr_converter'
require 'fileutils'

module KrTagGenerationRoutes
  def self.registered(app)
    # 路径1：自然语言 → AI → kr标签（直接生成）
    app.post '/generate-kr-tags' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        requirement = body['requirement'] || body['content']
        
        # 使用Kr标签生成器
        generator = KrTagGeneratorParser.new
        result = generator.parse({
          'content' => requirement,
          '_meta' => {
            'parser' => 'kr_tag_generator',
            'type' => 'kr_tags'
          }
        })
        
        # 保存kr标签到数据库
        tag_id = KrTagGenerationRoutes.save_kr_tags(result)
        
        # 可选：保存到文件
        KrTagGenerationRoutes.save_kr_tags_to_file(result) if body['save_to_file']
        
        tag_record = result['tag_record'] || result[:tag_record] || {}
        {
          status: 'success',
          tag_id: tag_id,
          kr_tags: result['kr_tags'] || result[:kr_tags] || '',
          file_path: tag_record[:file_path] || tag_record['file_path'] || ''
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
    
    # 路径2：schema → kr标签
    app.post '/schema-to-kr-tags' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        schema = body['schema']
        
        # 使用Schema转换器
        kr_tags = SchemaToKrConverter.convert(schema)
        
        # 保存
        tag_id = KrTagGenerationRoutes.save_kr_tags({
          'kr_tags' => kr_tags,
          'tag_record' => {
            name: "from_schema_#{Time.now.to_i}",
            file_path: "api/views/generated_from_schema.erb"
          }
        })
        
        {
          status: 'success',
          tag_id: tag_id,
          kr_tags: kr_tags,
          file_path: "api/views/generated_from_schema.erb"
        }.to_json
        
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 路径3：自然语言 → schema → kr标签（两步生成）
    app.post '/generate-schema-then-kr-tags' do
      content_type :json
      
      begin
        body = JSON.parse(request.body.read)
        requirement = body['requirement']
        
        # 步骤1：生成schema
        schema_generator = SchemaGeneratorParser.new
        schema_result = schema_generator.parse({
          'content' => requirement,
          '_meta' => { 'parser' => 'schema_generator' }
        })
        
        schema_id = KrTagGenerationRoutes.save_schema(schema_result)
        
        # 步骤2：从schema生成kr标签
        kr_tags = SchemaToKrConverter.convert(schema_result['schema'])
        
        tag_id = KrTagGenerationRoutes.save_kr_tags({
          'kr_tags' => kr_tags,
          'tag_record' => {
            name: "from_schema_#{schema_id}",
            file_path: "api/views/generated_from_schema_#{schema_id}.erb"
          }
        })
        
        {
          status: 'success',
          schema_id: schema_id,
          tag_id: tag_id,
          schema: schema_result['schema'],
          kr_tags: kr_tags
        }.to_json
        
      rescue => e
        status 500
        {
          status: 'error',
          error: e.message
        }.to_json
      end
    end
    
    # 获取已生成的kr标签列表
    app.get '/kr-tags' do
      content_type :json
      tags = M[:kr_tags].query({}).sort(created_at: -1).to_a
      { status: 'success', kr_tags: tags }.to_json
    end
    
    # 获取单个kr标签
    app.get '/kr-tags/:id' do
      content_type :json
      tag_doc = M[:kr_tags].query(_id: BSON::ObjectId(params[:id])).first
      { status: 'success', kr_tags: tag_doc }.to_json
    end
    
    # 获取已生成的schema列表
    app.get '/schemas' do
      content_type :json
      schemas = M[:crud_schemas].query({}).sort(created_at: -1).to_a
      { status: 'success', schemas: schemas }.to_json
    end
    
    # 获取单个schema
    app.get '/schemas/:id' do
      content_type :json
      schema = M[:crud_schemas].query(_id: BSON::ObjectId(params[:id])).first
      { status: 'success', schema: schema }.to_json
    end
    
    # 预览kr标签
    app.get '/preview-kr-tags' do
      content_type :html
      # 允许在 iframe 中显示
      response.headers['X-Frame-Options'] = 'SAMEORIGIN'
      
      # 从URL参数获取kr标签（备用方案）
      kr_tags_from_url = params['kr_tags'] || ''
      
      result = "<!DOCTYPE html>\n"
      result += "<html>\n"
      result += "<head>\n"
      result += "  <meta charset=\"utf-8\">\n"
      result += "  <title>预览页面</title>\n"
      result += "  <link href=\"//unpkg.com/layui@2.12.1/dist/css/layui.css\" rel=\"stylesheet\">\n"
      result += "  <style>\n"
      result += "    body { padding: 20px; }\n"
      result += "    .preview-container { min-height: 400px; }\n"
      result += "  </style>\n"
      result += "</head>\n"
      result += "<body>\n"
      result += "  <div class=\"layui-card\">\n"
      result += "    <div class=\"layui-card-header\">预览内容</div>\n"
      result += "    <div class=\"layui-card-body preview-container\" id=\"preview-content\">\n"
      result += "      <div class=\"layui-loading\" style=\"text-align: center; padding: 50px;\">\n"
      result += "        <i class=\"layui-icon layui-icon-loading layui-anim layui-anim-rotate layui-anim-loop\"></i>\n"
      result += "        <p>正在加载预览...</p>\n"
      result += "      </div>\n"
      result += "    </div>\n"
      result += "  </div>\n"
      result += "  \n"
      result += "  <script src=\"//unpkg.com/layui@2.12.1/dist/layui.js\"></script>\n"
      result += "  <script>\n"
      result += "    var krTagsToRender = '';\n"
      
      # 如果有URL参数，使用更安全的方式处理
      if !kr_tags_from_url.empty?
        # 使用URLSearchParams API安全地解析URL参数，避免JavaScript注入问题
        result += "    try {\n"
        result += "      var urlParams = new URLSearchParams(window.location.search);\n"
        result += "      krTagsToRender = decodeURIComponent(urlParams.get('kr_tags') || '');\n"
        result += "      if (krTagsToRender) {\n"
        result += "        renderKrTags(krTagsToRender);\n"
        result += "      }\n"
        result += "    } catch(e) {\n"
        result += "      console.error('Failed to parse URL parameter:', e);\n"
        result += "    }\n"
      end
      
      result += "    \n"
      result += "    // 监听来自父窗口的消息（postMessage方式）\n"
      result += "    window.addEventListener('message', function(event) {\n"
      result += "      if (event.data && event.data.type === 'kr_tags_content') {\n"
      result += "        krTagsToRender = event.data.content;\n"
      result += "        renderKrTags(krTagsToRender);\n"
      result += "      }\n"
      result += "    });\n"
      result += "    \n"
      result += "    // 渲染函数\n"
      result += "    function renderKrTags(krTags) {\n"
      result += "      if (!krTags || !krTags.trim()) {\n"
      result += "        document.getElementById('preview-content').innerHTML = \n"
      result += "          '<div class=\"layui-alert layui-alert-warning\">没有可渲染的内容</div>';\n"
      result += "        return;\n"
      result += "      }\n"
      result += "      \n"
      result += "      fetch('/api/render-kr-tags', {\n"
      result += "        method: 'POST',\n"
      result += "        headers: { 'Content-Type': 'application/json' },\n"
      result += "        body: JSON.stringify({ kr_tags: krTags })\n"
      result += "      })\n"
      result += "      .then(response => response.text())\n"
      result += "      .then(html => {\n"
      result += "        document.getElementById('preview-content').innerHTML = html;\n"
      result += "      })\n"
      result += "      .catch(error => {\n"
      result += "        document.getElementById('preview-content').innerHTML = \n"
      result += "          '<div class=\"layui-alert layui-alert-danger\">渲染失败：' + error.message + '</div>';\n"
      result += "      });\n"
      result += "    }\n"
      result += "  </script>\n"
      result += "</body>\n"
      result += "</html>\n"
      result
    end
    
    # 渲染kr标签为HTML
    app.post '/render-kr-tags' do
      content_type :html
      # 允许在 iframe 中显示
      response.headers['X-Frame-Options'] = 'SAMEORIGIN'
      
      begin
        body = JSON.parse(request.body.read)
        kr_tags = body['kr_tags'] || body[:kr_tags] || ''
        
        if kr_tags.empty?
          return '<div class="layui-alert layui-alert-warning">没有可渲染的内容</div>'
        end
        
        # 第一步解析：kr 标签
        kr_parsed = UIPage.new(:kr).parse_code(kr_tags)
        
        # 第二步解析：layui 标签
        final_html = UIPage.new(:layui).parse_code(kr_parsed)
        
        final_html
      rescue => e
        '<div class="layui-alert layui-alert-danger">渲染错误：' + e.message + '</div>'
      end
    end
    
    # 辅助方法：保存kr标签到数据库
    def self.save_kr_tags(result)
      # 处理不同的结果结构
      tag_record = result['tag_record'] || result[:tag_record] || {}
      kr_tags = result['kr_tags'] || result[:kr_tags] || ''
      
      tag_doc = {
        name: tag_record[:name] || tag_record['name'] || "generated_#{Time.now.to_i}",
        content: kr_tags,
        original_requirement: tag_record[:original_requirement] || tag_record['original_requirement'] || result['content'] || result[:content] || '',
        file_path: tag_record[:file_path] || tag_record['file_path'] || "api/views/generated_#{Time.now.to_i}.erb",
        created_at: Time.now,
        updated_at: Time.now,
        status: 'generated',
        type: 'kr_tags'
      }
      
      M[:kr_tags].add(tag_doc)
      tag_doc[:_id].to_s
    end
    
    # 辅助方法：保存kr标签到文件
    def self.save_kr_tags_to_file(result)
      tag_record = result['tag_record'] || result[:tag_record] || {}
      file_path = tag_record[:file_path] || tag_record['file_path'] || "api/views/generated_#{Time.now.to_i}.erb"
      kr_tags = result['kr_tags'] || result[:kr_tags] || ''
      
      # 确保目录存在
      FileUtils.mkdir_p(File.dirname(file_path))
      
      # 保存到文件
      File.write(file_path, kr_tags)
    end
    
    # 辅助方法：保存schema到数据库
    def self.save_schema(schema_result)
      schema_doc = {
        name: schema_result['schema_record'][:name],
        type: schema_result['schema_record'][:type],
        schema: schema_result['schema'],
        original_requirement: schema_result['schema_record'][:original_requirement],
        created_at: Time.now,
        updated_at: Time.now,
        status: 'generated'
      }
      
      M[:crud_schemas].add(schema_doc)
      schema_doc[:_id].to_s
    end
  end
end

