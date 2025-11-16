# frozen_string_literal: true

require 'sinatra/base'

class EmployeeController < Sinatra::Base
  set :root, Sinatra::Application.settings.root
  set :views, File.expand_path("#{root}/api/views", __FILE__)
  
  # 员工管理页面
  get '/employees' do
    content_type :html
    
    # 读取 ERB 模板
    erb_content = File.read(File.join(settings.views, 'employee_management.erb'))
    
    # 第一步解析：kr 标签
    kr_parsed = UIPage.new(:kr).parse_code(erb_content)
    
    # 第二步解析：layui 标签
    final_html = UIPage.new(:layui).parse_code(kr_parsed)
    
    final_html
  end
  
  # 健康检查
  get '/health' do
    content_type :json
    {
      status: 'ok',
      services: {
        relation_registry: defined?(RelationRegistry) ? 'loaded' : 'not_loaded',
        query_engine: defined?(MongoQueryEngine) ? 'loaded' : 'not_loaded',
        template_manager: defined?(TemplateManager) ? 'loaded' : 'not_loaded'
      }
    }.to_json
  end
end




