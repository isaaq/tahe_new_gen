module ApplicationHelper
  include Common
  def _params
    body = request.body.read
    params.delete_if {|k,v| k.start_with?('__')}
    return params if body == ''
    json = {}
    begin
      json = JSON.parse(body, { symbolize_names: true })
    rescue
      json = body
    end
    # json.merge(params).transform_keys(&:to_sym)
    o = json || params
    o.delete_if {|k,v| k.start_with?('__')} if o.is_a?(Hash)
    o
  end

  def _user
    env[:user]
  end

  def _roles
    env[:user]['roles']
  end

  def _scopes
    env[:scopes]
  end

  def make_resp(data, code = 0, msg = 'success')
    { code: code, msg: msg, data: data || {} }.to_json
  end

  def ok
    ''.to_resp
  end

  def token

  end

  def check_auth

  end

  def _routes
    self.class.routes.each do |rinfo|
      if %w[GET POST PUT DELETE].include?(rinfo[0])
        cached = R.hkeys('routes')
        rinfo[1].each do |rt|
          url = rt[0].safe_string
          if cached.include?(url)

          else
            R.hset('routes', url, {}.to_json)
          end
        end
      end
    end
  end
end

class Object
  include ApplicationHelper

  def to_resp
    make_resp(self, 0, 'success')
  end

  def to_paged_resp(num, size, totalcount)
    { code: 0, msg: 'success', data: self, count: totalcount || {} }.to_json
  end
end