# frozen_string_literal: true

require 'sinatra/base'
require_relative '../../lib/biz/query/mongo_query_engine'
require_relative '../../lib/biz/query/filter_builder'
require_relative '../../lib/biz/query/formatter_registry'
require_relative '../../lib/biz/query/secure_protocol'
require_relative '../../lib/biz/query/compact_protocol'
require_relative '../../lib/biz/query/session_manager'
require_relative '../../lib/biz/query/protocol_selector'
require 'base64'

module QueryRoutes
  def self.registered(app)

# ========== 会话管理：建立加密会话 ==========
app.post '/session/create' do
  content_type :json
  
  begin
    # 获取客户端信息
    client_info = {
      ip: request.ip,
      user_agent: request.user_agent
    }
    
    # 创建会话
    user_id = session[:user_id] rescue nil
    session_info = SessionManager.create_session(user_id, client_info)
    
    {
      code: 0,
      msg: 'success',
      session_id: session_info[:session_id],
      expires_at: session_info[:expires_at],
      ttl: session_info[:ttl]
    }.to_json
  rescue => e
    status 500
    { code: 500, msg: e.message }.to_json
  end
end

# 刷新会话
app.post '/session/refresh' do
  content_type :json
  
  session_id = request.env['HTTP_X_SESSION_ID']
  
  if SessionManager.refresh_session(session_id)
    { code: 0, msg: 'success' }.to_json
  else
    { code: 404, msg: '会话不存在或已过期' }.to_json
  end
end

# 销毁会话
app.post '/session/destroy' do
  content_type :json
  
  session_id = request.env['HTTP_X_SESSION_ID']
  SessionManager.destroy_session(session_id)
  
  { code: 0, msg: 'success' }.to_json
end

# ========== 加密查询端点（生产环境，不透明 + 安全） ==========
app.post '/query/secure' do
  content_type :json
  
  begin
    # 1. 解析加密payload
    encrypted_payload = JSON.parse(request.body.read)
    
    # 2. 验证会话
    session_id = request.env['HTTP_X_SESSION_ID']
    session_key = SessionManager.get_session_key(session_id)
    
    unless session_key
      raise SecurityError, "无效的会话ID或会话已过期"
    end
    
    # 3. 验证签名（防篡改）
    signature = request.env['HTTP_X_SIGNATURE']
    if signature
      unless SecureProtocol.verify_signature(encrypted_payload, signature, session_key)
        raise SecurityError, "签名验证失败"
      end
    end
    
    # 4. 解密协议
    protocol = SecureProtocol.decrypt(encrypted_payload, session_key)
    
    # 5. 如果是紧凑协议，解码
    if protocol.key?('c')
      protocol = CompactProtocol.decode(protocol)
    end
    
    # 6. 安全验证
    validate_protocol!(protocol)
    
    # 7. 执行查询
    result = MongoQueryEngine.execute(protocol, build_request_context)
    
    # 8. 应用格式化器
    result[:data] = FormatterRegistry.apply_formatters(
      result[:data],
      build_request_context
    )
    
    # 9. 加密响应
    response_data = {
      code: 0,
      msg: 'success',
      data: result[:data],
      count: result[:count]
    }
    
    encrypted_response = SecureProtocol.encrypt(response_data, session_key)
    
    # 10. 刷新会话
    SessionManager.refresh_session(session_id)
    
    {
      encrypted: true,
      **encrypted_response
    }.to_json
    
  rescue SecurityError => e
    status 403
    { code: 403, msg: e.message, encrypted: false }.to_json
  rescue => e
    status 500
    puts "❌ 安全查询失败: #{e.message}"
    { code: 500, msg: '查询失败', encrypted: false }.to_json
  end
end
    
