class JwtAuth
  include Common
  C = YAML.load_file("./config.yml")

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      options = { algorithm: "HS256", iss: C["JWT_ISSUER"] }
      bearer = env.fetch("HTTP_AUTHORIZATION", "").slice(7..-1)
      if env.include?("HTTP_COOKIE")
        cookie_string = env.fetch("HTTP_COOKIE")
        cookies = revert_hash_from_string(cookie_string)
        bearer = cookies[:token] if bearer.nil?
      end
      req_path = env.fetch("REQUEST_PATH", "")
      ip = env.fetch("REMOTE_ADDR")
      if req_path != "/buc/user/reg" && !req_path.match(/assets\/.+/) && req_path != "/buc/user/reg" && !req_path.match(/assets\/.+/) \
        && req_path != "/auth/app/password" && req_path != "/auth/app/vcode" && req_path != "/auth/app/f_password" \
        && req_path != "/auth/app/message"
        payload, header = JWT.decode bearer, C["JWT_SECRET"], true, options
        env[:scopes] = payload["scopes"]
        env[:user] = payload["user"]
      end

      @app.call env
    rescue JWT::DecodeError => ex
      @app.call env
    rescue JWT::ExpiredSignature
      [200, { "Content-Type" => "application/json" }, [{ code: 5000, msg: "The token has expired." }.to_json]]
    rescue JWT::InvalidIssuerError
      [200, { "Content-Type" => "application/json" }, [{ code: 5000, msg: "The token does not have a valid issuer." }.to_json]]
    rescue JWT::InvalidIatError
      [200, { "Content-Type" => "application/json" }, [{ code: 5000, msg: 'The token does not have a valid "issued at" time.' }.to_json]]
    end
  end
end
