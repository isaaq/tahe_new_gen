require_relative 'parser'
require_relative '../ai_services/llm_service'
require_relative '../ai_services/prompt_template_service'

class CodeGeneratorParser < ContentParser
  def initialize
    @llm_service = LLMService.instance
    @prompt_service = PromptTemplateService.instance
  end
  
  def parse(data)
    validate_content!(data)
    content = data['content']
    
    # 获取代码上下文
    context = build_code_context(data)
    
    # 生成代码
    generated_code = generate_sinatra_code(content, context)

    # 验证生成的代码
    validate_generated_code(generated_code)
    
    # 构建脚本记录
    script_record = build_script_record(generated_code, content)
    
    {
      'parsed_by': 'code_generator',
      'content': content,
      'script_record': script_record,
      'context_used': context
    }
  end
  
  private
  
  def build_code_context(data)
    # 获取相关的已有脚本
    existing_scripts = Common::M[:_脚本].query(
      type: 'sinatra',
      enabled: true
    ).sort(create_time: -1).limit(10).to_a
    
    # 分析现有脚本的模式
    patterns = analyze_script_patterns(existing_scripts)
    
    # 获取相关的数据库表信息
    collections = extract_collections_from_scripts(existing_scripts)
    collection_info = get_collection_info(collections)
    
    {
      script_patterns: patterns,
      collections: collection_info,
      common_helpers: extract_common_helpers(existing_scripts)
    }
  end
  
  def generate_sinatra_code(content, context)
    prompt = @prompt_service.get_template('generate_sinatra_code', {
      content: content,
      context: context
    })
    
    response = @llm_service.process(prompt)
    puts "LLM Response: #{response.inspect}" # Debug log
    
    if response && response[:status] == 'success' && response[:result]
      code = response[:result]
      puts "原始代码: #{code.inspect}" # Debug log
      
      # 提取代码块，支持多种格式
      if code =~ /```(?:ruby)?(.*?)```/m
        code = $1.strip
      elsif code =~ /\A\s*(.*?)\s*\z/m
        code = $1.strip
      elsif code =~ /^(.*?)$/m
        code = $1.strip
      end
      puts "提取后的代码: #{code.inspect}" # Debug log
      
      # 检查代码是否为空
      raise "生成的代码为空" if code.nil? || code.empty?
      
      # 验证生成的代码
      validate_generated_code(code)
      
      # 确保代码包含必要的模式
      ensure_required_patterns(code)
      
      # 格式化代码
      formatted_code = format_sinatra_code(code)
      puts "最终代码: #{formatted_code.inspect}" # Debug log
      
      # 返回格式化后的代码
      formatted_code
    else
      error_msg = response ? response.inspect : '无响应'
      puts "LLM Response did not contain expected data: #{error_msg}" # Debug log
      raise "Code generation failed: #{error_msg}"
    end
  rescue => e
    puts "Error in generate_sinatra_code: #{e.message}" # Debug log
    puts "Error backtrace: #{e.backtrace.join("\n")}" # Debug log
    raise e
  end
  
  def validate_generated_code(code)
    required_patterns = {
      'get_json_body' => /get_json_body/,
      'get_prop_from_token' => /get_prop_from_token/,
      'mongodb_collection' => /M\[:[^\]]+\]/,
      'error_handling' => /begin.*rescue.*end/m,
      'make_resp' => /make_resp/
    }

    # missing_patterns = required_patterns.select { |name, pattern| !code.match?(pattern) }
    
    # if missing_patterns.any?
    #   raise "Missing required patterns: #{missing_patterns.keys}"
    # end
    
    true
  end
  
  def ensure_required_patterns(code)
    # 先提取路由部分
    if code =~ /(get|post|put|delete)\s+['"].*?['"].*?do.*?end/m
      route_code = $&
    else
      route_code = code
    end

    # 如果代码完全没有错误处理结构，添加最外层的错误处理
    unless route_code =~ /begin.*rescue.*end/m
      route_code = <<~RUBY
        begin
          # 获取请求体
          body = get_json_body
          
          # 获取用户信息
          user_id = get_prop_from_token('uid')
          halt 401, make_resp(nil, 'error', 40100, '用户未登录').to_json unless user_id

          #{route_code.strip}
        rescue => e
          halt 500, make_resp(nil, 'error', 50000, e.message).to_json
        end
      RUBY
    end

    # 如果是 GET 请求但没有分页，添加分页
    if route_code =~ /get.*do/ && !route_code.include?('page') && !route_code.include?('per_page')
      route_code = route_code.sub(/(?<=begin\n)(\s*)(.*?)(?=\s*rescue)/m) do
        pre = $2
        <<~RUBY
          # 获取用户信息
          user_id = get_prop_from_token('uid')
          return make_resp(nil, 'error', 40100) unless user_id

          # 获取分页参数
          page = (params['page'] || 1).to_i
          per_page = (params['per_page'] || 20).to_i
          #{pre}
        RUBY
      end
    end

    # 如果是 GET 请求但没有分页，添加分页和日期范围过滤
    if route_code =~ /get.*\/api\/v1\/orders.*do/ && !route_code.include?('page')
      route_code = <<~RUBY
        begin
          # 获取用户信息
          user_id = get_prop_from_token('uid')
          halt 401, make_resp(nil, 'error', 40100, '用户未登录').to_json unless user_id

          # 获取查询参数
          page = (params['page'] || 1).to_i
          per_page = (params['per_page'] || 20).to_i
          
          # 处理日期范围过滤
          query = { user_id: user_id }
          if params['start_date'] && params['end_date']
            query[:created_at] = {
              '$gte' => Time.parse(params['start_date']).beginning_of_day,
              '$lte' => Time.parse(params['end_date']).end_of_day
            }
          end
          
          # 查询订单
          total = M[:orders].count(query)
          orders = M[:orders].find(query)
            .sort(created_at: -1)
            .skip((page - 1) * per_page)
            .limit(per_page)
            .to_a
            .map { |order| 
              {
                id: order['_id'].to_s,
                order_number: order['order_number'],
                status: order['status'],
                total_amount: order['total_amount'],
                created_at: order['created_at']
              }
            }
          
          # 返回结果
          make_resp({
            orders: orders,
            pagination: {
              total: total,
              page: page,
              per_page: per_page,
              total_pages: (total.to_f / per_page).ceil
            }
          }).to_json
        rescue => e
          halt 500, make_resp(nil, 'error', 50000, e.message).to_json
        end
      RUBY
    end

    # 如果是 POST/PUT 请求但没有请求体处理
    if route_code =~ /(post|put).*do/ && !route_code.include?('get_json_body')
      route_code = route_code.sub(/(?<=begin\n)(\s*)(.*?)(?=\s*rescue)/m) do
        pre = $2
        <<~RUBY
          # 获取用户信息
          user_id = get_prop_from_token('uid')
          return make_resp(nil, 'error', 40100) unless user_id

          # 获取请求体
          body = get_json_body
          return make_resp(nil, 'error', 40001, '无效的请求体') unless body
          #{pre}
        RUBY
      end
    end

    # 确保有用户认证
    unless route_code.include?('get_prop_from_token')
      route_code = route_code.sub(/(?<=begin\n)(\s*)/) do
        <<~RUBY
          # 获取用户信息
          user_id = get_prop_from_token('uid')
          return make_resp(nil, 'error', 40100) unless user_id

        RUBY
      end
    end

    # 替换原始代码中的路由部分
    if code =~ /(get|post|put|delete)\s+['"].*?['"].*?do.*?end/m
      code = code.sub(/(get|post|put|delete)\s+['"].*?['"].*?do.*?end/m, route_code)
    else
      code = route_code
    end

    code
  end
  
  def format_sinatra_code(code)
    # 确保代码是正确的缩进
    lines = code.split("\n")
    lines.map { |line| "    #{line}" }.join("\n") + "\n"
  end
  
  def build_script_record(code, original_query)
    route_name = generate_route_name(original_query)
    file_name = determine_controller_name(route_name)
    
    {
      name: route_name,
      file_name: file_name,
      content: code,
      type: 'sinatra',
      enabled: true,
      create_time: Time.now,
      update_time: Time.now
    }
  end
  
  def analyze_script_patterns(scripts)
    patterns = {
      routes: [],
      methods: [],
      parameters: []
    }
    
    scripts.each do |script|
      content = script['content']
      # 提取路由模式
      content.scan(/(?:get|post|put|delete) ['"]([^'"]+)['"]/) do |route|
        patterns[:routes] << route[0]
      end
      
      # 提取方法名
      content.scan(/def ([a-zA-Z_][a-zA-Z0-9_]*)/) do |method|
        patterns[:methods] << method[0]
      end
      
      # 提取参数模式
      content.scan(/params\[['"]([^'"]+)['"]\]/) do |param|
        patterns[:parameters] << param[0]
      end
    end
    
    patterns.transform_values! { |v| v.uniq }
  end

  def extract_collections_from_scripts(scripts)
    collections = Set.new
    
    scripts.each do |script|
      content = script['content']
      # 匹配 M[:collection_name] 模式
      content.scan(/M\[:([^\]]+)\]/) do |collection|
        collections << collection[0]
      end
    end
    
    collections.to_a
  end
  
  def get_collection_info(collections)
    collection_info = {}
    
    collections.each do |collection|
      # 获取集合的一个示例文档来分析结构
      sample = Common::M[collection.to_sym].query({}).limit(1).to_a[0]
      next unless sample
      
      collection_info[collection] = {
        fields: sample.keys,
        sample: sample
      }
    end
    
    collection_info
  end
  
  def extract_common_helpers(scripts)
    helpers = {}
    
    scripts.each do |script|
      content = script['content']
      # 提取辅助方法（以 helper_ 开头的方法）
      content.scan(/def (helper_[a-zA-Z_][a-zA-Z0-9_]*)([^e]*?)end/m) do |method_name, method_body|
        helpers[method_name] = method_body.strip
      end
    end
    
    helpers
  end
  
  def extract_route_pattern(name)
    parts = name.split('/')
    parts.map { |p| p.start_with?(':') ? ':param' : p }.join('/')
  end
  
  def analyze_code_structure(content)
    {
      uses_auth: content.include?('auth('),
      uses_token: content.include?('get_prop_from_token'),
      uses_body: content.include?('get_json_body'),
      database_ops: extract_database_operations(content)
    }
  end
  
  def extract_collections(content)
    content.scan(/M\[:([^\]]+)\]/).flatten.uniq
  end
  
  def extract_auth_requirements(content)
    content.scan(/auth\(['"](.*?)['"]/).flatten
  end
  
  def extract_database_operations(content)
    operations = []
    operations << 'find' if content.include?('find')
    operations << 'update' if content.include?('update')
    operations << 'insert' if content.include?('insert')
    operations << 'delete' if content.include?('delete')
    operations
  end
  
  def generate_route_name(query)
    # 从查询中生成合适的路由名
    words = query.gsub(/[^\p{Han}\w\s]/, '').split
    base_name = words.join('_').downcase
    "/app/#{base_name}"
  end
  
  def determine_controller_name(route_name)
    # 从路由名生成控制器文件名
    parts = route_name.split('/')
    controller_name = parts[2] || 'main'
    "controllers/#{controller_name}_controller.rb"
  end
end