# ========== 主端点：POST /api/query（自动检测协议类型：完整/紧凑） ==========
app.post '/query' do
  content_type :json
  
  begin
    # 1. 解析查询协议
    # 检查是否有JSON body
    request.body.rewind
    body_content = request.body.read
    
    if request.content_type&.include?('application/json') && !body_content.empty?
      # JSON body方式
      raw_protocol = JSON.parse(body_content)
    else
      # 查询参数方式（LayUI兼容）
      raw_protocol = params.to_h
    end
    
    # 2. 自动检测协议类型
    protocol = auto_decode_protocol(raw_protocol)
    
    # 2. 安全验证
    validate_protocol!(protocol)
    
    # 3. 执行查询
    result = MongoQueryEngine.execute(protocol, build_request_context)
    
    # 4. 应用格式化器
    result[:data] = FormatterRegistry.apply_formatters(
      result[:data],
      build_request_context
    )
    
    # 5. 返回结果
    {
      code: 0,
      msg: 'success',
      data: result[:data],
      count: result[:count]
    }.to_json
    
  rescue SecurityError => e
    status 403
    { code: 403, msg: e.message, data: [] }.to_json
    
  rescue => e
    status 500
    puts "❌ 查询失败: #{e.message}"
    puts e.backtrace.first(5).join("\n") if ENV['RACK_ENV'] != 'production'
    { code: 500, msg: e.message, data: [] }.to_json
  end
end

# ========== 兼容端点：POST /q/:collection（REST 风格，兼容老系统） ==========
app.post '/q/:collection' do
  content_type :json
  
  begin
    # 从 URL 参数构建协议
    protocol = build_protocol_from_rest_params(params)
    
    # 安全验证
    validate_protocol!(protocol)
    
    # 执行查询
    result = MongoQueryEngine.execute(protocol, build_request_context)
    
    # 应用格式化器
    result[:data] = FormatterRegistry.apply_formatters(
      result[:data],
      build_request_context
    )
    
    # 返回老系统兼容格式
    to_paged_resp(
      result[:data],
      protocol['page'],
      protocol['limit'],
      result[:count]
    )
    
  rescue SecurityError => e
    status 403
    { code: 403, msg: e.message, data: [] }.to_json
    
  rescue => e
    status 500
    puts "❌ 查询失败: #{e.message}"
    puts e.backtrace.first(5).join("\n") if ENV['RACK_ENV'] != 'production'
    { code: 500, msg: e.message, data: [] }.to_json
  end
end

# ========== 辅助方法 ==========

def build_protocol_from_rest_params(params)
  {
    'collection' => params[:collection],
    'filter' => FilterBuilder.build_from_params(params),
    'expand' => parse_fk_param(params[:fk]),
    'sort' => parse_sort_param(params[:sort]),
    'page' => params[:page]&.to_i || 1,
    'limit' => params[:limit]&.to_i || 10
  }
end

def parse_fk_param(fk_param)
  return [] if fk_param.nil? || fk_param.empty?
  
  # 兼容老系统：Base64 编码的 FK 配置
  fk_decoded = Base64.decode64(fk_param)
  fk_array = eval(fk_decoded)  # ["b_package,package_id,name,_id,package_name"]
  
  fk_array.map do |fk_str|
    parts = fk_str.split(',')
    {
      'collection' => parts[0],           # b_packages
      'foreign_key' => parts[1],          # package_id
      'display_field' => parts[2],        # name
      'target_key' => parts[3] || '_id',  # _id
      'result_field' => parts[4] || parts[1]  # package_name
    }
  end
rescue => e
  puts "⚠️  解析 FK 参数失败: #{e.message}"
  []
end

def parse_sort_param(sort_param)
  return {} if sort_param.nil? || sort_param.empty?
  
  # 支持多种格式：
  # - "field:asc" 或 "field:desc"
  # - "field:-1" 或 "field:1"
  # - "field" (默认升序)
  
  parts = sort_param.to_s.split(':')
  field = parts[0]
  direction = parts[1]
  
  dir_value = case direction
              when 'desc', '-1' then -1
              when 'asc', '1', nil then 1
              else 1
              end
  
  { field.to_sym => dir_value }
end

def build_request_context
  {
    request_path: request.path,
    request_uri: request.url,
    referer: request.referer,
    origin: "#{request.scheme}://#{request.host_with_port}"
  }
end

