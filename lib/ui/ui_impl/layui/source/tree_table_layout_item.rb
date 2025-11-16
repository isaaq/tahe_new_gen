# frozen_string_literal: true

require 'securerandom'
require_relative '../layui_element'

# TreeTableLayoutItem - 树表联动布局项
# 负责处理 kr:tree_table_layout 标签，生成完整的树表联动布局
class TreeTableLayoutItem < LayuiElement
  attr_accessor :tree_config, :table_config, :linkage_config
  
  def pre_process
    # 提取子组件配置
    extract_components_config
    
    # 生成组件ID
    @tree_id = generate_component_id('tree')
    @table_id = generate_component_id('table')
  end
  
  def output_tag
    # 构建上下文
    context = build_context
    
    # 使用配置注册表转换（关键！）
    tree_l_attrs = ComponentConfigRegistry.transform('tree', @tree_config, context)
    table_l_attrs = ComponentConfigRegistry.transform('datatable', @table_config, context)
    
    # 生成l标签
    tree_html = generate_l_tree(tree_l_attrs)
    table_html = generate_l_datatable(table_l_attrs)
    linkage_script = generate_linkage_script
    
    # 组合布局
    layout_wrapper(tree_html, table_html, linkage_script)
  end
  
  private
  
  def extract_components_config
    # 从tag属性中提取配置
    @tree_config = {
      'url' => tag.attr['tree_source'] || '/api/tree',
      'search' => tag.attr['tree_search'] || 'false',
      'toolbar' => tag.attr['tree_toolbar'] || '',
      'checkbar' => tag.attr['tree_checkbar'] || 'false',
      'contextmenu' => tag.attr['tree_contextmenu'] || 'false'
    }
    
    @table_config = {
      'url' => tag.attr['table_source'] || '/api/table',
      'page' => tag.attr['table_page'] || 'true',
      'frozen-cols' => tag.attr['table_frozen_cols'] || '',
      'action-col' => tag.attr['table_action_col'] || 'false',
      'toolbar' => tag.attr['table_toolbar'] || 'false',
      'checkbox' => tag.attr['table_checkbox'] || 'false'
    }
    
    @linkage_config = {
      'tree_id' => @tree_id,
      'table_id' => @table_id,
      'link_param' => tag.attr['link_param'] || 'tree_id'
    }
  end
  
  def build_context
    {
      scenario: 'tree_table_layout',
      parent_component: self,
      linkage: true,
      tree_title: tag.attr['tree_title'] || '分类',
      table_title: tag.attr['table_title'] || '数据列表'
    }
  end
  
  def generate_l_tree(l_attrs)
    # attrs_str = serialize_attrs(l_attrs) # 暂时不使用，后续优化时使用
    
    <<~HTML
      <div class="layui-col-md4">
        <div class="layui-card">
          <div class="layui-card-header">#{tag.attr['tree_title'] || '分类'}</div>
          <div class="layui-card-body">
            <ul id="#{@tree_id}" class="dtree" data-id="#{@tree_id}"></ul>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_l_datatable(l_attrs)
    # attrs_str = serialize_attrs(l_attrs) # 暂时不使用，后续优化时使用
    
    <<~HTML
      <div class="layui-col-md8">
        <div class="layui-card">
          <div class="layui-card-header">#{tag.attr['table_title'] || '数据列表'}</div>
          <div class="layui-card-body">
            <table id="#{@table_id}" lay-filter="#{@table_id}_filter"></table>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_linkage_script
    link_param = @linkage_config['link_param']
    
    <<~JAVASCRIPT
      <script>
        layui.use(['dtree', 'table', 'jquery'], function(){
          var dtree = layui.dtree;
          var table = layui.table;
          var $ = layui.jquery;
          
          // 初始化树形控件
          dtree.render({
            elem: "##{@tree_id}",
            url: "#{@tree_config['url']}",
            #{generate_tree_options},
            click: function(obj){
              // 树表联动：点击树节点时重新加载表格
              table.reload('#{@table_id}', {
                where: {
                  #{link_param}: obj.param.nodeId
                }
              });
            }
          });
          
          // 初始化表格
          table.render({
            elem: '##{@table_id}',
            url: '#{@table_config['url']}',
            #{generate_table_options}
          });
        });
      </script>
    JAVASCRIPT
  end
  
  def generate_tree_options
    # 这里应该使用TreeConfigMapper的序列化方法
    # 暂时简化实现
    options = []
    
    options << "skin: 'laySimple'"
    options << "iconStyle: 'dtreefont'"
    options << "initLevel: 1"
    options << "dataFormat: 'list'"
    
    if @tree_config['search'] == 'true'
      options << "toolbar: true"
      options << "toolbarWay: 'follow'"
      options << "toolbarShow: ['searchIcon']"
    end
    
    if @tree_config['toolbar'] && !@tree_config['toolbar'].empty?
      options << "toolbarExt: #{build_toolbar_config}"
    end
    
    options.join(",\n            ")
  end
  
  def generate_table_options
    # 这里应该使用DatatableConfigMapper的序列化方法
    # 暂时简化实现
    options = []
    
    options << "page: #{@table_config['page'] == 'true'}"
    options << "limit: 10"
    options << "cellMinWidth: 60"
    
    if @table_config['page'] == 'true'
      options << "limits: [10, 20, 50, 100]"
    end
    
    options.join(",\n            ")
  end
  
  def layout_wrapper(tree_html, table_html, linkage_script)
    <<~HTML
      <div class="layui-row layui-col-space15">
        #{tree_html}
        #{table_html}
      </div>
      #{linkage_script}
    HTML
  end
  
  def build_toolbar_config
    buttons = @tree_config['toolbar'].split(',')
    toolbar_config = buttons.map do |btn|
      case btn.strip
      when 'add'
        "{ menubarId: 'btn-add', icon: 'layui-icon-add-1', title: '添加' }"
      when 'refresh'
        "{ menubarId: 'btn-refresh', icon: 'layui-icon-refresh', title: '刷新' }"
      else
        "{ menubarId: 'btn-#{btn.strip}', icon: 'layui-icon-more', title: '#{btn.strip}' }"
      end
    end
    
    "[#{toolbar_config.join(', ')}]"
  end
  
  def serialize_attrs(attrs)
    attrs.map do |key, value|
      case value
      when Hash
        "#{key}='#{value.to_json}'"
      when Array
        "#{key}='#{value.to_json}'"
      when String
        "#{key}='#{value}'"
      when true
        "#{key}='true'"
      when false
        "#{key}='false'"
      else
        "#{key}=#{value}"
      end
    end.join(' ')
  end
  
  def generate_component_id(prefix)
    "#{prefix}_#{SecureRandom.hex(4)}"
  end
end
