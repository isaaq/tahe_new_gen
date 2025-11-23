# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'yaml'

# 插件代码生成器
# 基于模板批量生成插件代码
class PluginGenerator
  TEMPLATES_DIR = File.join(File.dirname(__FILE__), 'templates')
  
  def initialize
    @templates = {}
    load_templates
  end
  
  # 生成策略插件
  def generate_strategy_plugin(config)
    template = get_template('strategy_plugin_template.rb.erb')
    
    # 计算基础require路径
    base_require_path = calculate_base_require_path(
      'strategy',
      config[:category],
      config[:class_name]
    )
    
    # 构建模板变量
    template_vars = {
      base_require_path: base_require_path,
      category_module: config[:category_module] || classify(config[:category]),
      class_name: config[:class_name],
      domain: config[:domain] || 'document',
      action: config[:action],
      context: config[:context] || 'default',
      required_params: config[:required_params] || [],
      pre_process_logic: config[:pre_process_logic] || '',
      perform_logic: config[:perform_logic] || generate_default_perform_logic(config),
      result_fields: config[:result_fields] || '',
      success_message: config[:success_message] || '操作成功',
      post_process_logic: config[:post_process_logic] || ''
    }
    
    render_template(template, template_vars)
  end
  
  # 生成字段类型插件
  def generate_field_type_plugin(config)
    template = get_template('field_type_plugin_template.rb.erb')
    
    base_require_path = calculate_base_require_path(
      'field_type',
      config[:category],
      config[:class_name]
    )
    
    template_vars = {
      base_require_path: base_require_path,
      category_module: config[:category_module] || classify(config[:category]),
      class_name: config[:class_name],
      field_type_name: config[:field_type_name] || underscore(config[:class_name]),
      validation_logic: config[:validation_logic] || generate_default_validation_logic(config),
      mongo_conversion_logic: config[:mongo_conversion_logic] || 'value',
      mongo_from_logic: config[:mongo_from_logic] || 'value',
      ui_conversion_logic: config[:ui_conversion_logic] || 'value'
    }
    
    render_template(template, template_vars)
  end
  
  # 批量生成插件
  def batch_generate(plugin_configs, output_dir)
    FileUtils.mkdir_p(output_dir)
    
    results = []
    plugin_configs.each do |config|
      begin
        code = case config[:type]
        when 'strategy'
          generate_strategy_plugin(config)
        when 'field_type'
          generate_field_type_plugin(config)
        when 'form_behavior'
          # 使用表单行为模板生成
          template = get_template('form_behavior_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            behavior_logic: config[:behavior_logic] || '# 在此实现表单行为逻辑'
          })
          code
        when 'ui_component'
          template = get_template('ui_component_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            render_logic: config[:render_logic] || 'return "<div>UI Component</div>"'
          })
          code
        when 'hook'
          template = get_template('hook_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            hook_logic: config[:hook_logic] || '# 在此实现钩子逻辑'
          })
          code
        when 'ai_prompt'
          template = get_template('ai_prompt_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            ai_logic: config[:ai_logic] || 'return { success: true, output: input }'
          })
          code
        when 'data_source'
          template = get_template('data_source_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            data_source_logic: config[:data_source_logic] || '# 在此实现数据源逻辑'
          })
          code
        else
          raise "未知的插件类型: #{config[:type]}"
        end
        
        # 确定输出路径
        output_path = determine_output_path(config, output_dir)
        FileUtils.mkdir_p(File.dirname(output_path))
        
        # 写入文件（确保UTF-8编码）
        File.write(output_path, code, encoding: 'UTF-8')
        
        results << {
          success: true,
          plugin_id: config[:plugin_id],
          output_path: output_path
        }
      rescue => e
        results << {
          success: false,
          plugin_id: config[:plugin_id],
          error: e.message
        }
      end
    end
    
    results
  end
  
  private
  
  def load_templates
    Dir.glob(File.join(TEMPLATES_DIR, '*.erb')).each do |template_file|
      name = File.basename(template_file)
      @templates[name] = File.read(template_file)
    end
  end
  
  def get_template(name)
    @templates[name] || raise("模板不存在: #{name}")
  end
  
  def render_template(template_content, vars)
    # 将变量设置为实例变量，以便ERB模板可以访问
    vars.each do |key, value|
      # 确保字符串值是UTF-8编码
      if value.is_a?(String)
        value = value.force_encoding('UTF-8') if value.encoding != Encoding::UTF_8
      elsif value.is_a?(Array)
        value = value.map { |v| v.is_a?(String) && v.encoding != Encoding::UTF_8 ? v.force_encoding('UTF-8') : v }
      end
      instance_variable_set("@#{key}", value)
    end
    
    # 确保模板内容是UTF-8编码
    template_content = template_content.force_encoding('UTF-8') if template_content.encoding != Encoding::UTF_8
    
    # 定义辅助方法供模板使用
    def indent_code(code, spaces)
      return '' if code.nil? || code.strip.empty?
      indent = ' ' * spaces
      # 计算代码的最小缩进（排除空行）
      lines = code.lines.reject { |l| l.strip.empty? }
      return '' if lines.empty?
      
      min_indent = lines.map { |l| l[/\A */].size }.min || 0
      
      # 重新缩进代码，保持相对缩进
      code.lines.map do |line|
        stripped = line.strip
        if stripped.empty?
          ''
        else
          # 移除原有缩进，添加新缩进
          unindented = line.sub(/\A\s{#{min_indent}}/, '')
          indent + unindented.rstrip
        end
      end.join("\n")
    end
    
    # 创建binding并渲染模板
    result = ERB.new(template_content, trim_mode: '-').result(binding)
    # 确保结果是UTF-8编码
    result.force_encoding('UTF-8')
  end
  
  def calculate_base_require_path(base_type, category, class_name)
    # 计算相对require路径
    # 例如: strategy/save -> '../../../strategy/base_strategy'
    depth = category.split('/').size + 1
    '../' * depth + "#{base_type}/base_#{base_type == 'strategy' ? 'strategy' : 'field_type'}"
  end
  
  def determine_output_path(config, base_dir)
    category_path = config[:category].gsub('_', '/')
    file_name = underscore(config[:class_name]) + '.rb'
    File.join(base_dir, category_path, file_name)
  end
  
  def generate_default_perform_logic(config)
    action = config[:action].to_s
    context = config[:context].to_s
    domain = config[:domain].to_s
    collection = config[:collection] || 'documents'
    
    if action == 'save'
      # 保存策略的默认逻辑
      case context
      when 'draft'
        <<~RUBY.strip
# 草稿保存逻辑
data = params[:data] || {}
collection = params[:collection] || 'drafts'

# 添加草稿标记
data[:_draft] = true
data[:_draft_time] = Time.now

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 保存草稿
result = collection_obj.insert_one(data)

{ success: true, document_id: result.inserted_id.to_s, message: "草稿已保存" }
        RUBY
      when 'queue'
        <<~RUBY.strip
# 队列保存逻辑
data = params[:data] || {}
        collection = params[:collection] || '#{collection}'
        
# 获取 MongoDB 客户端
db = Common::M.database

# 添加到保存队列
db['save_queue'].insert_one({
  data: data,
  collection: collection,
  status: 'pending',
  created_at: Time.now
})

{ success: true, message: "数据已加入保存队列" }
        RUBY
      when 'audit'
        <<~RUBY.strip
# 审计保存逻辑
data = params[:data] || {}
collection = params[:collection] || '#{collection}'
operator_id = params[:operator_id]

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 保存数据
result = collection_obj.insert_one(data)

# 记录审计日志
db['audit_logs'].insert_one({
  action: 'save',
          document_id: result.inserted_id.to_s,
  collection: collection,
  operator_id: operator_id,
  data_snapshot: data,
  created_at: Time.now
})

{ success: true, document_id: result.inserted_id.to_s, message: "文档已保存并记录审计日志" }
        RUBY
      when 'version'
        <<~RUBY.strip
# 版本保存逻辑
data = params[:data] || {}
collection = params[:collection] || '#{collection}'
version = params[:version] || '1.0'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 保存数据
result = collection_obj.insert_one(data)

# 保存版本记录
db['document_versions'].insert_one({
  document_id: result.inserted_id.to_s,
  version: version.to_s,
  data: data,
  created_at: Time.now
})

{ success: true, document_id: result.inserted_id.to_s, version: version, message: "文档已保存并创建版本" }
        RUBY
      else
        <<~RUBY.strip
# 保存逻辑
data = params[:data] || {}
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 保存数据
result = collection_obj.insert_one(data)

{ success: true, document_id: result.inserted_id.to_s, message: "文档已保存" }
        RUBY
      end
    elsif action == 'query'
      # 查询策略的默认逻辑
      case context
      when 'fulltext'
        <<~RUBY.strip
# 全文搜索逻辑
keyword = params[:keyword] || params[:query][:keyword]
collection = params[:collection] || '#{collection}'

return { success: false, message: "搜索关键词未指定" } unless keyword

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 构建全文搜索查询
search_query = {
  '$text' => { '$search' => keyword }
}

# 执行全文搜索
results = collection_obj.find(search_query).to_a

{ success: true, data: results, count: results.size, keyword: keyword }
        RUBY
      when 'faceted', 'facets'
        <<~RUBY.strip
# 分面搜索逻辑
        query = params[:query] || {}
facets = params[:facets] || []
        collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 执行基础查询
results = collection_obj.find(query).to_a

# 计算分面统计
facet_results = {}
facets.each do |facet_field|
  facet_values = results.map { |r| r[facet_field.to_sym] || r[facet_field.to_s] }.compact.uniq
  facet_results[facet_field] = facet_values.map do |value|
    { value: value, count: results.count { |r| (r[facet_field.to_sym] || r[facet_field.to_s]) == value } }
  end
end

{ success: true, data: results, count: results.size, facets: facet_results }
        RUBY
      when 'pagination'
        <<~RUBY.strip
# 分页查询逻辑
query = params[:query] || {}
page = params[:page] || 1
page_size = params[:page_size] || params[:limit] || 20
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 计算跳过的记录数
skip = (page.to_i - 1) * page_size.to_i

# 执行分页查询
total_count = collection_obj.count_documents(query)
results = collection_obj.find(query).skip(skip).limit(page_size.to_i).to_a

# 计算总页数
total_pages = (total_count.to_f / page_size.to_i).ceil

{ success: true, data: results, count: results.size, total: total_count, page: page.to_i, page_size: page_size.to_i, total_pages: total_pages }
        RUBY
      when 'nested'
        <<~RUBY.strip
# 嵌套查询逻辑
query = params[:query] || {}
nested_path = params[:nested_path] || params[:path]
nested_query = params[:nested_query] || {}
collection = params[:collection] || '#{collection}'

return { success: false, message: "嵌套路径未指定" } unless nested_path

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 构建嵌套查询
mongo_query = query.dup
mongo_query["#{nested_path}"] = nested_query

# 执行嵌套查询
results = collection_obj.find(mongo_query).to_a

{ success: true, data: results, count: results.size, nested_path: nested_path }
        RUBY
      when 'aggregate'
        <<~RUBY.strip
# 聚合查询逻辑
pipeline = params[:pipeline] || []
collection = params[:collection] || '#{collection}'

return { success: false, message: "聚合管道未指定" } if pipeline.empty?

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 执行聚合查询
results = collection_obj.aggregate(pipeline).to_a

{ success: true, data: results, count: results.size }
        RUBY
      when 'cached'
        <<~RUBY.strip
# 缓存查询逻辑
query = params[:query] || {}
cache_key = params[:cache_key] || Digest::MD5.hexdigest(query.to_json)
cache_ttl = params[:cache_ttl] || 3600
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database

# 尝试从缓存获取
cache_doc = db['query_cache'].find_one({ key: cache_key })
if cache_doc && cache_doc['expires_at'] > Time.now
  return { success: true, data: cache_doc['data'], count: cache_doc['data'].size, cached: true }
end

# 缓存未命中，执行查询
collection_obj = db[collection]
results = collection_obj.find(query).to_a

# 写入缓存
db['query_cache'].insert_one({
  key: cache_key,
  data: results,
  expires_at: Time.now + cache_ttl,
  created_at: Time.now
})

{ success: true, data: results, count: results.size, cached: false }
        RUBY
      else
        <<~RUBY.strip
# 查询逻辑
query = params[:query] || {}
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]
        
        # 执行查询
results = collection_obj.find(query).to_a

{ success: true, data: results, count: results.size }
        RUBY
      end
    elsif action == 'filter' && domain == 'permission'
      # 权限过滤策略的默认逻辑
      case context
      when 'time', 'time_window'
        <<~RUBY.strip
# 基于时间的权限过滤
current_time = Time.now
resource = params[:resource] || {}

# 检查时间窗口配置
time_window = params[:time_window] || resource[:time_window] || {}
start_time = time_window[:start_time]
end_time = time_window[:end_time]

# 如果配置了时间窗口，检查当前时间是否在允许范围内
if start_time && end_time
  allowed = current_time >= Time.parse(start_time) && current_time <= Time.parse(end_time)
  unless allowed
    return { success: false, message: "当前时间不在允许的访问时间窗口内" }
  end
end

# 设置允许访问标志
@allowed = true
        RUBY
      when 'ip'
        <<~RUBY.strip
# 基于IP的权限过滤
user_ip = params[:user_ip] || params[:request]&.remote_ip
allowed_ips = params[:allowed_ips] || []

return { success: false, message: "IP地址未提供" } unless user_ip
return { success: false, message: "IP地址不在白名单中" } unless allowed_ips.empty? || allowed_ips.include?(user_ip)

# 设置允许访问标志
@allowed = true
        RUBY
      when 'data'
        <<~RUBY.strip
# 基于数据的权限过滤
user = params[:user] || {}
resource = params[:resource] || {}
data_filters = params[:data_filters] || []

# 应用数据过滤规则
@filtered_data = resource
data_filters.each do |filter|
  # 根据过滤规则过滤数据
  # 这里需要根据具体的过滤规则实现
end

@allowed = true
        RUBY
      else
        <<~RUBY.strip
# 权限过滤逻辑
user = params[:user] || {}
resource = params[:resource] || {}

# 实现具体的权限检查逻辑
# 默认允许访问
@allowed = true
        RUBY
      end
    elsif action == 'validate'
      # 验证策略的默认逻辑
      case context
      when 'form'
        <<~RUBY.strip
# 表单验证逻辑
data = params[:data] || {}
validation_rules = params[:validation_rules] || {}

errors = []

# 遍历验证规则
validation_rules.each do |field_name, rules|
  value = data[field_name.to_sym] || data[field_name.to_s]
  
  # 必填验证
  if rules[:required] && (value.nil? || value.to_s.strip.empty?)
    errors << { field: field_name, message: "\#{field_name} 不能为空" }
    next
  end
  
  next if value.nil? || value.to_s.strip.empty?
  
  # 类型验证
  if rules[:type] && !value.is_a?(rules[:type])
    errors << { field: field_name, message: "\#{field_name} 类型不正确" }
  end
  
  # 长度验证
  if rules[:min_length] && value.to_s.length < rules[:min_length]
    errors << { field: field_name, message: "\#{field_name} 长度不能小于 \#{rules[:min_length]}" }
  end
  
  if rules[:max_length] && value.to_s.length > rules[:max_length]
    errors << { field: field_name, message: "\#{field_name} 长度不能超过 \#{rules[:max_length]}" }
  end
  
  # 正则验证
  if rules[:pattern] && !value.to_s.match?(rules[:pattern])
    errors << { field: field_name, message: "\#{field_name} 格式不正确" }
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'custom'
        <<~RUBY.strip
# 自定义验证逻辑
data = params[:data] || {}
validator = params[:validator]

return { success: false, message: "验证器未指定" } unless validator

# 调用自定义验证器
if validator.respond_to?(:call)
  result = validator.call(data)
  if result.is_a?(Hash)
    result
  elsif result == true
    { success: true, valid: true }
  else
    { success: false, valid: false, errors: [{ message: result.to_s }] }
  end
else
  { success: false, message: "验证器必须是可调用的对象" }
end
        RUBY
      when 'sequential'
        <<~RUBY.strip
# 顺序验证逻辑
data = params[:data] || {}
validators = params[:validators] || []

errors = []

validators.each do |validator|
  if validator.respond_to?(:call)
    result = validator.call(data)
    unless result == true || (result.is_a?(Hash) && result[:success])
      errors << { validator: validator.to_s, message: result.to_s }
      break  # 顺序验证，遇到错误就停止
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'parallel'
        <<~RUBY.strip
# 并行验证逻辑
data = params[:data] || {}
validators = params[:validators] || []

errors = []

validators.each do |validator|
  if validator.respond_to?(:call)
    result = validator.call(data)
    unless result == true || (result.is_a?(Hash) && result[:success])
      errors << { validator: validator.to_s, message: result.to_s }
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'business_logic'
        <<~RUBY.strip
# 业务逻辑验证
data = params[:data] || {}
business_rules = params[:business_rules] || []

errors = []

# 执行业务规则验证
business_rules.each do |rule|
  if rule.respond_to?(:call)
    result = rule.call(data)
    unless result == true || (result.is_a?(Hash) && result[:success])
      errors << { rule: rule.to_s, message: result.is_a?(Hash) ? result[:message] : result.to_s }
    end
  elsif rule.is_a?(Hash)
    # 基于规则的业务逻辑验证
    condition = rule[:condition]
    message = rule[:message] || '业务规则验证失败'
    if condition.respond_to?(:call) && !condition.call(data)
      errors << { rule: rule[:name] || 'business_rule', message: message }
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'business_rule'
        <<~RUBY.strip
# 业务规则验证
data = params[:data] || {}
rules = params[:rules] || []

errors = []

rules.each do |rule|
  field = rule[:field]
  condition = rule[:condition]
  message = rule[:message] || "\#{field} 不符合业务规则"
  
  field_value = data[field.to_sym] || data[field.to_s]
  
  if condition.respond_to?(:call)
    unless condition.call(field_value, data)
      errors << { field: field, message: message }
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'cache'
        <<~RUBY.strip
# 缓存验证逻辑
data = params[:data] || {}
validation_rules = params[:validation_rules] || {}
cache_key = params[:cache_key] || Digest::MD5.hexdigest(data.to_json)

# 获取 MongoDB 客户端
db = Common::M.database

# 尝试从缓存获取验证结果
cache_doc = db['validation_cache'].find_one({ key: cache_key })
if cache_doc && cache_doc['expires_at'] > Time.now
  return cache_doc['result']
end

# 执行实际验证
errors = []
validation_rules.each do |field, rules|
  field_value = data[field]
  if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
    errors << { field: field, message: "\#{field} 是必填字段" }
  end
end

result = errors.empty? ? { success: true, valid: true } : { success: false, valid: false, errors: errors }

# 写入缓存
db['validation_cache'].insert_one({
  key: cache_key,
  result: result,
  expires_at: Time.now + (params[:cache_ttl] || 3600),
  created_at: Time.now
})

result
        RUBY
      when 'cascade'
        <<~RUBY.strip
# 级联验证逻辑
data = params[:data] || {}
validation_rules = params[:validation_rules] || {}
related_collections = params[:related_collections] || []

errors = []

# 验证主数据
validation_rules.each do |field, rules|
  field_value = data[field]
  if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
    errors << { field: field, message: "\#{field} 是必填字段" }
  end
end

# 级联验证关联数据
if errors.empty? && !related_collections.empty?
  db = Common::M.database
  related_collections.each do |collection_name|
    foreign_key = params[:foreign_key] || 'document_id'
    related_data = db[collection_name].find({ foreign_key.to_sym => data[:_id] || data['_id'] }).to_a
    
    related_data.each do |related_item|
      related_rules = params[:related_validation_rules] || {}
      related_rules.each do |field, rules|
        field_value = related_item[field.to_sym] || related_item[field.to_s]
        if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
          errors << { 
            field: "\#{collection_name}.\#{field}", 
            message: "\#{collection_name} 的 \#{field} 是必填字段" 
          }
        end
      end
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'conditional'
        <<~RUBY.strip
# 条件验证逻辑
data = params[:data] || {}
condition = params[:condition]
validation_rules = params[:validation_rules] || {}

errors = []

# 检查条件是否满足
condition_met = true
if condition.respond_to?(:call)
  condition_met = condition.call(data)
elsif condition.is_a?(Hash)
  condition.each do |field, expected_value|
    actual_value = data[field.to_sym] || data[field.to_s]
    unless actual_value == expected_value
      condition_met = false
      break
    end
  end
end

# 只有在条件满足时才执行验证
if condition_met
  validation_rules.each do |field, rules|
    field_value = data[field]
    if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
      errors << { field: field, message: "\#{field} 是必填字段" }
    end
  end
end

if errors.empty?
  { success: true, valid: true, condition_met: condition_met }
else
  { success: false, valid: false, errors: errors, condition_met: condition_met }
end
        RUBY
      when 'cross_field'
        <<~RUBY.strip
# 跨字段验证逻辑
data = params[:data] || {}
cross_field_rules = params[:cross_field_rules] || []

errors = []

# 执行跨字段验证规则
cross_field_rules.each do |rule|
  fields = rule[:fields] || []
  validator = rule[:validator]
  message = rule[:message] || '跨字段验证失败'
  
  if validator.respond_to?(:call)
    field_values = fields.map { |f| data[f.to_sym] || data[f.to_s] }
    unless validator.call(*field_values, data)
      errors << { fields: fields, message: message }
    end
  elsif rule[:type] == 'equal'
    # 字段值必须相等
    values = fields.map { |f| data[f.to_sym] || data[f.to_s] }
    unless values.uniq.size == 1
      errors << { fields: fields, message: "\#{fields.join(', ')} 的值必须相等" }
    end
  elsif rule[:type] == 'sum'
    # 字段值之和必须等于指定值
    sum = fields.sum { |f| (data[f.to_sym] || data[f.to_s] || 0).to_f }
    expected_sum = rule[:expected_sum]
    if expected_sum && (sum - expected_sum).abs > 0.01
      errors << { fields: fields, message: "\#{fields.join(' + ')} 的和必须等于 \#{expected_sum}" }
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'custom_format'
        <<~RUBY.strip
# 自定义格式验证逻辑
data = params[:data] || {}
format_validators = params[:format_validators] || {}

errors = []

format_validators.each do |field, format_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil? || field_value.to_s.empty?
  
  format_type = format_config[:type]
  pattern = format_config[:pattern]
  validator = format_config[:validator]
  
  if validator.respond_to?(:call)
    unless validator.call(field_value)
      errors << { field: field, message: "\#{field} 格式不正确" }
    end
  elsif pattern
    unless field_value.to_s.match?(pattern)
      errors << { field: field, message: "\#{field} 格式不正确" }
    end
  elsif format_type
    case format_type
    when 'email'
      unless field_value.to_s.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        errors << { field: field, message: "\#{field} 必须是有效的邮箱地址" }
      end
    when 'phone'
      unless field_value.to_s.match?(/^1[3-9]\d{9}$/)
        errors << { field: field, message: "\#{field} 必须是有效的手机号码" }
      end
    when 'url'
      unless field_value.to_s.match?(/\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/)
        errors << { field: field, message: "\#{field} 必须是有效的URL" }
      end
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'data_integrity'
        <<~RUBY.strip
# 数据完整性验证逻辑
data = params[:data] || {}
integrity_rules = params[:integrity_rules] || {}

errors = []

# 验证数据完整性
integrity_rules.each do |rule_type, rule_config|
  case rule_type.to_s
  when 'required_fields'
    required_fields = rule_config[:fields] || []
    required_fields.each do |field|
      field_value = data[field.to_sym] || data[field.to_s]
      if field_value.nil? || field_value.to_s.empty?
        errors << { field: field, message: "\#{field} 是必填字段" }
      end
    end
  when 'foreign_key'
    # 外键完整性验证
    foreign_key = rule_config[:field]
    reference_collection = rule_config[:collection]
    if foreign_key && reference_collection
      db = Common::M.database
      foreign_key_value = data[foreign_key.to_sym] || data[foreign_key.to_s]
      if foreign_key_value
        referenced = db[reference_collection].find_one({ _id: BSON::ObjectId(foreign_key_value) })
        unless referenced
          errors << { field: foreign_key, message: "\#{foreign_key} 引用的记录不存在" }
        end
      end
    end
  when 'unique'
    # 唯一性验证
    unique_fields = rule_config[:fields] || []
    unique_fields.each do |field|
      field_value = data[field.to_sym] || data[field.to_s]
      if field_value
        db = Common::M.database
        collection = params[:collection] || 'documents'
        existing = db[collection].find_one({ field.to_sym => field_value })
        if existing && existing['_id'].to_s != (data[:_id] || data['_id']).to_s
          errors << { field: field, message: "\#{field} 的值必须唯一" }
        end
      end
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'dependency'
        <<~RUBY.strip
# 依赖验证逻辑
data = params[:data] || {}
dependency_rules = params[:dependency_rules] || []

errors = []

# 验证字段依赖关系
dependency_rules.each do |rule|
  dependent_field = rule[:dependent_field]
  depends_on_field = rule[:depends_on_field]
  condition = rule[:condition] || ->(dep_value) { !dep_value.nil? && !dep_value.to_s.empty? }
  
  depends_on_value = data[depends_on_field.to_sym] || data[depends_on_field.to_s]
  dependent_value = data[dependent_field.to_sym] || data[dependent_field.to_s]
  
  # 如果依赖字段满足条件，则被依赖字段必须存在
  if condition.respond_to?(:call) && condition.call(depends_on_value)
    if dependent_value.nil? || dependent_value.to_s.empty?
      errors << { 
        field: dependent_field, 
        message: "\#{dependent_field} 依赖于 \#{depends_on_field}，当 \#{depends_on_field} 存在时，\#{dependent_field} 必须填写" 
      }
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'external'
        <<~RUBY.strip
# 外部验证逻辑
data = params[:data] || {}
external_validators = params[:external_validators] || []

errors = []

# 调用外部验证服务
external_validators.each do |validator_config|
  service_url = validator_config[:service_url]
  field = validator_config[:field]
  field_value = data[field.to_sym] || data[field.to_s]
  
  if service_url && field_value
    begin
      # 调用外部验证API
      # 实际实现需要根据具体的外部服务进行集成
      # 示例：使用 HTTParty 调用外部验证服务
      # begin
      #   response = HTTParty.post(service_url, 
      #     body: { field: field, value: field_value }.to_json,
      #     headers: { 'Content-Type' => 'application/json' },
      #     timeout: 5
      #   )
      #   unless response.success? || (response.parsed_response && response.parsed_response['valid'])
      #     errors << { field: field, message: "外部验证失败: \#{response.body}" }
      #   end
      # rescue => e
      #   errors << { field: field, message: "外部验证服务错误: \#{e.message}" }
      # end
      
      # 记录外部验证请求（实际应该调用真实的外部服务）
      db = Common::M.database
      db['external_validation_logs'].insert_one({
        field: field,
        value: field_value,
        service_url: service_url,
        validated_at: Time.now,
        status: 'pending'
      })
    rescue => e
      errors << { field: field, message: "外部验证服务错误: \#{e.message}" }
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'format'
        <<~RUBY.strip
# 格式验证逻辑
data = params[:data] || {}
format_rules = params[:format_rules] || {}

errors = []

format_rules.each do |field, format_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil? || field_value.to_s.empty?
  
  pattern = format_config[:pattern]
  format_type = format_config[:type]
  
  if pattern
    unless field_value.to_s.match?(pattern)
      errors << { field: field, message: "\#{field} 格式不正确" }
    end
  elsif format_type
    case format_type
    when 'email'
      unless field_value.to_s.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        errors << { field: field, message: "\#{field} 必须是有效的邮箱地址" }
      end
    when 'phone'
      unless field_value.to_s.match?(/^1[3-9]\d{9}$/)
        errors << { field: field, message: "\#{field} 必须是有效的手机号码" }
      end
    when 'url'
      unless field_value.to_s.match?(/\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/)
        errors << { field: field, message: "\#{field} 必须是有效的URL" }
      end
    when 'date'
      begin
        Date.parse(field_value.to_s)
      rescue
        errors << { field: field, message: "\#{field} 必须是有效的日期格式" }
      end
    when 'datetime'
      begin
        DateTime.parse(field_value.to_s)
      rescue
        errors << { field: field, message: "\#{field} 必须是有效的日期时间格式" }
      end
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'length'
        <<~RUBY.strip
# 长度验证逻辑
data = params[:data] || {}
length_rules = params[:length_rules] || {}

errors = []

length_rules.each do |field, length_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil?
  
  min_length = length_config[:min]
  max_length = length_config[:max]
  exact_length = length_config[:exact]
  value_length = field_value.to_s.length
  
  if exact_length && value_length != exact_length
    errors << { field: field, message: "\#{field} 长度必须为 \#{exact_length}" }
  elsif min_length && value_length < min_length
    errors << { field: field, message: "\#{field} 长度不能小于 \#{min_length}" }
  elsif max_length && value_length > max_length
    errors << { field: field, message: "\#{field} 长度不能超过 \#{max_length}" }
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'range'
        <<~RUBY.strip
# 范围验证逻辑
data = params[:data] || {}
range_rules = params[:range_rules] || {}

errors = []

range_rules.each do |field, range_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil?
  
  min_value = range_config[:min]
  max_value = range_config[:max]
  numeric_value = field_value.to_f
  
  if min_value && numeric_value < min_value
    errors << { field: field, message: "\#{field} 不能小于 \#{min_value}" }
  elsif max_value && numeric_value > max_value
    errors << { field: field, message: "\#{field} 不能大于 \#{max_value}" }
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'referential'
        <<~RUBY.strip
# 引用完整性验证逻辑
data = params[:data] || {}
referential_rules = params[:referential_rules] || []

errors = []

referential_rules.each do |rule|
  field = rule[:field]
  reference_collection = rule[:collection]
  reference_field = rule[:reference_field] || '_id'
  
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil? || field_value.to_s.empty?
  
  # 验证引用是否存在
  db = Common::M.database
  referenced = db[reference_collection].find_one({ reference_field.to_sym => field_value })
  unless referenced
    errors << { field: field, message: "\#{field} 引用的记录在 \#{reference_collection} 中不存在" }
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'regex'
        <<~RUBY.strip
# 正则表达式验证逻辑
data = params[:data] || {}
regex_rules = params[:regex_rules] || {}

errors = []

regex_rules.each do |field, regex_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil? || field_value.to_s.empty?
  
  pattern = regex_config[:pattern]
  message = regex_config[:message] || "\#{field} 格式不正确"
  
  if pattern
    regex = pattern.is_a?(Regexp) ? pattern : Regexp.new(pattern)
    unless field_value.to_s.match?(regex)
      errors << { field: field, message: message }
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'relation'
        <<~RUBY.strip
# 关联验证逻辑
data = params[:data] || {}
relation_rules = params[:relation_rules] || []

errors = []

relation_rules.each do |rule|
  relation_type = rule[:type]
  fields = rule[:fields] || []
  
  case relation_type.to_s
  when 'one_to_one'
    # 一对一关系验证
    if fields.size == 2
      field1_value = data[fields[0].to_sym] || data[fields[0].to_s]
      field2_value = data[fields[1].to_sym] || data[fields[1].to_s]
      if field1_value && field2_value
        db = Common::M.database
        collection = params[:collection] || 'documents'
        existing = db[collection].find_one({ fields[0].to_sym => field1_value, fields[1].to_sym => field2_value })
        if existing && existing['_id'].to_s != (data[:_id] || data['_id']).to_s
          errors << { fields: fields, message: "一对一关系已存在" }
        end
      end
    end
  when 'one_to_many'
    # 一对多关系验证（通常不需要验证，但可以检查数量限制）
    field = rule[:field]
    max_count = rule[:max_count]
    if field && max_count
      db = Common::M.database
      related_collection = rule[:related_collection]
      if related_collection
        count = db[related_collection].count_documents({ field.to_sym => data[:_id] || data['_id'] })
        if count > max_count
          errors << { field: field, message: "\#{field} 关联数量不能超过 \#{max_count}" }
        end
      end
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'threshold'
        <<~RUBY.strip
# 阈值验证逻辑
data = params[:data] || {}
threshold_rules = params[:threshold_rules] || {}

errors = []

threshold_rules.each do |field, threshold_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil?
  
  min_threshold = threshold_config[:min]
  max_threshold = threshold_config[:max]
  numeric_value = field_value.to_f
  
  if min_threshold && numeric_value < min_threshold
    errors << { field: field, message: "\#{field} 不能低于阈值 \#{min_threshold}" }
  elsif max_threshold && numeric_value > max_threshold
    errors << { field: field, message: "\#{field} 不能超过阈值 \#{max_threshold}" }
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'type'
        <<~RUBY.strip
# 类型验证逻辑
data = params[:data] || {}
type_rules = params[:type_rules] || {}

errors = []

type_rules.each do |field, type_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil?
  
  expected_type = type_config[:type]
  allow_nil = type_config[:allow_nil] || false
  
  unless allow_nil && field_value.nil?
    case expected_type.to_s
    when 'string', 'String'
      unless field_value.is_a?(String)
        errors << { field: field, message: "\#{field} 必须是字符串类型" }
      end
    when 'integer', 'Integer', 'int'
      unless field_value.is_a?(Integer) || (field_value.is_a?(String) && field_value.match?(/^-?\d+$/))
        errors << { field: field, message: "\#{field} 必须是整数类型" }
      end
    when 'float', 'Float', 'number', 'Numeric'
      unless field_value.is_a?(Numeric) || (field_value.is_a?(String) && field_value.match?(/^-?\d+(\.\d+)?$/))
        errors << { field: field, message: "\#{field} 必须是数字类型" }
      end
    when 'boolean', 'Boolean', 'bool'
      unless [true, false].include?(field_value) || ['true', 'false'].include?(field_value.to_s.downcase)
        errors << { field: field, message: "\#{field} 必须是布尔类型" }
      end
    when 'array', 'Array'
      unless field_value.is_a?(Array)
        errors << { field: field, message: "\#{field} 必须是数组类型" }
      end
    when 'hash', 'Hash', 'object', 'Object'
      unless field_value.is_a?(Hash)
        errors << { field: field, message: "\#{field} 必须是对象类型" }
      end
    end
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'uniqueness'
        <<~RUBY.strip
# 唯一性验证逻辑
data = params[:data] || {}
uniqueness_rules = params[:uniqueness_rules] || {}

errors = []

uniqueness_rules.each do |field, uniqueness_config|
  field_value = data[field.to_sym] || data[field.to_s]
  next if field_value.nil? || field_value.to_s.empty?
  
  scope = uniqueness_config[:scope] || []
  collection = params[:collection] || 'documents'
  
  # 构建查询条件
  query = { field.to_sym => field_value }
  scope.each do |scope_field|
    scope_value = data[scope_field.to_sym] || data[scope_field.to_s]
    query[scope_field.to_sym] = scope_value if scope_value
  end
  
  # 检查是否已存在
  db = Common::M.database
  existing = db[collection].find_one(query)
  if existing && existing['_id'].to_s != (data[:_id] || data['_id']).to_s
    scope_msg = scope.empty? ? '' : " (在 \#{scope.join(', ')} 范围内)"
    errors << { field: field, message: "\#{field} 的值必须唯一\#{scope_msg}" }
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      when 'async', 'batch'
        <<~RUBY.strip
# 异步/批量验证逻辑
data_list = params[:data_list] || [params[:data]].compact
validation_rules = params[:validation_rules] || {}

all_errors = []
validated_count = 0

data_list.each_with_index do |data, index|
  errors = []
  
  validation_rules.each do |field, rules|
    field_value = data[field.to_sym] || data[field.to_s]
    if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
      errors << { field: field, message: "\#{field} 是必填字段", index: index }
    end
  end
  
  if errors.empty?
    validated_count += 1
  else
    all_errors.concat(errors)
  end
end

if all_errors.empty?
  { success: true, valid: true, validated_count: validated_count, total: data_list.size }
else
  { success: false, valid: false, errors: all_errors, validated_count: validated_count, total: data_list.size }
end
        RUBY
      else
        <<~RUBY.strip
# 验证逻辑
data = params[:data] || {}
validation_rules = params[:validation_rules] || {}

errors = []

# 实现具体的验证逻辑
validation_rules.each do |field, rules|
  field_value = data[field]
  if rules[:required] && (field_value.nil? || field_value.to_s.empty?)
    errors << { field: field, message: "\#{field} 是必填字段" }
  end
end

if errors.empty?
  { success: true, valid: true }
else
  { success: false, valid: false, errors: errors }
end
        RUBY
      end
    elsif action == 'notify'
      # 通知策略的默认逻辑
      case context
      when 'email'
        <<~RUBY.strip
# 邮件通知逻辑
recipient = params[:recipient]
subject = params[:subject] || params[:message]&.dig(:subject) || '通知'
content = params[:content] || params[:message]&.dig(:content) || ''

return { success: false, message: "收件人未指定" } unless recipient

# 发送邮件
# 使用系统邮件服务发送
begin
  # 这里可以集成实际的邮件服务，如 ActionMailer、SendGrid 等
  # 示例：Mail.deliver do |mail|
  #   mail.to recipient
  #   mail.subject subject
  #   mail.body content
  # end
  
  # 记录发送日志
  db = Common::M.database
  db['notification_logs'].insert_one({
    type: 'email',
    recipient: recipient,
    subject: subject,
    content: content,
    sent_at: Time.now,
    status: 'sent'
  })
  
  { success: true, message: "邮件已发送", recipient: recipient }
rescue => e
  { success: false, message: "邮件发送失败: #{e.message}" }
end
        RUBY
      when 'sms'
        <<~RUBY.strip
# 短信通知逻辑
recipient = params[:recipient]
content = params[:content] || params[:message]&.dig(:content) || ''

return { success: false, message: "收件人未指定" } unless recipient

# 发送短信
begin
  # 这里可以集成实际的短信服务，如阿里云、腾讯云等
  # 示例：SmsClient.send(recipient, content)
  
  # 记录发送日志
  db = Common::M.database
  db['notification_logs'].insert_one({
    type: 'sms',
    recipient: recipient,
    content: content,
    sent_at: Time.now,
    status: 'sent'
  })
  
  { success: true, message: "短信已发送", recipient: recipient }
rescue => e
  { success: false, message: "短信发送失败: #{e.message}" }
end
        RUBY
      when 'batch'
        <<~RUBY.strip
# 批量通知逻辑
recipients = params[:recipients] || []
message = params[:message] || {}
channel = params[:channel] || 'email'

return { success: false, message: "收件人列表为空" } if recipients.empty?

# 获取 MongoDB 客户端
db = Common::M.database

# 批量发送通知
sent_count = 0
failed_count = 0
recipients.each do |recipient|
  begin
    # 根据渠道发送通知
    case channel.to_s
    when 'email'
      # 发送邮件
      db['notification_logs'].insert_one({
        type: 'email',
        recipient: recipient,
        subject: message[:subject] || '通知',
        content: message[:content] || '',
        sent_at: Time.now,
        status: 'sent'
      })
    when 'sms'
      # 发送短信
      db['notification_logs'].insert_one({
        type: 'sms',
        recipient: recipient,
        content: message[:content] || '',
        sent_at: Time.now,
        status: 'sent'
      })
    else
      # 其他渠道
      db['notification_logs'].insert_one({
        type: channel,
        recipient: recipient,
        message: message,
        sent_at: Time.now,
        status: 'sent'
      })
    end
    sent_count += 1
  rescue => e
    failed_count += 1
    db['notification_logs'].insert_one({
      type: channel,
      recipient: recipient,
      message: message,
      status: 'failed',
      error: e.message,
      created_at: Time.now
    })
  end
end

{ success: true, message: "批量通知已发送", sent_count: sent_count, failed_count: failed_count, total: recipients.size }
        RUBY
      when 'scheduled'
        <<~RUBY.strip
# 定时通知逻辑
recipient = params[:recipient]
message = params[:message] || {}
scheduled_time = params[:scheduled_time]
channel = params[:channel] || 'email'

return { success: false, message: "收件人未指定" } unless recipient
return { success: false, message: "定时时间未指定" } unless scheduled_time

# 获取 MongoDB 客户端
db = Common::M.database

# 创建定时通知任务
db['scheduled_notifications'].insert_one({
  recipient: recipient,
  message: message,
  channel: channel,
  scheduled_time: Time.parse(scheduled_time.to_s),
  status: 'pending',
  created_at: Time.now
})

{ success: true, message: "定时通知任务已创建", scheduled_time: scheduled_time }
        RUBY
      when 'retry'
        <<~RUBY.strip
# 重试通知逻辑
recipient = params[:recipient]
message = params[:message] || {}
channel = params[:channel] || 'email'
max_retries = params[:max_retries] || 3

return { success: false, message: "收件人未指定" } unless recipient

# 获取 MongoDB 客户端
db = Common::M.database

# 记录重试通知
db['retry_notifications'].insert_one({
  recipient: recipient,
  message: message,
  channel: channel,
  max_retries: max_retries,
  retry_count: 0,
  status: 'pending',
  created_at: Time.now
})

{ success: true, message: "重试通知任务已创建", max_retries: max_retries }
        RUBY
      when 'priority'
        <<~RUBY.strip
# 优先级通知逻辑
recipient = params[:recipient]
message = params[:message] || {}
channel = params[:channel] || 'email'
priority = params[:priority] || 5

return { success: false, message: "收件人未指定" } unless recipient

# 获取 MongoDB 客户端
db = Common::M.database

# 发送优先级通知
db['notification_logs'].insert_one({
  type: channel,
  recipient: recipient,
  message: message,
  priority: priority,
  sent_at: Time.now,
  status: 'sent'
})

{ success: true, message: "优先级通知已发送", priority: priority }
        RUBY
      when 'template'
        <<~RUBY.strip
# 模板通知逻辑
recipient = params[:recipient]
template_id = params[:template_id]
template_vars = params[:template_vars] || {}
channel = params[:channel] || 'email'

return { success: false, message: "收件人未指定" } unless recipient
return { success: false, message: "模板ID未指定" } unless template_id

# 获取 MongoDB 客户端
db = Common::M.database

# 获取模板
template = db['notification_templates'].find_one({ _id: template_id })
return { success: false, message: "模板不存在" } unless template

# 渲染模板内容
subject = (template['subject'] || '').gsub(/\{\{(\w+)\}\}/) { |m| template_vars[$1.to_sym] || template_vars[$1] || m }
content = (template['content'] || '').gsub(/\{\{(\w+)\}\}/) { |m| template_vars[$1.to_sym] || template_vars[$1] || m }

# 发送通知
db['notification_logs'].insert_one({
  type: channel,
  recipient: recipient,
  subject: subject,
  content: content,
  template_id: template_id,
  sent_at: Time.now,
  status: 'sent'
})

{ success: true, message: "模板通知已发送", template_id: template_id }
        RUBY
      else
        <<~RUBY.strip
# 通知逻辑
recipient = params[:recipient]
message = params[:message] || {}
channel = params[:channel] || 'email'

return { success: false, message: "收件人未指定" } unless recipient

# 获取 MongoDB 客户端
db = Common::M.database

# 发送通知
db['notification_logs'].insert_one({
  type: channel,
  recipient: recipient,
  message: message,
  sent_at: Time.now,
  status: 'sent'
})

{ success: true, message: "通知已发送", channel: channel }
        RUBY
      end
    elsif action == 'delete'
      # 删除策略的默认逻辑
      case context
      when 'cascade'
        <<~RUBY.strip
# 级联删除逻辑
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'
related_collections = params[:related_collections] || []
foreign_key_field = params[:foreign_key_field] || 'document_id'

# 获取 MongoDB 客户端
db = Common::M.database
main_collection = db[collection]

# 删除主文档
delete_result = main_collection.delete_one({ _id: BSON::ObjectId(document_id) })

# 级联删除关联数据
deleted_count = delete_result.deleted_count
related_deleted = {}

related_collections.each do |related_collection_name|
  related_collection = db[related_collection_name]
  related_query = { foreign_key_field.to_sym => document_id }
  related_result = related_collection.delete_many(related_query)
  related_deleted[related_collection_name] = related_result.deleted_count
  deleted_count += related_result.deleted_count
end
        
        {
          success: true,
  deleted_count: deleted_count,
  main_deleted: delete_result.deleted_count,
  related_deleted: related_deleted,
  message: "文档及关联数据已删除"
}
        RUBY
      when 'logical', 'soft'
        <<~RUBY.strip
# 逻辑删除（软删除）
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'
deleted_field = params[:deleted_field] || 'deleted_at'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 更新文档，标记为已删除
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { deleted_field.to_sym => Time.now } }
)

