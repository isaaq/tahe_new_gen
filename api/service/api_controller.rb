class ApiController < Sinatra::Base
  helpers ApplicationHelper
  use Letsaboard::Aboard if defined? Letsaboard::Aboard

  # register to cloud

  services_list = M[:sys_settings].query({ name: 'services'}).to_a[0]
  services = services_list[:value]
  found = services.find {|f| f[:ip] == C[:ip] && f[:name] == C[:name]}
  if found.nil?
    services << {ip: C[:ip], name: C[:name], port: C[:port], status: 1}
  else
    found[:status] = 1
  end
  puts services_list
  M[:sys_settings].update({ name: 'services'}, services_list)

  before do
    check_auth
  end

  after do
    _routes
  end

  not_found do
    path = env['REQUEST_PATH'].gsub('/api','')
    func = M[:sys_funcs].query(type: 'sinatra', name: /#{path}/).to_a[0]
    cnt = func[:content].gsub(/(M\[:\w+\])\.find/, "\\1.query")
    eval(cnt)
  end

  get '/' do
    'it works'
  end

end
