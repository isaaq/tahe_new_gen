require 'sinatra/base'

# 网格布局演示控制器
# 用于演示通过控制器调用解释器处理网格布局DSL
class GridDemoController < Sinatra::Base
  
  # 立项信息登记表单演示
  get '/ui/grid/project_form' do
    content_type :html
    
    # 修正路径，指向项目根目录下的demo文件夹
    project_root = File.expand_path('../../../', __FILE__)
    html_file = File.join(project_root, 'demo/project_registration_form.html')
    
    if File.exist?(html_file)
      File.read(html_file)
    else
      status 404
      "HTML文件未找到: #{html_file}"
    end
  end
  
  # 健康检查端点
  get '/health' do
    content_type :json
    { status: 'ok', message: 'GridDemoController is running' }.to_json
  end
  
end