{
  success: true,
  updated_count: update_result.modified_count,
  message: "文档已逻辑删除"
}
        RUBY
      when 'physical', 'hard', 'permanent'
        <<~RUBY.strip
# 物理删除（硬删除）
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 物理删除文档
delete_result = collection_obj.delete_one({ _id: BSON::ObjectId(document_id) })

{
  success: true,
  deleted_count: delete_result.deleted_count,
  message: "文档已物理删除"
}
        RUBY
      when 'conditional'
        <<~RUBY.strip
# 条件删除
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'
conditions = params[:conditions] || {}

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 构建查询条件
query = { _id: BSON::ObjectId(document_id) }.merge(conditions)

# 检查条件是否满足
document = collection_obj.find_one(query)
unless document
  return { success: false, message: "文档不存在或条件不满足" }
end

# 删除文档
delete_result = collection_obj.delete_one(query)

{
  success: true,
  deleted_count: delete_result.deleted_count,
  message: "文档已删除"
        }
      RUBY
    else
        <<~RUBY.strip
# 删除逻辑
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 删除文档
delete_result = collection_obj.delete_one({ _id: BSON::ObjectId(document_id) })

{
  success: true,
  deleted_count: delete_result.deleted_count,
  message: "文档已删除"
}
        RUBY
      end
    elsif action == 'submit' || action == 'publish'
      # 提交/发布策略的默认逻辑
      case context
      when 'manual'
        <<~RUBY.strip
