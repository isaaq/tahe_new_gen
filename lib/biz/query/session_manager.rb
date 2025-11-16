# frozen_string_literal: true

require 'singleton'
require 'securerandom'

# SessionManager - 会话管理器
# 管理客户端的加密会话密钥
class SessionManager
  include Singleton
  
  SESSION_COLLECTION = 'sys_query_sessions'
  SESSION_TTL = 3600  # 1小时过期
  
  def initialize
    @memory_sessions = {}
    ensure_indexes!
  end
  
  # 创建新会话
  def self.create_session(user_id = nil, client_info = {})
    instance.send(:create_new_session, user_id, client_info)
  end
  
  # 获取会话密钥
  def self.get_session_key(session_id)
    instance.send(:get_session, session_id)
  end
  
  # 刷新会话
  def self.refresh_session(session_id)
    instance.send(:refresh, session_id)
  end
  
  # 销毁会话
  def self.destroy_session(session_id)
    instance.send(:destroy, session_id)
  end
  
  # 清理所有过期会话
  def self.cleanup_expired!
    instance.send(:cleanup_expired_sessions)
  end
  
  private
  
  def create_new_session(user_id, client_info)
    session_id = SecureRandom.hex(16)
    session_key = SecureProtocol.generate_session_key rescue SecureRandom.hex(32)
    
    session_data = {
      session_id: session_id,
      session_key: session_key,
      user_id: user_id,
      client_ip: client_info[:ip],
      user_agent: client_info[:user_agent],
      created_at: Time.now,
      expires_at: Time.now + SESSION_TTL,
      last_accessed: Time.now
    }
    
    # 保存到内存
    @memory_sessions[session_id] = session_data
    
    # 保存到 MongoDB（持久化）
    save_to_mongo(session_data)
    
    {
      session_id: session_id,
      expires_at: session_data[:expires_at],
      ttl: SESSION_TTL
    }
  end
  
  def get_session(session_id)
    return nil unless session_id
    
    # 1. 内存查找
    session = @memory_sessions[session_id]
    if session
      # 检查是否过期
      if session[:expires_at] < Time.now
        destroy(session_id)
        return nil
      end
      
      # 更新最后访问时间
      session[:last_accessed] = Time.now
      
      return session[:session_key]
    end
    
    # 2. MongoDB 查找
    session = load_from_mongo(session_id)
    
    return nil unless session
    
    # 回填内存
    @memory_sessions[session_id] = session
    
    session[:session_key]
  end
  
  def load_from_mongo(session_id)
    return nil unless defined?(M)
    
    doc = M[SESSION_COLLECTION].query({ 
      session_id: session_id,
      expires_at: { '$gt': Time.now }
    }).first
    
    return nil unless doc
    
    {
      session_id: doc['session_id'],
      session_key: doc['session_key'],
      user_id: doc['user_id'],
      created_at: doc['created_at'],
      expires_at: doc['expires_at'],
      last_accessed: Time.now
    }
  rescue => e
    puts "⚠️  从MongoDB加载会话失败: #{e.message}"
    nil
  end
  
  def refresh(session_id)
    session = @memory_sessions[session_id]
    return false unless session
    
    new_expires = Time.now + SESSION_TTL
    session[:expires_at] = new_expires
    session[:last_accessed] = Time.now
    
    # 更新 MongoDB
    update_mongo(session_id, { 
      expires_at: new_expires,
      last_accessed: Time.now
    })
    
    true
  rescue
    false
  end
  
  def destroy(session_id)
    @memory_sessions.delete(session_id)
    
    return unless defined?(M)
    M[SESSION_COLLECTION].delete_one({ session_id: session_id })
  rescue
    # 忽略错误
  end
  
  def cleanup_expired_sessions
    # 清理内存中的过期会话
    now = Time.now
    @memory_sessions.delete_if { |_, session| session[:expires_at] < now }
    
    # MongoDB 的 TTL 索引会自动清理
    puts "✅ 清理了内存中的过期会话"
  rescue => e
    puts "⚠️  清理过期会话失败: #{e.message}"
  end
  
  def save_to_mongo(session_data)
    return unless defined?(M)
    
    M[SESSION_COLLECTION].insert_one({
      session_id: session_data[:session_id],
      session_key: session_data[:session_key],
      user_id: session_data[:user_id],
      client_ip: session_data[:client_ip],
      user_agent: session_data[:user_agent],
      created_at: session_data[:created_at],
      expires_at: session_data[:expires_at],
      last_accessed: session_data[:last_accessed]
    })
  rescue => e
    puts "⚠️  保存会话到MongoDB失败: #{e.message}"
  end
  
  def update_mongo(session_id, updates)
    return unless defined?(M)
    
    M[SESSION_COLLECTION].upsert(
      { session_id: session_id },
      updates
    )
  rescue
    # 忽略错误
  end
  
  def ensure_indexes!
    return unless defined?(M)
    
    begin
      # 唯一索引
      M[SESSION_COLLECTION].indexes.create_one(
        { session_id: 1 },
        { unique: true }
      )
      
      # TTL 索引（自动删除过期会话）
      M[SESSION_COLLECTION].indexes.create_one(
        { expires_at: 1 },
        { expireAfterSeconds: 0 }
      )
    rescue
      # 索引已存在
    end
  end
end
