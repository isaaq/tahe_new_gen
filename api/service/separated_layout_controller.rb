#!/usr/bin/env ruby
# 支持布局与内容分离的控制器
# 用于动态渲染分离的布局和内容文件

require 'sinatra/base'
require_relative '../../_system'
require_relative '../../lib/util/common'
require_relative '../../lib/ui/ui_impl/kr_layout_parser'
require_relative '../../lib/ui/ui_impl/kr_content_parser'
require_relative '../../lib/ui/ui_impl/kr_merged_layout_generator'

class SeparatedLayoutController < Sinatra::Base
  set :root, File.expand_path('../..', __dir__)
  set :public_folder, File.join(settings.root, 'web/static')
  set :views, File.join(settings.root, 'web/views')
  
  # 启用静态文件服务
  enable :static
  
  # 启用会话
  enable :sessions
  
  # 配置
  configure do
    set :layout_dir, File.join(settings.root, 'demo')
    set :content_dir, File.join(settings.root, 'demo')
  end
  
  # 主页，显示可用的布局和内容文件
  get '/' do
    @layout_files = Dir.glob(File.join(settings.layout_dir, '*.json'))
                       .map { |f| File.basename(f) }
                       .sort
    
    @content_files = Dir.glob(File.join(settings.content_dir, '*.xml'))
                        .map { |f| File.basename(f) }
                        .sort
    
    erb :separated_layout_index
  end
  
  # 渲染指定的布局和内容文件
  get '/render' do
    layout_file = params[:layout]
    content_file = params[:content]
    
    if layout_file.nil? || content_file.nil?
      return "请指定布局文件和内容文件"
    end
    
    layout_path = File.join(settings.layout_dir, layout_file)
    content_path = File.join(settings.content_dir, content_file)
    
    unless File.exist?(layout_path) && File.exist?(content_path)
      return "布局文件或内容文件不存在"
    end
    
    begin
      # 解析布局和内容文件
      layout_config = KrLayoutParser.parse_file(layout_path)
      content_map = KrContentParser.parse_file(content_path)
      
      # 合并布局和内容，生成页面
      result = KrMergedLayoutGenerator.generate(layout_config, content_map)
      
      # 渲染完整页面
      erb :separated_layout_page, locals: {
        title: layout_config[:title] || "布局与内容分离演示",
        html: result[:html],
        css: result[:css],
        js: result[:js]
      }
    rescue => e
      "渲染错误: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end
  
  # 渲染项目立项信息登记表单示例
  get '/project_form' do
    layout_file = 'project_registration_layout.json'
    content_file = 'project_registration_content.xml'
    
    layout_path = File.join(settings.layout_dir, layout_file)
    content_path = File.join(settings.content_dir, content_file)
    
    begin
      # 解析布局和内容文件
      layout_config = KrLayoutParser.parse_file(layout_path)
      content_map = KrContentParser.parse_file(content_path)
      
      # 合并布局和内容，生成页面
      result = KrMergedLayoutGenerator.generate(layout_config, content_map)
      
      # 渲染完整页面
      erb :separated_layout_page, locals: {
        title: "立项信息登记表单 - 布局与内容分离版",
        html: result[:html],
        css: result[:css],
        js: result[:js]
      }
    rescue => e
      "渲染错误: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end
  
  # 设计器模式
  get '/designer' do
    layout_file = params[:layout] || 'project_registration_layout.json'
    content_file = params[:content] || 'project_registration_content.xml'
    
    layout_path = File.join(settings.layout_dir, layout_file)
    content_path = File.join(settings.content_dir, content_file)
    
    begin
      # 解析布局和内容文件
      layout_config = KrLayoutParser.parse_file(layout_path)
      content_map = KrContentParser.parse_file(content_path)
      
      # 合并布局和内容，生成页面
      result = KrMergedLayoutGenerator.generate(layout_config, content_map)
      
      # 渲染设计器页面
      erb :separated_layout_designer, locals: {
        title: "布局设计器 - #{layout_file}",
        layout_file: layout_file,
        content_file: content_file,
        layout_config: layout_config.to_json,
        content_map: content_map.to_json,
        html: result[:html],
        css: result[:css],
        js: result[:js]
      }
    rescue => e
      "渲染错误: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end
  
  # 启动服务器
  run! if app_file == $0
end