# 手动提交逻辑
document_id = params[:document_id]
operator_id = params[:operator_id]
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 更新文档状态为已提交
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'submitted', submitted_at: Time.now, operator_id: operator_id } }
)

{ success: true, updated_count: update_result.modified_count, message: "文档已手动提交" }
        RUBY
      when 'auto'
        <<~RUBY.strip
# 自动提交逻辑
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 更新文档状态为已提交
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'submitted', submitted_at: Time.now, auto_submitted: true } }
)

{ success: true, updated_count: update_result.modified_count, message: "文档已自动提交" }
        RUBY
      when 'scheduled'
        <<~RUBY.strip
# 定时发布逻辑
document_id = params[:document_id]
publish_time = params[:publish_time]
collection = params[:collection] || '#{collection}'

return { success: false, message: "发布时间未指定" } unless publish_time

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 创建定时任务
scheduled_time = Time.parse(publish_time.to_s)
db['scheduled_tasks'].insert_one({
  type: 'publish',
  document_id: document_id,
  scheduled_time: scheduled_time,
  status: 'pending',
  created_at: Time.now
})

# 更新文档状态为待发布
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'scheduled', scheduled_publish_time: scheduled_time } }
)

{ success: true, updated_count: update_result.modified_count, scheduled_time: scheduled_time, message: "定时发布任务已创建" }
        RUBY
      when 'batch'
        <<~RUBY.strip