def validate_protocol!(protocol)
  collection = protocol['collection']
  
  # 1. 白名单检查
  allowed_collections = load_allowed_collections
  
  unless allowed_collections.include?(collection)
    raise SecurityError, "集合 #{collection} 不允许查询"
  end
  
  # 2. 查询深度限制
  expand = protocol['expand'] || []
  if expand.size > 5
    raise SecurityError, "关联查询层级过深（最多5层）"
  end
  
  # 3. 分页限制
  limit = protocol['limit'] || 20
  if limit > 1000
    raise SecurityError, "分页大小超过限制（最多1000条）"
  end
end

def load_allowed_collections
  # 从配置或数据库加载白名单
  if defined?(M)
    @allowed_collections ||= M[:sys_allowed_collections].find.map { |c| c['name'] }
  end
rescue => e
  puts "⚠️  加载白名单失败，使用默认配置: #{e.message}"
  nil
ensure
  # 默认白名单
  @allowed_collections || %w[
    b_orders b_packages b_channel_names
    org_employees org_departments org_positions
  ]
end

app.helpers do
  # 自动检测并解码协议
  def auto_decode_protocol(raw_protocol)
    if raw_protocol.key?('collection')
      # 标准协议（完整JSON）
      raw_protocol
    elsif raw_protocol.key?('c')
      # 紧凑协议
      CompactProtocol.decode(raw_protocol)
    else
      raise SecurityError, "未知的协议格式"
    end
  end
  
  def build_protocol_from_rest_params(params)
    {
      'collection' => params[:collection],
      'filter' => FilterBuilder.build_from_params(params),
      'expand' => parse_fk_param(params[:fk]),
      'sort' => parse_sort_param(params[:sort]),
      'page' => params[:page]&.to_i || 1,
      'limit' => params[:limit]&.to_i || 10
    }
  end

  def parse_fk_param(fk_param)
    return [] if fk_param.nil? || fk_param.empty?
    
    # 兼容老系统：Base64 编码的 FK 配置
    fk_decoded = Base64.decode64(fk_param)
    fk_array = eval(fk_decoded)  # ["b_package,package_id,name,_id,package_name"]
    
    fk_array.map do |fk_str|
      parts = fk_str.split(',')
      {
        'collection' => parts[0],           # b_packages
        'foreign_key' => parts[1],          # package_id
        'display_field' => parts[2],        # name
        'target_key' => parts[3] || '_id',  # _id
        'result_field' => parts[4] || parts[1]  # package_name
      }
    end
  rescue => e
    puts "⚠️  解析 FK 参数失败: #{e.message}"
    []
  end

  def parse_sort_param(sort_param)
    return {} if sort_param.nil? || sort_param.empty?
    
    # 支持多种格式：
    # - "field:asc" 或 "field:desc"
    # - "field:-1" 或 "field:1"
    # - "field" (默认升序)
    
    parts = sort_param.to_s.split(':')
    field = parts[0]
    direction = parts[1]
    
    dir_value = case direction
                when 'desc', '-1' then -1
                when 'asc', '1', nil then 1
                else 1
                end
    
    { field.to_sym => dir_value }
  end

  def build_request_context
    {
      request_path: request.path,
      request_uri: request.url,
      referer: request.referer,
      origin: "#{request.scheme}://#{request.host_with_port}"
    }
  end

  def validate_protocol!(protocol)
    collection = protocol['collection']
    
    # 1. 白名单检查
    allowed_collections = load_allowed_collections
    
    unless allowed_collections.include?(collection)
      raise SecurityError, "集合 #{collection} 不允许查询"
    end
    
    # 2. 查询深度限制
    expand = protocol['expand'] || []
    if expand.size > 5
      raise SecurityError, "关联查询层级过深（最多5层）"
    end
    
    # 3. 分页限制
    limit = protocol['limit'] || 20
    if limit > 1000
      raise SecurityError, "分页大小超过限制（最多1000条）"
    end
  end

  def load_allowed_collections
    # 默认白名单
    %w[
      b_orders b_packages b_channel_names b_departments b_positions b_orgs
      org_employees org_departments org_positions
    ]
  end

  def to_paged_resp(data, page, limit, total)
    {
      code: 0,
      msg: 'success',
      data: data,
      count: total,
      page: page,
      limit: limit
    }.to_json
  end
end

  end  # self.registered
end  # module QueryRoutes
