require_relative '../../lib/util/auth'
require_relative '../../lib/util/jwt_auth'

class ApiController < Sinatra::Base
  # puts "=== Loading ApiController ==="
  helpers ApplicationHelper
  use Letsaboard::Aboard if defined? Letsaboard::Aboard
  # puts "=== Loading JwtAuth middleware ==="
  use JwtAuth
  # puts "=== JwtAuth middleware loaded ==="

  set :root, Sinatra::Application.settings.root
  set :public_folder, File.expand_path("#{root}/web", __FILE__)
  set :protection, except: %i[frame_options json_csrf]
  set :views, File.expand_path("#{root}/api/views", __FILE__)


  configure do
    # M.change_db(C[:mongo]['use_db'])
    services_list = M[:sys_settings].query({ name: 'services' }).to_a[0]
    services = services_list[:value]
    found = services.find { |f| f[:ip] == C[:ip] && f[:name] == C[:name] }
    if found.nil?
      services << { ip: C[:ip], name: C[:name], port: C[:port], status: 1 }
    else
      found[:status] = 1
    end
    puts services_list
    M[:sys_settings].update({ name: 'services' }, services_list)
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['X-Frame-Options'] = 'allow-from *'
    content_type :json
    check_auth
    status 200
  end

  # 注册解析引擎路由
  register ParseRoutes
  register FeedbackRoutes

  after do
    _routes
  end

  options '*' do
    response.headers['Allow'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token'
    response.headers['Access-Control-Allow-Origin'] = '*'
    200
  end

  not_found do
    path = env['REQUEST_PATH'].gsub('/api', '')
    func = M[:sys_funcs].query(type: 'sinatra', name: /#{path}/).to_a[0]
    unless func.nil?
      cnt = func[:content].gsub(/(M\[:\w+\])\.find/, '\\1.query')
      eval(cnt)
    end
  end

  get '/' do
    'it works'
  end
  
  # 辅助方法：渲染kr标签库模板
  def kr(template)
    content_type :html
    erb_content = File.read(File.join(settings.views, "#{template}.erb"))
    puts "DEBUG: 原始模板内容:\n#{erb_content}"
    
    # 第一步解析：kr 标签
    parsed_content = UIPage.new(:kr).parse_code(erb_content)
    puts "DEBUG: kr 解析后内容:\n#{parsed_content}"
    
    # 第二步解析：layui 标签
    parsed_content = UIPage.new(:layui).parse_code(parsed_content)
    puts "DEBUG: layui 解析后内容:\n#{parsed_content}"
    
    parsed_content
  end
end