# 批量发布逻辑
document_ids = params[:document_ids] || []
collection = params[:collection] || '#{collection}'

return { success: false, message: "文档ID列表为空" } if document_ids.empty?

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 批量更新文档状态
object_ids = document_ids.map { |id| BSON::ObjectId(id) }
update_result = collection_obj.update_many(
  { _id: { '$in' => object_ids } },
  { '$set' => { status: 'submitted', submitted_at: Time.now, batch_submitted: true } }
)

{ success: true, updated_count: update_result.modified_count, total: document_ids.size, message: "批量发布成功" }
        RUBY
      when 'conditional'
        <<~RUBY.strip
# 条件发布逻辑
document_id = params[:document_id]
condition = params[:condition] || params[:conditions] || {}
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 获取文档
document = collection_obj.find_one({ _id: BSON::ObjectId(document_id) })
return { success: false, message: "文档不存在" } unless document

# 检查条件
condition_met = true
if condition.is_a?(Hash)
  condition.each do |field, expected_value|
    actual_value = document[field.to_sym] || document[field.to_s]
    unless actual_value == expected_value
      condition_met = false
      break
    end
  end
elsif condition.respond_to?(:call)
  condition_met = condition.call(document)
end

unless condition_met
  return { success: false, message: "发布条件不满足" }
