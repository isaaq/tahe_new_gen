require 'singleton'

class PromptTemplateService
  include Singleton

  def initialize
    @templates = {}
    load_templates
  end

  def get_template(template_name, params = {})
    template = @templates[template_name.to_sym]
    raise "Template not found: #{template_name}" unless template

    # 替换模板参数
    template = template.dup
    params.each do |key, value|
      template.gsub!("{{#{key}}}", value.to_s)
    end

    template
  end

  def update_template(name, content, version = nil)
    version ||= (get_template_version(name) + 1)
    
    # 更新模板并持久化
    template_data = {
      name: name,
      content: content,
      version: version,
      updated_at: Time.now,
      performance_metrics: {
        usage_count: 0,
        success_rate: 0,
        avg_confidence: 0
      }
    }
    
    Common::M[:prompt_templates].add(template_data)
    
    @templates[name.to_sym] = content
  end

  def track_template_performance(name, metrics)
    Common::M[:prompt_templates].update(
      { name: name },
      { 
        '$inc': { 
          'performance_metrics.usage_count': 1,
          'performance_metrics.success_rate': metrics[:success] ? 1 : 0,
          'performance_metrics.avg_confidence': metrics[:confidence]
        }
      }
    )
  end

  private

  def get_template_version(name)
    template = Common::M[:prompt_templates].query(name: name).to_a[0]
    template ? template[:version] : 0
  end

  def load_templates
    # 从数据库加载模板
    templates = Common::M[:prompt_templates].query.to_a
    templates.each do |t|
      @templates[t[:name].to_sym] = t[:content]
    end

    # 如果没有模板，初始化默认模板
    initialize_default_templates if templates.empty?
    
    # 确保所有默认模板都存在
    ensure_default_templates_exist
  end

  def ensure_default_templates_exist
    default_templates.each do |name, content|
      unless @templates.key?(name.to_sym)
        update_template(name.to_s, content)
      end
    end
  end

  def default_templates
    {
      parse_content: <<~PROMPT,
        请解析以下内容，并提供结构化的解释：
        
        {{content}}
        
        要求：
        1. 识别主要主题和关键信息
        2. 提取实体和关系
        3. 分析情感倾向
        4. 返回JSON格式结果
        
        历史解析效果：{{history_performance}}
        当前上下文：{{context}}
      PROMPT

      generate_code: <<~PROMPT,
        请根据以下自然语言描述，生成对应的MongoDB查询代码：

        需求描述：
        {{content}}

        数据库上下文：
        {{context}}
      PROMPT

      generate_sinatra_code: <<~PROMPT,
        请根据以下自然语言描述，生成对应的Sinatra路由代码：

        需求描述：
        {{content}}

        代码上下文：
        {{context}}

        要求：
        1. 使用标准的Sinatra路由格式（get/post/put/delete）
        2. 包含必要的参数验证和错误处理
        3. 使用 M[:collection_name] 进行MongoDB操作
        4. 使用 make_resp 或 ok 方法返回结果
        5. 必须使用 get_json_body 获取 POST/PUT 请求的请求体
        6. 必须使用 get_prop_from_token 获取用户信息
        7. 遵循已有代码的模式和风格
        8. 确保代码安全和性能

        示例代码格式：
        ```ruby
        get '/api/v1/example' do
          begin
            # 获取用户信息
            user_id = get_prop_from_token('uid')
            return make_resp(nil, 'error', 40100) unless user_id

            # 获取请求参数
            page = (params['page'] || 1).to_i
            per_page = (params['per_page'] || 20).to_i

            # 构建查询条件
            query = { user_id: user_id }
            
            # 执行查询
            data = M[:collection].query(query)
              .sort(created_at: -1)
              .skip((page - 1) * per_page)
              .limit(per_page)
              .to_a

            # 返回结果
            make_resp(data)
          rescue => e
            make_resp(nil, 'error', 50000, e.message)
          end
        end

        post '/api/v1/example' do
          begin
            # 获取用户信息
            user_id = get_prop_from_token('uid')
            return make_resp(nil, 'error', 40100) unless user_id

            # 获取请求体
            body = get_json_body
            return make_resp(nil, 'error', 40001, '无效的请求体') unless body

            # 添加记录
            data = {
              user_id: user_id,
              content: body['content'],
              created_at: Time.now
            }
            
            M[:collection].add(data)
            make_resp(data)
          rescue => e
            make_resp(nil, 'error', 50000, e.message)
          end
        end
        ```

        请确保生成的代码：
        1. 包含错误代码（40001=参数错误, 40100=未登录, 50000=系统错误）
        2. 包含所有必需的辅助方法调用（get_json_body, get_prop_from_token, make_resp）
        3. 使用 begin/rescue 进行错误处理
        4. 遵循示例代码的格式和风格
      PROMPT
    }
  end

  def initialize_default_templates
    default_templates.each do |name, content|
      update_template(name.to_s, content)
    end
  end
end
