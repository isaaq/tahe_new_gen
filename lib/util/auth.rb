# frozen_string_literal: true
require 'jwt'
require_relative '../util/error'
# typed: true
module Auth
  include Common

  C = YAML.load_file('./config.yml')
  def fetch_token(opt = {})
    token = JWT.encode payload(opt), C['JWT_SECRET'], 'HS256'
    { token: token }.to_json
  end

  def fetch_token_hash(opt = {})
    token = JWT.encode payload(opt), C['JWT_SECRET'], 'HS256'
    { token: token }
  end

  def payload(opt = {})
    u = M[:用户].query(_id: opt[:uid].to_objid).to_a[0]
    raise AccountError.new('用户不存在', ErrorCode::ACCOUNT) if u.nil?
    {
      exp: Time.now.to_i + 60 * 60 * 24 * 7,
      iat: Time.now.to_i,
      iss: C['JWT_ISSUER'],
      scopes: get_scopes(u),
      user: {
        uid: opt[:uid],
        created_at: DateTime.now,
        roles: get_roles(u),
      }
    }
  end

  def get_roles(u)
    u[:roles]
  end

  def get_scopes(u)
    u[:scopes]
  end
end