end

# 更新文档状态
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'submitted', submitted_at: Time.now, conditional_published: true } }
)

{ success: true, updated_count: update_result.modified_count, message: "条件发布成功" }
        RUBY
      when 'gray'
        <<~RUBY.strip
# 灰度发布逻辑
document_id = params[:document_id]
gray_percentage = params[:gray_percentage] || 10
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 创建灰度发布任务
db['gray_publish_tasks'].insert_one({
  document_id: document_id,
  gray_percentage: gray_percentage,
  status: 'active',
  created_at: Time.now
})

# 更新文档状态为灰度发布
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'gray_published', gray_percentage: gray_percentage, published_at: Time.now } }
)

{ success: true, updated_count: update_result.modified_count, gray_percentage: gray_percentage, message: "灰度发布任务已创建" }
        RUBY
      when 'rollback'
        <<~RUBY.strip
# 回滚发布逻辑
document_id = params[:document_id]
target_version = params[:version] || params[:target_version]
collection = params[:collection] || '#{collection}'

return { success: false, message: "目标版本未指定" } unless target_version

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 查找目标版本
version_doc = db['document_versions'].find_one({
  document_id: document_id,
  version: target_version.to_s
})

return { success: false, message: "目标版本不存在" } unless version_doc

# 恢复文档内容
version_data = version_doc['data'] || {}
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => version_data.merge({
    status: 'published',
    rolled_back_to: target_version,
    rolled_back_at: Time.now
  }) }
)

