class ApiController < Sinatra::Base
  helpers ApplicationHelper
  use Letsaboard::Aboard if defined? Letsaboard::Aboard

  set :root, Sinatra::Application.settings.root
  set :public_folder, File.expand_path("#{root}/web", __FILE__)
  set :protection, except: %i[frame_options json_csrf]

  # register to cloud

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

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['X-Frame-Options'] = 'allow-from *'
    content_type :json
    check_auth
    status 200
  end

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
end
