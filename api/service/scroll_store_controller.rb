# frozen_string_literal: true

require 'sinatra/base'

class ScrollStoreController < Sinatra::Base
  set :root, Sinatra::Application.settings.root
  set :views, File.expand_path("#{root}/api/views", __FILE__)
  
  # Scroll 商店主界面
  get '/store' do
    content_type :html
    
    # 读取 ERB 模板
    erb_content = File.read(File.join(settings.views, 'scroll_store.erb'))
    
    # 第一步解析：kr 标签
    kr_parsed = UIPage.new(:kr).parse_code(erb_content)
    
    # 第二步解析：layui 标签
    final_html = UIPage.new(:layui).parse_code(kr_parsed)
    
    final_html
  end
  
  # Scroll 详情页面
  get '/detail/:id' do
    content_type :html
    
    scroll_id = params['id']
    
    # 读取 ERB 模板（可以使用同一个模板，根据参数显示不同内容）
    erb_content = File.read(File.join(settings.views, 'scroll_store.erb'))
    
    # 解析模板
    kr_parsed = UIPage.new(:kr).parse_code(erb_content)
    final_html = UIPage.new(:layui).parse_code(kr_parsed)
    
    final_html
  end
  
  # 在线阅读页面
  get '/read/:id' do
    content_type :html
    
    scroll_id = params['id']
    page = params['page'] || 1
    
    # 读取 ERB 模板
    erb_content = File.read(File.join(settings.views, 'scroll_store.erb'))
    
    # 解析模板
    kr_parsed = UIPage.new(:kr).parse_code(erb_content)
    final_html = UIPage.new(:layui).parse_code(kr_parsed)
    
    final_html
  end
end