{ success: true, updated_count: update_result.modified_count, version: target_version, message: "发布已回滚" }
        RUBY
      when 'version_compare'
        <<~RUBY.strip
# 版本比较发布逻辑
document_id = params[:document_id]
compare_version = params[:compare_version]
collection = params[:collection] || '#{collection}'

return { success: false, message: "比较版本未指定" } unless compare_version

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 获取当前文档
current_doc = collection_obj.find_one({ _id: BSON::ObjectId(document_id) })
return { success: false, message: "文档不存在" } unless current_doc

# 获取比较版本
compare_doc = db['document_versions'].find_one({
  document_id: document_id,
  version: compare_version.to_s
})

return { success: false, message: "比较版本不存在" } unless compare_doc

# 比较版本差异
differences = []
current_data = current_doc.reject { |k, v| ['_id', '_created_at', '_updated_at'].include?(k.to_s) }
compare_data = compare_doc['data'] || {}

(current_data.keys + compare_data.keys).uniq.each do |key|
  if current_data[key] != compare_data[key]
    differences << { field: key, current: current_data[key], compare: compare_data[key] }
  end
end

# 更新文档，记录版本比较结果
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { 
    status: 'submitted', 
    submitted_at: Time.now,
    version_compared: true,
    version_comparison: {
      compare_version: compare_version,
      differences: differences,
      compared_at: Time.now
    }
  } }
)

{ success: true, updated_count: update_result.modified_count, differences: differences, message: "版本比较完成" }
        RUBY
      when 'delayed'
        <<~RUBY.strip
# 延迟发布逻辑
document_id = params[:document_id]
delay_seconds = params[:delay_seconds] || 0
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 计算发布时间
publish_time = Time.now + delay_seconds

# 创建延迟任务
db['delayed_tasks'].insert_one({
  type: 'publish',
  document_id: document_id,
  delay_seconds: delay_seconds,
  scheduled_time: publish_time,
  status: 'pending',
  created_at: Time.now
})

# 更新文档状态
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'delayed', delayed_publish_time: publish_time } }
)

{ success: true, updated_count: update_result.modified_count, publish_time: publish_time, message: "延迟发布任务已创建" }
        RUBY
      when 'immediate'
        <<~RUBY.strip
# 立即发布逻辑
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 立即更新文档状态为已发布
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'published', published_at: Time.now, immediate_published: true } }
)

{ success: true, updated_count: update_result.modified_count, message: "文档已立即发布" }
        RUBY
      when 'review', 'conditional_review', 'batch_review'
        <<~RUBY.strip
# 审核发布逻辑
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 创建审核任务
db['review_tasks'].insert_one({
  document_id: document_id,
  status: 'pending',
  created_at: Time.now
})

