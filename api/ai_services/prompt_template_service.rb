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
        请根据以下自然语言描述，生成对应的Sinatra路由代码。

        需求描述：
        {{content}}

        代码上下文：
        {{context}}

        必须严格遵循以下要求：
        1. 使用标准的Sinatra路由格式（get/post/put/delete）
        2. 必须包含以下关键代码模式：
           - 使用 get_prop_from_token('uid') 获取用户ID
           - 使用 M[:collection_name] 进行MongoDB操作
           - 使用 get_json_body 获取POST/PUT请求的请求体
           - 使用 make_resp 返回结果
           - 使用 begin/rescue 进行错误处理
        3. 必须包含以下错误代码：
           - 40001: 参数错误
           - 40100: 未登录
           - 50000: 系统错误

        示例代码格式（请严格参考）：
        ```ruby
        get '/api/v1/example' do
          begin
            # 获取用户信息（必须）
            user_id = get_prop_from_token('uid')
            return make_resp(nil, 'error', 40100) unless user_id

            # 获取分页参数（GET请求必须）
            page = (params['page'] || 1).to_i
            per_page = (params['per_page'] || 20).to_i

            # 构建查询条件
            query = { user_id: user_id }
            
            # 执行MongoDB查询（必须使用M[:collection]）
            data = M[:collection].query(query)
              .sort(created_at: -1)
              .skip((page - 1) * per_page)
              .limit(per_page)
              .to_a

            # 返回结果（必须使用make_resp）
            make_resp(data)
          rescue => e
            # 错误处理（必须）
            make_resp(nil, 'error', 50000, e.message)
          end
        end
        ```

        请确保生成的代码：
        1. 严格遵循示例代码的格式和结构
        2. 包含所有必需的辅助方法调用
        3. 使用正确的错误代码
        4. 包含适当的注释说明
      PROMPT

      generate_kr_tags: <<~PROMPT,
        你是一个低代码平台的页面生成器。
        根据用户的自然语言需求，直接生成kr标签（框架的声明式标签）。
        
        用户需求：
        {{content}}
        
        数据库上下文：
        {{context}}
        
        可用的kr标签：
        - <kr:datatable> - 数据表格，属性：source(数据源), page(分页), checkbox(多选)
        - <kr:col> - 表格列，属性：title(标题), field(字段名), width(宽度), relation(关联名), relation_field(关联显示字段), enum(枚举值)
        - <kr:form> - 表单，属性：model(模型), action(提交地址), method(方法)
        - <kr:input> - 输入框，属性：name(字段名), label(标签), required(必填), type(类型)
        - <kr:select> - 下拉选择，属性：name(字段名), label(标签), relation(关联名), options(选项)
        - <kr:tree_table_layout> - 树表联动布局，属性：tree_source(树数据源), table_source(表格数据源), link_param(联动参数)
        - <kr:search_table> - 搜索表格，属性：table_source(数据源), page(分页)
        - <kr:row-actions> - 行操作，包含 <kr:action> 子标签
        - <kr:action> - 操作按钮，属性：name(操作名), label(标签), confirm(确认消息)
        
        kr标签使用说明：
        1. 关联字段使用 relation 属性（语义化），如 relation="category" 会自动发现对应的集合
        2. 枚举字段使用 enum 属性，值为逗号分隔的选项，如 enum="待支付,已支付,已完成"
        3. 字段列表使用 fields 属性，值为逗号分隔的字段名，如 fields="name,price,category"
        4. 布尔属性使用 "true" 或 "false" 字符串
        
        请直接生成完整的ERB文件内容，包含kr标签。
        只返回ERB代码，不要其他说明文字。
        
        示例输出格式：
        ```erb
        <kr:datatable source="products" page="true">
          <kr:col title="产品名" field="name" width="200" />
          <kr:col title="价格" field="price" width="120" />
          <kr:col title="分类" field="category_id" relation="category" relation_field="name" width="150" />
          <kr:col title="状态" field="status" enum="在售,下架,缺货" width="100" />
          <kr:row-actions>
            <kr:action name="view" label="查看" />
            <kr:action name="edit" label="编辑" />
            <kr:action name="delete" label="删除" confirm="确认删除？" />
          </kr:row-actions>
        </kr:datatable>
        ```
      PROMPT

      generate_kr_tags_from_schema: <<~PROMPT,
        根据以下schema配置，生成对应的kr标签。
        
        Schema配置：
        {{schema}}
        
        数据库上下文：
        {{context}}
        
        可用的kr标签：
        - <kr:datatable> - 数据表格
        - <kr:col> - 表格列
        - <kr:form> - 表单
        - <kr:tree_table_layout> - 树表联动布局
        - <kr:search_table> - 搜索表格
        - <kr:row-actions> - 行操作
        
        请根据schema中的配置生成对应的kr标签。
        只返回ERB代码，不要其他说明文字。
      PROMPT

      generate_crud_schema: <<~PROMPT,
        你是一个低代码平台的后台管理页面配置生成器。
        根据用户的自然语言需求，生成标准的CRUD页面配置schema。
        
        用户需求：
        {{content}}
        
        数据库上下文：
        {{context}}
        
        请生成以下格式的YAML schema：
        
        ```yaml
        type: datamanage
        data: {{primary_collection}}  # 主数据表
        fields:
          - {{field1}}
          - {{field2}}
          # ... 从需求中提取的字段列表
        actions: [add, edit, delete, view]  # 从需求中提取的操作
        layout: auto  # auto/tree_table/search_table
        relations:  # 自动发现的关联表
          - name: {{relation_name}}
            collection: {{collection_name}}
            type: belongs_to  # belongs_to/has_many
            field: {{foreign_key_field}}
        ```
        
        要求：
        1. 识别主数据表和关联表
        2. 从数据库上下文推断字段列表
        3. 识别需要的操作（增删改查）
        4. 推断合适的布局类型
        5. 识别关联关系
        
        只返回YAML格式的schema，不要其他说明文字。
      PROMPT

      recommend_plugins: <<~PROMPT,
        你是一个插件推荐专家。根据用户需求，从以下插件列表中选择最合适的插件。
        
        用户需求：
        {{requirement}}
        
        可用插件列表：
        {{plugins}}
        
        请分析需求并推荐：
        1. 必须安装的插件（must_have）- 核心功能必需的插件
        2. 可选插件（optional）- 增强功能的插件
        3. 推荐理由（explanation）- 简要说明为什么推荐这些插件
        
        请以JSON格式返回，不要其他说明文字：
        {
          "must_have": ["plugin_id1", "plugin_id2"],
          "optional": ["plugin_id3", "plugin_id4"],
          "explanation": "推荐理由..."
        }
      PROMPT

      configure_plugin: <<~PROMPT,
        你是一个插件配置专家。根据用户输入，为插件生成合适的配置。
        
        插件名称：{{plugin_name}}
        插件描述：{{plugin_description}}
        
        用户输入：
        {{user_input}}
        
        配置项说明：
        {{config_schema}}
        
        请根据用户输入生成配置，以JSON格式返回，不要其他说明文字：
        {
          "config": {
            "field1": "value1",
            "field2": "value2"
          },
          "explanation": "配置说明..."
        }
      PROMPT

      suggest_plugin_combination: <<~PROMPT,
        你是一个插件组合专家。根据用户需求，推荐一组可以协同工作的插件。
        
        用户需求：
        {{requirements}}
        
        可用插件列表：
        {{plugins}}
        
        请推荐插件组合，包括：
        1. 插件列表（plugins）- 推荐的插件ID数组
        2. 安装顺序（order）- 建议的安装顺序
        3. 配置指南（config）- 每个插件的配置建议
        
        请以JSON格式返回，不要其他说明文字：
        {
          "plugins": ["plugin_id1", "plugin_id2"],
          "order": ["plugin_id1", "plugin_id2"],
          "config": {
            "plugin_id1": {"field1": "value1"},
            "plugin_id2": {"field2": "value2"}
          }
        }
      PROMPT
    }
  end

  def initialize_default_templates
    default_templates.each do |name, content|
      update_template(name.to_s, content)
    end
  end
end
