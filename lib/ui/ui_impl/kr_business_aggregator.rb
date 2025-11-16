# frozen_string_literal: true

# KR 业务聚合标签处理器
# 处理复杂的业务场景，如左树右表、搜索+表格等
class KrBusinessAggregator
  include Common
  
  # 业务聚合标签映射
  BUSINESS_TAGS = {
    # 布局聚合
    tree_table_layout: :TreeTableLayoutAggregator,
    search_table: :SearchTableAggregator,
    master_detail_form: :MasterDetailFormAggregator,
    
    # 表单聚合
    search_form: :SearchFormAggregator,
    filter_panel: :FilterPanelAggregator,
    
    # 数据聚合
    crud_table: :CrudTableAggregator,
    report_dashboard: :ReportDashboardAggregator,
    
    # 导航聚合
    sidebar_content: :SidebarContentAggregator,
    tab_content: :TabContentAggregator
  }
  
  def self.process(tag, ctx, children = nil)
    aggregator = new
    aggregator.aggregate(tag, ctx, children)
  end
  
  def initialize
    @node_context = nil
  end
  
  def aggregate(tag, ctx, children = nil)
    load_node_context()
    
    aggregator_class = BUSINESS_TAGS[tag.name.to_sym]
    if aggregator_class && Object.const_defined?(aggregator_class)
      create_aggregator(aggregator_class, tag, ctx, children)
    else
      # 回退到基础 KrTransformer
      KrTransformer.trans(tag, ctx, children)
    end
  end
  
  private
  
  def load_node_context
    return @node_context if @node_context
    
    begin
      file = M[:sys_files].query(Name: 'test_node.krnode').to_a[0]
      if file && file[:Content]
        @node_context = KrNodeBuilder.build(file[:Content])
      else
        @node_context = {}
      end
    rescue => e
      __p "加载节点配置失败: #{e.message}"
      @node_context = {}
    end
  end
  
  def create_aggregator(aggregator_class, tag, ctx, children)
    begin
      aggregator = Object.const_get(aggregator_class).new
      aggregator.tag = tag
      aggregator.context = ctx
      aggregator.children = children
      aggregator.node_context = @node_context
      aggregator.aggregate
    rescue => e
      __p "创建业务聚合器失败 #{aggregator_class}: #{e.message}"
      generate_fallback_layout(tag, children)
    end
  end
  
  def generate_fallback_layout(tag, children)
    child_content = children ? children.join("\n") : ""
    
    <<~HTML
      <div class="kr-business-layout" data-layout="#{tag.name}">
        #{child_content}
      </div>
    HTML
  end
end

# 基础业务聚合器
class BaseBusinessAggregator
  include Common
  attr_accessor :tag, :context, :children, :node_context
  
  def aggregate
    raise NotImplementedError, "子类必须实现 aggregate 方法"
  end
  
  protected
  
  def generate_layout_container(layout_class, content)
    <<~HTML
      <div class="layui-container #{layout_class}">
        #{content}
      </div>
    HTML
  end
  
  def generate_row(content, gutter = false)
    gutter_class = gutter ? "layui-row layui-col-space15" : "layui-row"
    <<~HTML
      <div class="#{gutter_class}">
        #{content}
      </div>
    HTML
  end
  
  def generate_col(content, span = 12)
    <<~HTML
      <div class="layui-col-md#{span}">
        #{content}
      </div>
    HTML
  end
end