# 更新文档状态为待审核
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'pending_review', submitted_at: Time.now } }
)

{ success: true, updated_count: update_result.modified_count, message: "文档已提交审核" }
        RUBY
      when 'priority'
        <<~RUBY.strip
# 优先级发布逻辑
document_id = params[:document_id]
priority = params[:priority] || 5
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 更新文档状态，设置优先级
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'submitted', submitted_at: Time.now, priority: priority, priority_published: true } }
)

{ success: true, updated_count: update_result.modified_count, priority: priority, message: "优先级发布成功" }
        RUBY
      else
        <<~RUBY.strip
# 提交逻辑
document_id = params[:document_id]
collection = params[:collection] || '#{collection}'

# 获取 MongoDB 客户端
db = Common::M.database
collection_obj = db[collection]

# 更新文档状态
update_result = collection_obj.update_one(
  { _id: BSON::ObjectId(document_id) },
  { '$set' => { status: 'submitted', submitted_at: Time.now } }
)

{ success: true, updated_count: update_result.modified_count, message: "文档已提交" }
        RUBY
      end
    elsif action == 'workflow' || (action == 'process' && domain == 'workflow')
      # 工作流策略的默认逻辑
      case context
      when 'approval'
        <<~RUBY.strip
# 审批工作流逻辑
workflow_id = params[:workflow_id] || params[:document_id]
action_type = params[:action] || 'approve'
comment = params[:comment] || ''

# 获取 MongoDB 客户端
db = Common::M.database

# 获取工作流实例
workflow = db['workflows'].find_one({ _id: BSON::ObjectId(workflow_id) })
return { success: false, message: "工作流不存在" } unless workflow

# 执行审批操作
db['workflow_actions'].insert_one({
  workflow_id: workflow_id,
  action: action_type,
  comment: comment,
  operator_id: params[:operator_id],
  created_at: Time.now
})

# 更新工作流状态
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { 
    status: action_type == 'approve' ? 'approved' : 'rejected',
    updated_at: Time.now
  } }
)

{ success: true, message: "审批操作已执行", action: action_type }
        RUBY
      when 'sequential_approval'
        <<~RUBY.strip
# 顺序审批工作流逻辑
workflow_id = params[:workflow_id] || params[:document_id]
sequence = params[:sequence] || []
current_step = params[:current_step] || 0
action_type = params[:action] || 'approve'

# 获取 MongoDB 客户端
db = Common::M.database

# 获取工作流
workflow = db['workflows'].find_one({ _id: BSON::ObjectId(workflow_id) })
return { success: false, message: "工作流不存在" } unless workflow

# 执行当前步骤审批
if action_type == 'approve' && current_step < sequence.size - 1
  # 进入下一步
  next_step = current_step + 1
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { current_step: next_step, updated_at: Time.now } }
  )
  { success: true, message: "已进入下一步审批", current_step: next_step }
elsif action_type == 'approve'
  # 所有步骤完成
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: 'approved', completed_at: Time.now } }
  )
  { success: true, message: "顺序审批已完成" }
else
  # 拒绝，终止流程
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: 'rejected', rejected_at: Time.now } }
  )
  { success: true, message: "审批已拒绝" }
end
        RUBY
      when 'parallel_approval'
        <<~RUBY.strip
# 并行审批工作流逻辑
workflow_id = params[:workflow_id] || params[:document_id]
approvers = params[:approvers] || []
action_type = params[:action] || 'approve'
approver_id = params[:approver_id]

# 获取 MongoDB 客户端
db = Common::M.database

# 获取工作流
workflow = db['workflows'].find_one({ _id: BSON::ObjectId(workflow_id) })
return { success: false, message: "工作流不存在" } unless workflow

# 记录审批结果
db['workflow_approvals'].insert_one({
  workflow_id: workflow_id,
  approver_id: approver_id,
  action: action_type,
  created_at: Time.now
})

# 检查是否所有审批人都已审批
approval_count = db['workflow_approvals'].count_documents({ workflow_id: workflow_id, action: 'approve' })
if approval_count >= approvers.size
  # 所有审批人已通过
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: 'approved', completed_at: Time.now } }
  )
  { success: true, message: "并行审批已完成", approval_count: approval_count, total: approvers.size }
else
  { success: true, message: "审批已记录", approval_count: approval_count, total: approvers.size }
end
        RUBY
      when 'task_assignment'
        <<~RUBY.strip
# 任务分配工作流逻辑
workflow_id = params[:workflow_id]
assignee = params[:assignee] || params[:assignee_id]
task_id = params[:task_id]

return { success: false, message: "任务ID未指定" } unless task_id
return { success: false, message: "分配人未指定" } unless assignee

# 获取 MongoDB 客户端
db = Common::M.database

# 分配任务
db['workflow_tasks'].update_one(
  { _id: BSON::ObjectId(task_id) },
  { '$set' => { assigned_to: assignee, assigned_at: Time.now, status: 'assigned' } }
)

# 记录任务分配历史
db['workflow_task_assignments'].insert_one({
  task_id: task_id,
  workflow_id: workflow_id,
  assignee: assignee,
  assigned_by: params[:operator_id],
  created_at: Time.now
})

{ success: true, message: "任务已分配", assignee: assignee }
        RUBY
      when 'sub_process'
        <<~RUBY.strip
# 子流程工作流逻辑
workflow_id = params[:workflow_id]
sub_process_config = params[:sub_process_config] || {}

# 获取 MongoDB 客户端
db = Common::M.database

# 创建子流程实例
sub_workflow = db['workflows'].insert_one({
  parent_workflow_id: workflow_id,
  type: 'sub_process',
  config: sub_process_config,
  status: 'active',
  created_at: Time.now
})

{ success: true, message: "子流程已启动", sub_workflow_id: sub_workflow.inserted_id.to_s }
        RUBY
      when 'compensate'
        <<~RUBY.strip
# 补偿工作流逻辑
workflow_id = params[:workflow_id]
compensation_action = params[:compensation_action] || {}

# 获取 MongoDB 客户端
db = Common::M.database

# 记录补偿操作
db['workflow_compensations'].insert_one({
  workflow_id: workflow_id,
  action: compensation_action,
  created_at: Time.now
})

# 更新工作流状态
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { compensated: true, compensated_at: Time.now } }
)

{ success: true, message: "补偿操作已执行" }
        RUBY
      when 'escalation'
        <<~RUBY.strip
# 升级工作流逻辑
workflow_id = params[:workflow_id]
escalation_level = params[:escalation_level] || 1

# 获取 MongoDB 客户端
db = Common::M.database

# 记录升级操作
db['workflow_escalations'].insert_one({
  workflow_id: workflow_id,
  escalation_level: escalation_level,
  created_at: Time.now
})

# 更新工作流状态
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { escalated: true, escalation_level: escalation_level, escalated_at: Time.now } }
)

{ success: true, message: "工作流已升级", level: escalation_level }
        RUBY
      when 'delegate'
        <<~RUBY.strip
# 委托工作流逻辑
workflow_id = params[:workflow_id]
delegate_to = params[:delegate_to]

return { success: false, message: "被委托人未指定" } unless delegate_to

# 获取 MongoDB 客户端
db = Common::M.database

# 记录委托操作
db['workflow_delegations'].insert_one({
  workflow_id: workflow_id,
  delegate_to: delegate_to,
  delegated_by: params[:operator_id],
  created_at: Time.now
})

# 更新工作流负责人
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { assigned_to: delegate_to, delegated_at: Time.now } }
)

{ success: true, message: "工作流已委托", delegate_to: delegate_to }
        RUBY
      when 'add_signer'
        <<~RUBY.strip
# 加签工作流逻辑
document_id = params[:document_id]
workflow_id = params[:workflow_id] || document_id
approver_id = params[:approver_id]

return { success: false, message: "审批人未指定" } unless approver_id

# 获取 MongoDB 客户端
db = Common::M.database

# 添加审批人
db['workflow_signers'].insert_one({
  workflow_id: workflow_id,
  document_id: document_id,
  approver_id: approver_id,
  status: 'pending',
  created_at: Time.now
})

# 更新工作流签批人列表
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$addToSet' => { signers: approver_id } }
)

{ success: true, message: "已添加审批人", approver_id: approver_id }
        RUBY
      when 'return'
        <<~RUBY.strip
# 退回工作流逻辑
workflow_id = params[:workflow_id]
return_to = params[:return_to]
comment = params[:comment] || ''

# 获取 MongoDB 客户端
db = Common::M.database

# 记录退回操作
db['workflow_returns'].insert_one({
  workflow_id: workflow_id,
  return_to: return_to,
  comment: comment,
  returned_by: params[:operator_id],
  created_at: Time.now
})

# 更新工作流状态
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { status: 'returned', returned_to: return_to, returned_at: Time.now } }
)

{ success: true, message: "工作流已退回", return_to: return_to }
        RUBY
      when 'withdraw'
        <<~RUBY.strip
# 撤回工作流逻辑
workflow_id = params[:workflow_id]

