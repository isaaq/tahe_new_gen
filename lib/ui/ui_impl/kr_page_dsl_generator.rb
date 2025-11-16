# frozen_string_literal: true

# KR 页面级 DSL 生成器
# 支持通过简单的 DSL 描述生成完整的页面
class KrPageDslGenerator
  include Common
  
  def initialize
    @page_config = {}
    @components = []
    @scripts = []
    @styles = []
  end
  
  # 从 DSL 字符串生成页面
  def self.generate_from_dsl(dsl_content)
    generator = new
    generator.parse_dsl(dsl_content)
    generator.generate_page
  end
  
  # 从配置对象生成页面
  def self.generate_from_config(config)
    generator = new
    generator.load_config(config)
    generator.generate_page
  end
  
  def parse_dsl(dsl_content)
    # 简化的 DSL 解析器
    lines = dsl_content.split("\n")
    current_section = nil
    current_component = nil
    
    lines.each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      case line
      when /^page\s+"([^"]+)"/
        @page_config[:title] = $1
      when /^layout\s+(\w+)/
        @page_config[:layout] = $1
      when /^theme\s+(\w+)/
        @page_config[:theme] = $1
      when /^component\s+(\w+)/
        current_component = { type: $1, config: {} }
        @components << current_component
      when /^\s+(\w+):\s*(.+)/
        if current_component
          current_component[:config][$1.to_sym] = parse_value($2)
        end
      end
    end
  end
  
  def load_config(config)
    @page_config = config[:page] || {}
    @components = config[:components] || []
  end
  
  def generate_page
    html_content = generate_html_structure
    script_content = generate_script_section
    
    {
      html: html_content,
      script: script_content,
      full_page: wrap_in_html_document(html_content, script_content)
    }
  end
  
  private
  
  def parse_value(value_str)
    value_str = value_str.strip
    
    # 解析不同类型的值
    case value_str
    when /^"([^"]+)"$/
      $1  # 字符串
    when /^\[(.+)\]$/
      $1.split(',').map(&:strip)  # 数组
    when /^\{(.+)\}$/
      parse_object($1)  # 对象
    when /^\d+$/
      value_str.to_i  # 整数
    when /^true|false$/
      value_str == 'true'  # 布尔值
    else
      value_str  # 默认字符串
    end
  end
  
  def parse_object(obj_str)
    obj = {}
    obj_str.split(',').each do |pair|
      key, value = pair.split(':').map(&:strip)
      obj[key.to_sym] = parse_value(value)
    end
    obj
  end
  
  def generate_html_structure
    layout_class = @page_config[:layout] || 'default'
    theme_class = @page_config[:theme] || 'default'
    
    components_html = @components.map { |comp| generate_component_html(comp) }.join("\n")
    
    <<~HTML
      <div class="kr-page-container #{layout_class}-layout #{theme_class}-theme">
        #{generate_page_header}
        <div class="kr-page-content">
          #{components_html}
        </div>
        #{generate_page_footer}
      </div>
    HTML
  end
  
  def generate_page_header
    return '' unless @page_config[:show_header]
    
    <<~HTML
      <div class="kr-page-header">
        <h1 class="kr-page-title">#{@page_config[:title]}</h1>
        #{generate_breadcrumb if @page_config[:breadcrumb]}
      </div>
    HTML
  end
  
  def generate_page_footer
    return '' unless @page_config[:show_footer]
    
    <<~HTML
      <div class="kr-page-footer">
        <p>&copy; #{Date.current.year} KR Framework</p>
      </div>
    HTML
  end
  
  def generate_breadcrumb
    return '' unless @page_config[:breadcrumb].is_a?(Array)
    
    items = @page_config[:breadcrumb].map do |item|
      if item.is_a?(Hash)
        "<a href=\"#{item[:url]}\">#{item[:text]}</a>"
      else
        "<span>#{item}</span>"
      end
    end.join(' / ')
    
    <<~HTML
      <div class="layui-breadcrumb">
        #{items}
      </div>
    HTML
  end
  
  def generate_component_html(component)
    case component[:type]
    when 'tree_table_layout'
      generate_tree_table_layout(component[:config])
    when 'search_table'
      generate_search_table(component[:config])
    when 'master_detail_form'
      generate_master_detail_form(component[:config])
    when 'crud_panel'
      generate_crud_panel(component[:config])
    when 'dashboard'
      generate_dashboard(component[:config])
    when 'form'
      generate_form(component[:config])
    when 'table'
      generate_table(component[:config])
    else
      generate_generic_component(component)
    end
  end
  
  def generate_tree_table_layout(config)
    tree_id = "tree_#{SecureRandom.hex(4)}"
    table_id = "table_#{SecureRandom.hex(4)}"
    
    @scripts << generate_tree_table_script(tree_id, table_id, config)
    
    <<~HTML
      <div class="layui-row layui-col-space15">
        <div class="layui-col-md4">
          <div class="layui-card">
            <div class="layui-card-header">#{config[:tree_title] || '分类'}</div>
            <div class="layui-card-body">
              <ul id="#{tree_id}" class="layui-tree"></ul>
            </div>
          </div>
        </div>
        <div class="layui-col-md8">
          <div class="layui-card">
            <div class="layui-card-header">#{config[:table_title] || '数据列表'}</div>
            <div class="layui-card-body">
              <table id="#{table_id}" lay-filter="#{table_id}"></table>
            </div>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_search_table(config)
    form_id = "search_form_#{SecureRandom.hex(4)}"
    table_id = "search_table_#{SecureRandom.hex(4)}"
    
    search_fields = generate_search_fields(config[:search_fields] || [])
    
    @scripts << generate_search_table_script(form_id, table_id, config)
    
    <<~HTML
      <div class="layui-card">
        <div class="layui-card-header">搜索条件</div>
        <div class="layui-card-body">
          <form class="layui-form" id="#{form_id}" lay-filter="#{form_id}">
            #{search_fields}
            <div class="layui-form-item">
              <div class="layui-input-block">
                <button class="layui-btn" lay-submit lay-filter="search">搜索</button>
                <button type="reset" class="layui-btn layui-btn-primary">重置</button>
              </div>
            </div>
          </form>
        </div>
      </div>
      
      <div class="layui-card" style="margin-top: 15px;">
        <div class="layui-card-header">#{config[:table_title] || '数据列表'}</div>
        <div class="layui-card-body">
          <table id="#{table_id}" lay-filter="#{table_id}"></table>
        </div>
      </div>
    HTML
  end
  
  def generate_search_fields(fields)
    fields.map do |field|
      case field[:type]
      when 'input'
        <<~HTML
          <div class="layui-inline">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-inline">
              <input type="text" name="#{field[:name]}" placeholder="#{field[:placeholder]}" class="layui-input">
            </div>
          </div>
        HTML
      when 'select'
        options = field[:options]&.map { |opt| "<option value=\"#{opt[:value]}\">#{opt[:text]}</option>" }&.join || ''
        <<~HTML
          <div class="layui-inline">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-inline">
              <select name="#{field[:name]}">
                <option value="">请选择</option>
                #{options}
              </select>
            </div>
          </div>
        HTML
      when 'date_range'
        <<~HTML
          <div class="layui-inline">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-inline">
              <input type="text" name="#{field[:name]}" id="#{field[:name]}" placeholder="#{field[:placeholder]}" class="layui-input">
            </div>
          </div>
        HTML
      end
    end.join("\n")
  end
  
  def generate_crud_panel(config)
    table_id = "crud_table_#{SecureRandom.hex(4)}"
    form_id = "crud_form_#{SecureRandom.hex(4)}"
    
    @scripts << generate_crud_script(table_id, form_id, config)
    
    <<~HTML
      <div class="layui-card">
        <div class="layui-card-header">
          #{config[:title] || 'CRUD 管理'}
          <div class="layui-btn-group" style="float: right;">
            <button class="layui-btn layui-btn-sm" id="add-btn">
              <i class="layui-icon layui-icon-add-1"></i> 新增
            </button>
            <button class="layui-btn layui-btn-sm layui-btn-danger" id="batch-delete-btn">
              <i class="layui-icon layui-icon-delete"></i> 批量删除
            </button>
          </div>
        </div>
        <div class="layui-card-body">
          <table id="#{table_id}" lay-filter="#{table_id}"></table>
        </div>
      </div>
      
      <!-- 表单弹窗 -->
      <div id="#{form_id}" style="display: none; padding: 20px;">
        <!-- 动态表单内容 -->
      </div>
    HTML
  end
  
  def generate_form(config)
    form_id = "form_#{SecureRandom.hex(4)}"
    fields_html = generate_form_fields(config[:fields] || [])
    
    @scripts << generate_form_script(form_id, config)
    
    <<~HTML
      <div class="layui-card">
        <div class="layui-card-header">#{config[:title] || '表单'}</div>
        <div class="layui-card-body">
          <form class="layui-form" id="#{form_id}" lay-filter="#{form_id}">
            #{fields_html}
            <div class="layui-form-item">
              <div class="layui-input-block">
                <button class="layui-btn" lay-submit lay-filter="submit">提交</button>
                <button type="reset" class="layui-btn layui-btn-primary">重置</button>
              </div>
            </div>
          </form>
        </div>
      </div>
    HTML
  end
  
  def generate_form_fields(fields)
    fields.map do |field|
      case field[:type]
      when 'input'
        <<~HTML
          <div class="layui-form-item">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-block">
              <input type="#{field[:input_type] || 'text'}" name="#{field[:name]}" 
                     placeholder="#{field[:placeholder]}" class="layui-input" 
                     #{field[:required] ? 'lay-verify="required"' : ''}>
            </div>
          </div>
        HTML
      when 'textarea'
        <<~HTML
          <div class="layui-form-item layui-form-text">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-block">
              <textarea name="#{field[:name]}" placeholder="#{field[:placeholder]}" 
                        class="layui-textarea" #{field[:required] ? 'lay-verify="required"' : ''}></textarea>
            </div>
          </div>
        HTML
      when 'select'
        options = field[:options]&.map { |opt| "<option value=\"#{opt[:value]}\">#{opt[:text]}</option>" }&.join || ''
        <<~HTML
          <div class="layui-form-item">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-block">
              <select name="#{field[:name]}" #{field[:required] ? 'lay-verify="required"' : ''}>
                <option value="">请选择</option>
                #{options}
              </select>
            </div>
          </div>
        HTML
      when 'number_range'
        <<~HTML
          <div class="layui-form-item">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-block number-range-container" id="#{field[:name]}_container">
              <!-- 数值范围控件将由 KR Runtime 自动初始化 -->
            </div>
          </div>
        HTML
      end
    end.join("\n")
  end
  
  def generate_script_section
    layui_modules = extract_layui_modules
    
    <<~JAVASCRIPT
      layui.use(#{layui_modules.to_json}, function(){
        #{generate_layui_vars(layui_modules)}
        
        #{@scripts.join("\n\n")}
        
        // KR Runtime 初始化
        if (typeof KR !== 'undefined') {
          KR.init();
        }
      });
    JAVASCRIPT
  end
  
  def extract_layui_modules
    modules = ['jquery', 'layer']
    
    @components.each do |comp|
      case comp[:type]
      when 'tree_table_layout'
        modules += ['tree', 'table']
      when 'search_table', 'crud_panel', 'table'
        modules += ['table', 'form']
      when 'form'
        modules << 'form'
      end
    end
    
    modules.uniq
  end
  
  def generate_layui_vars(modules)
    vars = modules.map { |mod| "var #{mod} = layui.#{mod};" }.join("\n    ")
    "    #{vars}"
  end
  
  def generate_tree_table_script(tree_id, table_id, config)
    <<~JAVASCRIPT
      // 树表联动
      tree.render({
        elem: '##{tree_id}',
        url: '#{config[:tree_source] || '/api/tree'}',
        click: function(obj){
          table.reload('#{table_id}', {
            where: {
              tree_id: obj.data.id
            }
          });
        }
      });
      
      table.render({
        elem: '##{table_id}',
        url: '#{config[:table_source] || '/api/table'}',
        page: true,
        cols: #{(config[:columns] || []).to_json}
      });
    JAVASCRIPT
  end
  
  def generate_search_table_script(form_id, table_id, config)
    <<~JAVASCRIPT
      // 搜索表格
      var tableIns = table.render({
        elem: '##{table_id}',
        url: '#{config[:table_source] || '/api/search'}',
        page: true,
        cols: #{(config[:columns] || []).to_json}
      });
      
      form.on('submit(search)', function(data){
        tableIns.reload({
          where: data.field,
          page: { curr: 1 }
        });
        return false;
      });
    JAVASCRIPT
  end
  
  def generate_crud_script(table_id, form_id, config)
    <<~JAVASCRIPT
      // CRUD 面板
      var tableIns = table.render({
        elem: '##{table_id}',
        url: '#{config[:api_base] || '/api/crud'}',
        page: true,
        cols: #{(config[:columns] || []).to_json}
      });
      
      // 新增按钮
      $('#add-btn').click(function(){
        layer.open({
          type: 1,
          title: '新增',
          content: $('##{form_id}'),
          area: ['600px', '400px']
        });
      });
    JAVASCRIPT
  end
  
  def generate_form_script(form_id, config)
    <<~JAVASCRIPT
      // 表单提交
      form.on('submit(submit)', function(data){
        $.post('#{config[:action] || '/api/save'}', data.field, function(res){
          if(res.code === 0) {
            layer.msg('提交成功');
          } else {
            layer.msg('提交失败: ' + res.msg);
          }
        });
        return false;
      });
    JAVASCRIPT
  end
  
  def generate_generic_component(component)
    <<~HTML
      <div class="kr-component" data-type="#{component[:type]}">
        <!-- #{component[:type]} 组件 -->
        <p>组件类型: #{component[:type]}</p>
        <pre>#{component[:config].to_json}</pre>
      </div>
    HTML
  end
  
  def wrap_in_html_document(html_content, script_content)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>#{@page_config[:title] || 'KR Framework Page'}</title>
        <link rel="stylesheet" href="/layui/css/layui.css">
        <style>
          .kr-page-container { padding: 20px; }
          .kr-page-header { margin-bottom: 20px; }
          .kr-page-title { margin: 0; color: #333; }
          .kr-page-footer { margin-top: 30px; text-align: center; color: #999; }
          .number-range-container { position: relative; }
        </style>
      </head>
      <body>
        #{html_content}
        
        <script src="/layui/layui.js"></script>
        <script src="/assets/kr-runtime.js"></script>
        <script>
          #{script_content}
        </script>
      </body>
      </html>
    HTML
  end
end
