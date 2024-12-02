# frozen_string_literal: true

# typed: true
module Auth
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
    {
      exp: Time.now.to_i + 60 * 60 * 24 * 7,
      iat: Time.now.to_i,
      iss: C['JWT_ISSUER'],
      scopes: %w[add_money remove_money view_money],
      user: {
        uid: opt[:uid],
        created_at: DateTime.now
      }
    }
  end
end