# 左树右表布局聚合器
class TreeTableLayoutAggregator < BaseBusinessAggregator
  def aggregate
    tree_config = extract_tree_config
    table_config = extract_table_config
    
    tree_html = generate_tree_section(tree_config)
    table_html = generate_table_section(table_config)
    
    layout_html = generate_row(
      generate_col(tree_html, 4) + 
      generate_col(table_html, 8),
      true
    )
    
    generate_layout_container("tree-table-layout", layout_html) + 
    generate_tree_table_script(tree_config, table_config)
  end
  
  private
  
  def extract_tree_config
    tree_child = children&.find { |child| child.include?('kr:tree') }
    {
      id: "tree_#{SecureRandom.hex(4)}",
      source: extract_attribute(tree_child, 'source') || '/api/tree',
      click_reload_table: true
    }
  end
  
  def extract_table_config
    table_child = children&.find { |child| child.include?('kr:table') }
    {
      id: "table_#{SecureRandom.hex(4)}",
      source: extract_attribute(table_child, 'source') || '/api/table',
      filter_param: 'tree_id'
    }
  end
  
  def generate_tree_section(config)
    <<~HTML
      <div class="tree-section">
        <div class="layui-card">
          <div class="layui-card-header">分类</div>
          <div class="layui-card-body">
            <ul id="#{config[:id]}" class="layui-tree"></ul>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_table_section(config)
    <<~HTML
      <div class="table-section">
        <div class="layui-card">
          <div class="layui-card-header">数据列表</div>
          <div class="layui-card-body">
            <table id="#{config[:id]}" lay-filter="#{config[:id]}"></table>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_tree_table_script(tree_config, table_config)
    <<~HTML
      <script>
        layui.use(['tree', 'table'], function(){
          var tree = layui.tree;
          var table = layui.table;
          
          // 初始化树形控件
          tree.render({
            elem: '##{tree_config[:id]}',
            url: '#{tree_config[:source]}',
            click: function(obj){
              // 点击树节点时重新加载表格
              table.reload('#{table_config[:id]}', {
                where: {
                  #{table_config[:filter_param]}: obj.data.id
                }
              });
            }
          });
          
          // 初始化表格
          table.render({
            elem: '##{table_config[:id]}',
            url: '#{table_config[:source]}',
            page: true,
            cols: [[
              // 动态列配置
            ]]
          });
        });
      </script>
    HTML
  end
  
  def extract_attribute(html_string, attr_name)
    return nil unless html_string
    match = html_string.match(/#{attr_name}=["']([^"']*)["']/)
    match ? match[1] : nil
  end
end

# 搜索+表格聚合器
class SearchTableAggregator < BaseBusinessAggregator
  def aggregate
    search_config = extract_search_config
    table_config = extract_table_config
    
    search_html = generate_search_section(search_config)
    table_html = generate_table_section(table_config)
    
    layout_html = search_html + table_html
    
    generate_layout_container("search-table-layout", layout_html) + 
    generate_search_table_script(search_config, table_config)
  end
  
  private
  
  def extract_search_config
    {
      id: "search_form_#{SecureRandom.hex(4)}",
      fields: extract_search_fields
    }
  end
  
  def extract_table_config
    {
      id: "search_table_#{SecureRandom.hex(4)}",
      source: extract_table_source
    }
  end
  
  def extract_search_fields
    # 从 children 中提取搜索字段配置
    fields = []
    children&.each do |child|
      if child.include?('kr:search_form')
        # 解析搜索表单中的字段
        fields << { name: 'keyword', type: 'input', label: '关键词' }
        fields << { name: 'status', type: 'select', label: '状态' }
      end
    end
    fields
  end
  
  def extract_table_source
    table_child = children&.find { |child| child.include?('kr:table') }
    extract_attribute(table_child, 'source') || '/api/search'
  end
  
  def generate_search_section(config)
    fields_html = config[:fields].map do |field|
      case field[:type]
      when 'input'
        <<~HTML
          <div class="layui-inline">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-inline">
              <input type="text" name="#{field[:name]}" placeholder="请输入#{field[:label]}" class="layui-input">
            </div>
          </div>
        HTML
      when 'select'
        <<~HTML
          <div class="layui-inline">
            <label class="layui-form-label">#{field[:label]}</label>
            <div class="layui-input-inline">
              <select name="#{field[:name]}">
                <option value="">请选择#{field[:label]}</option>
              </select>
            </div>
          </div>
        HTML
      end
    end.join("\n")
    
    <<~HTML
      <div class="search-section">
        <div class="layui-card">
          <div class="layui-card-body">
            <form class="layui-form" id="#{config[:id]}" lay-filter="#{config[:id]}">
              #{fields_html}
              <div class="layui-inline">
                <button class="layui-btn" lay-submit lay-filter="search">搜索</button>
                <button type="reset" class="layui-btn layui-btn-primary">重置</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_table_section(config)
    <<~HTML
      <div class="table-section">
        <div class="layui-card">
          <div class="layui-card-body">
            <table id="#{config[:id]}" lay-filter="#{config[:id]}"></table>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_search_table_script(search_config, table_config)
    <<~HTML
      <script>
        layui.use(['form', 'table'], function(){
          var form = layui.form;
          var table = layui.table;
          
          // 初始化表格
          var tableIns = table.render({
            elem: '##{table_config[:id]}',
            url: '#{table_config[:source]}',
            page: true,
            cols: [[
              // 动态列配置
            ]]
          });
          
          // 搜索表单提交
          form.on('submit(search)', function(data){
            tableIns.reload({
              where: data.field,
              page: {
                curr: 1
              }
            });
            return false;
          });
        });
      </script>
    HTML
  end
  
  def extract_attribute(html_string, attr_name)
    return nil unless html_string
    match = html_string.match(/#{attr_name}=["']([^"']*)["']/)
    match ? match[1] : nil
  end
end