# 获取 MongoDB 客户端
db = Common::M.database

# 记录撤回操作
db['workflow_withdrawals'].insert_one({
  workflow_id: workflow_id,
  withdrawn_by: params[:operator_id],
  created_at: Time.now
})

# 更新工作流状态
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { status: 'withdrawn', withdrawn_at: Time.now } }
)

{ success: true, message: "工作流已撤回" }
        RUBY
      when 'transfer'
        <<~RUBY.strip
# 转交工作流逻辑
workflow_id = params[:workflow_id]
transfer_to = params[:transfer_to]

return { success: false, message: "转交人未指定" } unless transfer_to

# 获取 MongoDB 客户端
db = Common::M.database

# 记录转交操作
db['workflow_transfers'].insert_one({
  workflow_id: workflow_id,
  transfer_to: transfer_to,
  transferred_by: params[:operator_id],
  created_at: Time.now
})

# 更新工作流负责人
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { assigned_to: transfer_to, transferred_at: Time.now } }
)

{ success: true, message: "工作流已转交", transfer_to: transfer_to }
        RUBY
      when 'urge'
        <<~RUBY.strip
# 催办工作流逻辑
workflow_id = params[:workflow_id]
message = params[:urge_message] || '请尽快处理'

# 获取 MongoDB 客户端
db = Common::M.database

# 记录催办操作
db['workflow_urges'].insert_one({
  workflow_id: workflow_id,
  message: message,
  urged_by: params[:operator_id],
  created_at: Time.now
})

# 更新工作流催办次数
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$inc' => { urge_count: 1 }, '$set' => { last_urged_at: Time.now } }
)

{ success: true, message: "催办已发送" }
        RUBY
      when 'timeout'
        <<~RUBY.strip
# 超时工作流逻辑
workflow_id = params[:workflow_id]
timeout_action = params[:timeout_action] || 'escalate'

# 获取 MongoDB 客户端
db = Common::M.database

# 记录超时处理
db['workflow_timeouts'].insert_one({
  workflow_id: workflow_id,
  timeout_action: timeout_action,
  created_at: Time.now
})

# 根据超时动作处理
case timeout_action
when 'escalate'
  # 升级处理
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: 'escalated', escalated_at: Time.now } }
  )
when 'cancel'
  # 取消处理
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: 'cancelled', cancelled_at: Time.now } }
  )
else
  # 默认标记为超时
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: 'timeout', timed_out_at: Time.now } }
  )
end

{ success: true, message: "超时已处理", action: timeout_action }
        RUBY
      when 'auto_transition'
        <<~RUBY.strip
# 自动流转工作流逻辑
workflow_id = params[:workflow_id]
transition_condition = params[:transition_condition] || {}

# 获取 MongoDB 客户端
db = Common::M.database

# 检查流转条件
workflow = db['workflows'].find_one({ _id: BSON::ObjectId(workflow_id) })
return { success: false, message: "工作流不存在" } unless workflow

# 检查条件是否满足
condition_met = true
if transition_condition.is_a?(Hash) && !transition_condition.empty?
  transition_condition.each do |field, expected_value|
    actual_value = workflow[field.to_sym] || workflow[field.to_s]
    unless actual_value == expected_value
      condition_met = false
      break
    end
  end
end

if condition_met
  # 自动流转到下一状态
  next_status = workflow['next_status'] || 'completed'
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: next_status, auto_transitioned_at: Time.now } }
  )
  { success: true, message: "工作流已自动流转", new_status: next_status }
else
  { success: false, message: "流转条件不满足" }
end
        RUBY
      when 'auto_trigger'
        <<~RUBY.strip
# 自动触发工作流逻辑
trigger_condition = params[:trigger_condition] || {}
workflow_template = params[:workflow_template]

return { success: false, message: "工作流模板未指定" } unless workflow_template

# 获取 MongoDB 客户端
db = Common::M.database

# 创建新的工作流实例
new_workflow = db['workflows'].insert_one({
  template: workflow_template,
  trigger_condition: trigger_condition,
  status: 'active',
  created_at: Time.now
})

{ success: true, message: "工作流已自动触发", workflow_id: new_workflow.inserted_id.to_s }
        RUBY
      when 'conditional_transition'
        <<~RUBY.strip
# 条件流转工作流逻辑
workflow_id = params[:workflow_id]
condition = params[:condition] || {}
target_status = params[:target_status]

return { success: false, message: "目标状态未指定" } unless target_status

# 获取 MongoDB 客户端
db = Common::M.database

# 检查条件
workflow = db['workflows'].find_one({ _id: BSON::ObjectId(workflow_id) })
return { success: false, message: "工作流不存在" } unless workflow

condition_met = true
if condition.is_a?(Hash) && !condition.empty?
  condition.each do |field, expected_value|
    actual_value = workflow[field.to_sym] || workflow[field.to_s]
    unless actual_value == expected_value
      condition_met = false
      break
    end
  end
end

if condition_met
  db['workflows'].update_one(
    { _id: BSON::ObjectId(workflow_id) },
    { '$set' => { status: target_status, conditional_transitioned_at: Time.now } }
  )
  { success: true, message: "工作流已条件流转", target_status: target_status }
else
  { success: false, message: "流转条件不满足" }
end
        RUBY
      when 'status_transition'
        <<~RUBY.strip
# 状态流转工作流逻辑
workflow_id = params[:workflow_id]
from_status = params[:from_status]
to_status = params[:to_status]

return { success: false, message: "目标状态未指定" } unless to_status

# 获取 MongoDB 客户端
db = Common::M.database

# 更新工作流状态
update_result = db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { 
    status: to_status,
    from_status: from_status,
    status_transitioned_at: Time.now
  } }
)

# 记录状态流转历史
db['workflow_status_history'].insert_one({
  workflow_id: workflow_id,
  from_status: from_status,
  to_status: to_status,
  transitioned_at: Time.now
})

{ success: true, message: "状态已流转", from_status: from_status, to_status: to_status }
        RUBY
      when 'counter_sign', 'or_sign'
        <<~RUBY.strip
# 会签/或签工作流逻辑
workflow_id = params[:workflow_id]
signers = params[:signers] || []
is_counter_sign = '#{context}' == 'counter_sign'

return { success: false, message: "签批人列表为空" } if signers.empty?

# 获取 MongoDB 客户端
db = Common::M.database

# 为每个签批人创建签批任务
signers.each do |signer_id|
  db['workflow_sign_tasks'].insert_one({
    workflow_id: workflow_id,
    signer_id: signer_id,
    sign_type: is_counter_sign ? 'counter_sign' : 'or_sign',
    status: 'pending',
    created_at: Time.now
  })
end

# 更新工作流状态
db['workflows'].update_one(
  { _id: BSON::ObjectId(workflow_id) },
  { '$set' => { 
    sign_type: is_counter_sign ? 'counter_sign' : 'or_sign',
    signers: signers,
    sign_status: 'pending'
  } }
)

{ success: true, message: "\#{is_counter_sign ? '会签' : '或签'}已执行", signers: signers }
        RUBY
      else
        <<~RUBY.strip
# 工作流逻辑
workflow_id = params[:workflow_id]
action = params[:action] || ''

# 执行工作流操作
# 这里需要根据具体的工作流引擎实现

{ success: true, message: "工作流操作已执行" }
        RUBY
      end
    else
      <<~RUBY.strip
# 实现具体的策略逻辑
# params 包含策略执行所需的参数

# 在这里实现具体的业务逻辑
# 可以通过设置实例变量来传递结果，或者直接返回结果

# 示例：处理数据
# processed_data = process_data(params[:data])

{ success: true, message: "操作成功" }
      RUBY
    end
  end
  
  def generate_default_validation_logic(config)
    field_type = config[:field_type_name].to_s
    
    if field_type =~ /number|integer|float/
      <<~RUBY
        unless value.is_a?(Numeric)
          return [false, "\#{@name} 必须是数字"]
        end
        
        if @options[:min] && value < @options[:min]
          return [false, "\#{@name} 不能小于 \#{@options[:min]}"]
        end
        
        if @options[:max] && value > @options[:max]
          return [false, "\#{@name} 不能大于 \#{@options[:max]}"]
        end
      RUBY
    elsif field_type =~ /string|text/
      <<~RUBY
        unless value.is_a?(String)
          return [false, "\#{@name} 必须是字符串"]
        end
        
        if @options[:min_length] && value.length < @options[:min_length]
          return [false, "\#{@name} 长度不能小于 \#{@options[:min_length]}"]
        end
        
        if @options[:max_length] && value.length > @options[:max_length]
          return [false, "\#{@name} 长度不能超过 \#{@options[:max_length]}"]
        end
      RUBY
    else
      '# 自定义验证逻辑'
    end
  end
  
  def classify(str)
    str.split(/[_\s]+/).map(&:capitalize).join
  end
  
  def underscore(str)
    str.gsub(/::/, '/')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .tr('-', '_')
       .downcase
  end
end

