# frozen_string_literal: true

require 'sinatra/base'

class AiGeneratorController < Sinatra::Base
  set :root, Sinatra::Application.settings.root
  set :views, File.expand_path("#{root}/api/views", __FILE__)
  
  # AI生成器管理界面
  get '/generator' do
    content_type :html
    
    # 读取 ERB 模板
    erb_content = File.read(File.join(settings.views, 'ai_generator.erb'))
    
    # 第一步解析：kr 标签
    kr_parsed = UIPage.new(:kr).parse_code(erb_content)
    
    # 第二步解析：layui 标签
    final_html = UIPage.new(:layui).parse_code(kr_parsed)
    
    final_html
  end
end

