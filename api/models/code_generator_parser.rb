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
      context: context.to_json
    })
    
    response = @llm_service.process(prompt)
    
    if response && response[:status] == 'success' && response[:result]
      code = response[:result]
      # 提取代码块
      if code =~ /```ruby(.*?)```/m
        code = $1.strip
      end
      
      # 只保留路由处理部分
      if code =~ /(get|post|put|delete)\s+['"].*?['"].*?do.*?end/m
        code = $&
      end
      
      # 确保代码包含所有必需的模式
      code = ensure_required_patterns(code)
      
      # 格式化代码
      format_sinatra_code(code)
    else
      error_msg = response ? response[:error] || "生成的代码无效" : "无法生成代码"
      raise "Code generation failed: #{error_msg}"
    end
  end
  
  def ensure_required_patterns(code)
    # 如果是 GET 请求但没有分页，添加分页
    if code =~ /get.*do/ && !code.include?('page') && !code.include?('per_page')
      code = code.sub(/(\s*)(begin\s*$.*?)(\s*(?:make_resp|ok)\(.*?\))/m) do
        pre, begin_part, post = $1, $2, $3
        <<~CODE.gsub(/^/, pre)
          #{begin_part}
            # 获取分页参数
            page = (params['page'] || 1).to_i
            per_page = (params['per_page'] || 20).to_i

            # 获取用户信息
            user_id = get_prop_from_token('uid')
            return make_resp(nil, 'error', 40100) unless user_id

            # 构建查询条件
            query = { user_id: user_id }
            
            # 执行查询
            data = M[:orders]
              .query(query)
              .sort(created_at: -1)
              .skip((page - 1) * per_page)
              .limit(per_page)
              .to_a
            
          #{post}
        CODE
      end
    end
    
    # 如果是 POST/PUT 请求但没有 get_json_body，添加它
    if (code =~ /(post|put).*do/) && !code.include?('get_json_body')
      code = code.sub(/(\s*)(begin\s*$.*?)(\s*(?:make_resp|ok)\(.*?\))/m) do
        pre, begin_part, post = $1, $2, $3
        <<~CODE.gsub(/^/, pre)
          #{begin_part}
            # 获取请求体
            body = get_json_body
            return make_resp(nil, 'error', 40001, '无效的请求体') unless body

            # 获取用户信息
            user_id = get_prop_from_token('uid')
            return make_resp(nil, 'error', 40100) unless user_id
            
          #{post}
        CODE
      end
    end
    
    # 如果没有用户认证，添加它
    if !code.include?('get_prop_from_token')
      code = code.sub(/(\s*)(begin\s*$.*?)(\s*(?:make_resp|ok)\(.*?\))/m) do
        pre, begin_part, post = $1, $2, $3
        <<~CODE.gsub(/^/, pre)
          #{begin_part}
            # 获取用户信息
            user_id = get_prop_from_token('uid')
            return make_resp(nil, 'error', 40100) unless user_id
            
          #{post}
        CODE
      end
    end
    
    # 如果没有错误处理，添加它
    if !code.include?('rescue')
      code = code.sub(/(\s*end\s*)$/) do
        indent = $1.match(/^\s*/)[0]
        <<~CODE
          #{indent}rescue => e
          #{indent}  make_resp(nil, 'error', 50000, e.message)
          #{indent}end
        CODE
      end
    end
    
    puts "Code after ensuring patterns:\n#{code}"  # 添加调试日志
    code
  end
  
  def format_sinatra_code(code)
    # 确保代码是正确的缩进
    lines = code.split("\n")
    lines.map { |line| "    #{line}" }.join("\n") + "\n"
  end
  
  def validate_generated_code(code)
    # 验证 Sinatra 特定的代码结构
    required_patterns = [
      /get_json_body/,          # 请求体处理
      /get_prop_from_token/,    # 令牌属性获取
      /make_resp|ok/,           # 响应处理
      /M\[:[^\]]+\]/           # MongoDB 集合访问
    ]
    
    missing_patterns = required_patterns.reject { |p| code =~ p }
    raise "Missing required patterns: #{missing_patterns}" unless missing_patterns.empty?
    
    # 基本语法检查
    eval("def __temp_validate\n#{code}\nend", TOPLEVEL_BINDING)
    true
  rescue SyntaxError => e
    raise "Generated code has syntax errors: #{e.message}"
  ensure
    TOPLEVEL_BINDING.eval('undef __temp_validate') rescue nil
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
