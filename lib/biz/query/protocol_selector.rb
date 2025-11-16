# frozen_string_literal: true

# ProtocolSelector - 协议选择器
# 根据环境自动选择协议类型（透明/紧凑/加密）
class ProtocolSelector
  # 获取当前环境的协议模式
  def self.select_mode
    env = ENV['RACK_ENV'] || 'development'
    
    case env
    when 'production'
      # 生产环境：加密 + 紧凑
      { 
        mode: :encrypt,
        compress: true,
        endpoint: '/api/query/secure'
      }
    when 'staging'
      # 预发布环境：紧凑（不加密，便于调试）
      { 
        mode: :compact,
        compress: false,
        endpoint: '/api/query'
      }
    when 'test'
      # 测试环境：完整（便于验证）
      { 
        mode: :full,
        compress: false,
        endpoint: '/api/query'
      }
    else
      # 开发环境：完整（便于调试）
      { 
        mode: :full,
        compress: false,
        endpoint: '/api/query'
      }
    end
  end
  
  # 获取当前端点
  def self.endpoint
    select_mode[:endpoint]
  end
  
  # 判断是否使用加密
  def self.use_encryption?
    select_mode[:mode] == :encrypt
  end
  
  # 判断是否使用紧凑协议
  def self.use_compact?
    mode = select_mode[:mode]
    mode == :compact || mode == :encrypt
  end
  
  # 编码协议（根据模式）
  def self.encode(protocol)
    mode = select_mode
    
    # 1. 紧凑化（如果需要）
    if mode[:compress] || mode[:mode] == :compact || mode[:mode] == :encrypt
      protocol = CompactProtocol.encode(protocol)
    end
    
    protocol
  end
  
  # 获取前端配置
  def self.frontend_config
    mode = select_mode
    
    {
      endpoint: mode[:endpoint],
      use_encryption: mode[:mode] == :encrypt,
      use_compact: mode[:mode] == :compact || mode[:mode] == :encrypt,
      mode: mode[:mode].to_s
    }
  end
end




