# frozen_string_literal: true

# 混合协议模式演示
# 演示完整/紧凑/加密三种协议的使用

require_relative '../_system'
require_relative '../lib/ui/_config'
require_relative '../lib/biz/query/compact_protocol'
require_relative '../lib/biz/query/secure_protocol'
require_relative '../lib/biz/query/protocol_selector'
require_relative '../lib/biz/query/session_manager'

def demo_protocol_modes
  puts "\n" + "="*80
  puts "混合协议模式演示"
  puts "="*80
  puts
  
  # 示例查询协议
  sample_protocol = {
    'collection' => 'b_orders',
    'filter' => { 'status' => 1 },
    'expand' => [
      {
        'relation' => 'package',
        'collection' => 'b_packages',
        'foreign_key' => 'package_id',
        'display_field' => 'name',
        'result_field' => 'package_name'
      }
    ],
    'sort' => { 'created_at' => -1 },
    'page' => 1,
    'limit' => 20
  }
  
  # ========== 演示1: 完整协议 ==========
  puts "演示1: 完整协议（Full Protocol）"
  puts "-" * 40
  
  full_json = sample_protocol.to_json
  puts "体积: #{full_json.bytesize} 字节"
  puts "内容预览:"
  puts full_json[0..200] + "..."
  puts
  
  # ========== 演示2: 紧凑协议 ==========
  puts "演示2: 紧凑协议（Compact Protocol）"
  puts "-" * 40
  
  compact_protocol = CompactProtocol.encode(sample_protocol)
  compact_json = compact_protocol.to_json
  
  puts "体积: #{compact_json.bytesize} 字节"
  puts "压缩比: #{(compact_json.bytesize.to_f / full_json.bytesize * 100).round(1)}%"
  puts "减少: #{full_json.bytesize - compact_json.bytesize} 字节"
  puts "内容:"
  puts compact_json
  puts
  
  # 验证解码
  decoded = CompactProtocol.decode(compact_protocol)
  if decoded['collection'] == sample_protocol['collection']
    puts "✅ 解码验证成功"
  else
    puts "❌ 解码验证失败"
  end
  puts
  
  # ========== 演示3: 加密协议 ==========
  puts "演示3: 加密协议（Secure Protocol）"
  puts "-" * 40
  
  # 生成会话密钥
  session_key = SecureProtocol.generate_session_key
  puts "会话密钥长度: #{session_key.length} 字符"
  
  # 加密紧凑协议
  encrypted = SecureProtocol.encrypt(compact_protocol, session_key)
  encrypted_json = encrypted.to_json
  
  puts "加密后体积: #{encrypted_json.bytesize} 字节"
  puts "压缩比: #{(encrypted_json.bytesize.to_f / full_json.bytesize * 100).round(1)}%"
  puts "内容预览（完全不可读）:"
  puts encrypted_json[0..150] + "..."
  puts
  
  # 验证解密
  begin
    decrypted = SecureProtocol.decrypt(encrypted, session_key)
    if decrypted['c'] == compact_protocol['c']
      puts "✅ 解密验证成功"
    else
      puts "❌ 解密验证失败"
    end
  rescue => e
    puts "❌ 解密失败: #{e.message}"
  end
  puts
  
  # ========== 演示4: HMAC 签名 ==========
  puts "演示4: HMAC 签名（防篡改）"
  puts "-" * 40
  
  signature = SecureProtocol.sign(encrypted, session_key)
  puts "签名: #{signature[0..40]}..."
  
  # 验证签名
  if SecureProtocol.verify_signature(encrypted, signature, session_key)
    puts "✅ 签名验证成功"
  else
    puts "❌ 签名验证失败"
  end
  
  # 篡改测试
  tampered = encrypted.dup
  tampered['data'] = "tampered_data"
  if SecureProtocol.verify_signature(tampered, signature, session_key)
    puts "❌ 危险：篡改数据未被检测"
  else
    puts "✅ 篡改检测成功"
  end
  puts
  
  # ========== 演示5: 环境自动选择 ==========
  puts "演示5: 环境自动选择协议"
  puts "-" * 40
  
  environments = ['development', 'test', 'staging', 'production']
  
  environments.each do |env|
    original_env = ENV['RACK_ENV']
    ENV['RACK_ENV'] = env
    
    mode = ProtocolSelector.select_mode
    
    puts "环境: #{env}"
    puts "  模式: #{mode[:mode]}"
    puts "  端点: #{mode[:endpoint]}"
    puts "  压缩: #{mode[:compress]}"
    puts
    
    ENV['RACK_ENV'] = original_env
  end
  
  # ========== 演示6: 会话管理 ==========
  puts "演示6: 会话管理"
  puts "-" * 40
  
  # 创建会话
  session_info = SessionManager.create_session('user_001', { ip: '127.0.0.1' })
  puts "✅ 会话已创建"
  puts "  Session ID: #{session_info[:session_id]}"
  puts "  过期时间: #{session_info[:expires_at]}"
  puts
  
  # 获取会话密钥
  retrieved_key = SessionManager.get_session_key(session_info[:session_id])
  if retrieved_key
    puts "✅ 会话密钥获取成功"
  else
    puts "❌ 会话密钥获取失败"
  end
  puts
  
  # 销毁会话
  SessionManager.destroy_session(session_info[:session_id])
  puts "✅ 会话已销毁"
  puts
  
  # ========== 体积对比总结 ==========
  puts "体积对比总结"
  puts "-" * 40
  
  puts "完整JSON:   #{full_json.bytesize} 字节 (100%)"
  puts "紧凑协议:   #{compact_json.bytesize} 字节 (#{(compact_json.bytesize.to_f / full_json.bytesize * 100).round(1)}%)"
  puts "加密协议:   #{encrypted_json.bytesize} 字节 (#{(encrypted_json.bytesize.to_f / full_json.bytesize * 100).round(1)}%)"
  puts
  puts "节省传输量:"
  puts "  紧凑协议: #{full_json.bytesize - compact_json.bytesize} 字节 (减少#{((1 - compact_json.bytesize.to_f / full_json.bytesize) * 100).round(1)}%)"
  puts "  加密协议: #{full_json.bytesize - encrypted_json.bytesize} 字节 (减少#{((1 - encrypted_json.bytesize.to_f / full_json.bytesize) * 100).round(1)}%)"
  puts
  
  puts "🎉 混合协议模式演示完成！"
  puts
  puts "推荐配置:"
  puts "  开发环境: 完整协议（易调试）"
  puts "  预发布:   紧凑协议（性能测试）"
  puts "  生产环境: 加密协议（安全优先）"
  puts
end

# 运行演示
if __FILE__ == $PROGRAM_NAME
  demo_protocol_modes
end




