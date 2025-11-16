# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'base64'
require 'json'

# SecureProtocol - 安全协议编解码器
# 使用 AES-256-GCM 加密查询协议，防止抓包分析
class SecureProtocol
  ALGORITHM = 'aes-256-gcm'
  
  # 加密协议
  def self.encrypt(protocol, session_key)
    cipher = OpenSSL::Cipher.new(ALGORITHM)
    cipher.encrypt
    cipher.key = derive_key(session_key)
    
    # 生成随机 IV
    iv = cipher.random_iv
    
    # 加密数据
    json_data = protocol.to_json
    encrypted = cipher.update(json_data) + cipher.final
    
    # 获取认证标签（GCM模式）
    auth_tag = cipher.auth_tag
    
    # 组合：IV + 密文 + 认证标签
    {
      'iv' => Base64.strict_encode64(iv),
      'data' => Base64.strict_encode64(encrypted),
      'tag' => Base64.strict_encode64(auth_tag),
      'v' => 1  # 版本号
    }
  end
  
  # 解密协议
  def self.decrypt(encrypted_payload, session_key)
    decipher = OpenSSL::Cipher.new(ALGORITHM)
    decipher.decrypt
    decipher.key = derive_key(session_key)
    
    # 解析payload
    iv = Base64.strict_decode64(encrypted_payload['iv'])
    encrypted = Base64.strict_decode64(encrypted_payload['data'])
    auth_tag = Base64.strict_decode64(encrypted_payload['tag'])
    
    decipher.iv = iv
    decipher.auth_tag = auth_tag
    
    # 解密
    decrypted = decipher.update(encrypted) + decipher.final
    
    # 解析JSON
    JSON.parse(decrypted)
  rescue => e
    raise SecurityError, "协议解密失败: #{e.message}"
  end
  
  # 生成会话密钥
  def self.generate_session_key
    SecureRandom.hex(32)  # 256位密钥
  end
  
  # 从会话密钥派生加密密钥（PBKDF2）
  def self.derive_key(session_key)
    # 使用 SHA256 派生固定长度密钥
    OpenSSL::Digest::SHA256.digest(session_key)[0..31]
  end
  
  # 生成 HMAC 签名（防篡改）
  def self.sign(data, session_key)
    data_str = data.is_a?(String) ? data : data.to_json
    OpenSSL::HMAC.hexdigest('SHA256', session_key, data_str)
  end
  
  # 验证签名（常量时间比较，防时序攻击）
  def self.verify_signature(data, signature, session_key)
    expected = sign(data, session_key)
    
    # 使用 OpenSSL 的安全比较
    OpenSSL.fixed_length_secure_compare(signature, expected)
  rescue
    false
  end
end




