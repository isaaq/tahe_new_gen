require_relative '../tags/kr/tag_tree'
require_relative '../tags/kr/tag_datatable'
require_relative 'helpers/lay_ui_tag_helper_datatable'
require_relative 'helpers/lay_ui_tag_helper_tree'
require_relative 'helpers/lay_ui_tag_helper_layout'

class TagLibraryLayui < Tags::TagLibrary
  extend LayUITagHelper
  extend LayUITagHelperTree
  extend LayUITagHelperDatatable
  extend LayUITagHelperLayout
  prefix :l

  register_root_tag :layui, :'t', :f, :nri, :l_layout, :l_layout_panel, :table, :'t-top', :'t-item', :'t-item-sel', :'t-item-dlg', :'t-item-date', :'t-dpbtn', :'t-tb', :'t-col', :'t-btn', :'t-add', :'t-edit', :'t-del', :'t-disable', :layui, :tab
  register_child_tag :layui, :'col', :i, :nri, :'tab-item'
  
  # 直接定义 layout 标签
  tag :l_layout do |tag|
    puts "DEBUG: layout 标签被调用，参数: #{tag.attr.inspect}"
    type = tag.attr['type'] || 'row'
    style = tag.attr['style'] || ''
    id = tag.attr['id'] ? "id=\"#{tag.attr['id']}\"" : ''
    
    content = tag.expand
    
    case type
    when 'row'
      # 行布局
      <<~EOF
      <div class="layui-row" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    when 'col'
      # 列布局
      <<~EOF
      <div class="layui-col" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    when 'card'
      # 卡片布局
      <<~EOF
      <div class="layui-card" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    else
      # 默认布局
      <<~EOF
      <div class="layui-container" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    end
  end
  
  # 直接定义 layout_panel 标签
  tag :l_layout_panel do |tag|
    puts "DEBUG: layout_panel 标签被调用，参数: #{tag.attr.inspect}"
    width = tag.attr['width'] || '100%'
    height = tag.attr['height'] || 'auto'
    style = tag.attr['style'] || ''
    id = tag.attr['id'] ? "id=\"#{tag.attr['id']}\"" : ''
    
    content = tag.expand
    
    # 计算 layui 的栅格系统宽度
    grid_width = if width.end_with?('%')
                   (width.to_f / 100 * 12).round
                 else
                   6 # 默认为一半宽度
                 end
    
    <<~EOF
    <div class="layui-col-md#{grid_width}" #{id} style="#{style}; height: #{height};">
      #{content}
    </div>
    EOF
  end
  
  # 定义 table 标签的处理（l:标签层 → HTML）
  tag :table do |tag|
    puts "DEBUG: table 标签被调用，参数: #{tag.attr.inspect}"
    # 生成LayUI表格HTML结构
    table_id = tag.attr['id'] || 'table_default'
    url = tag.attr['url'] || '/api/query'
    method = tag.attr['method'] || 'POST'
    page = tag.attr['page'] == 'true'
    limit = tag.attr['limit'] || '20'
    query_protocol = tag.attr['query_protocol']
    
    content = tag.expand
    
    <<~HTML
      <div id="#{table_id}" class="layui-table-container">
        <div class="layui-table-body">
          <!-- 表格内容将由JavaScript动态生成 -->
          <div class="layui-table-loading">加载中...</div>
        </div>
      </div>
      
      <script>
        layui.use(['table'], function() {
          var table = layui.table;
          
          // 查询协议
          var queryProtocol = #{query_protocol ? query_protocol : '{}'};
          
          // 渲染表格
          table.render({
            elem: '##{table_id}',
            url: '#{url}',
            method: '#{method}',
            contentType: 'application/json',
            where: queryProtocol,
            page: #{page},
            limit: #{limit},
            cols: [[
              // 列配置将由子组件生成
              {field: 'id', title: 'ID', width: 80},
              {field: 'name', title: '名称', width: 120}
            ]]
          });
        });
      </script>
      
      #{content}
    HTML
  end
  
  # 搜索过滤组件
  tag :'t-top' do |tag|
    content = tag.expand
    <<~HTML
      <div class="layui-card">
        <div class="layui-card-body">
          <form class="layui-form" lay-filter="searchForm">
            <div class="layui-form-item">
              #{content}
            </div>
            <div class="layui-form-item">
              <button class="layui-btn" lay-submit lay-filter="search">查询</button>
              <button type="reset" class="layui-btn layui-btn-primary">重置</button>
            </div>
          </form>
        </div>
      </div>
    HTML
  end

  tag :'t-item' do |tag|
    text = tag.attr['text']
    field = tag.attr['field']
    <<~HTML
      <div class="layui-inline">
        <label class="layui-form-label">#{text}</label>
        <div class="layui-input-inline">
          <input type="text" name="#{field}" placeholder="请输入#{text}" class="layui-input">
        </div>
      </div>
    HTML
  end

  tag :'t-item-sel' do |tag|
    text = tag.attr['text']
    field = tag.attr['field']
    enum_str = tag.attr['enum'] || ''
    enum_values = enum_str.split(',')
    
    options = enum_values.map { |val| "<option value=\"#{val.strip}\">#{val.strip}</option>" }.join("\n")
    
    <<~HTML
      <div class="layui-inline">
        <label class="layui-form-label">#{text}</label>
        <div class="layui-input-inline">
          <select name="#{field}">
            <option value="">请选择</option>
            #{options}
          </select>
        </div>
      </div>
    HTML
  end

  tag :'t-item-date' do |tag|
    text = tag.attr['text']
    field = tag.attr['field']
    <<~HTML
      <div class="layui-inline">
        <label class="layui-form-label">#{text}</label>
        <div class="layui-input-inline">
          <input type="text" name="#{field}" id="#{field}" placeholder="yyyy-MM-dd" class="layui-input" readonly>
        </div>
      </div>
    HTML
  end

  # 标签页组件
  tag :tab do |tag|
    content = tag.expand
    tab_id = tag.attr['id'] || 'tab_default'
    filter = tag.attr['filter'] || ''
    
    <<~HTML
      <div class="layui-tab layui-tab-brief" lay-filter="#{filter}">
        <ul class="layui-tab-title">
          <!-- 标签页标题将由子组件生成 -->
        </ul>
        <div class="layui-tab-content">
          #{content}
        </div>
      </div>
    HTML
  end

  tag :'tab-item' do |tag|
    lbl = tag.attr['lbl']
    tab_id = tag.attr['id']
    sel = tag.attr['sel'] == 'true'
    content = tag.expand
    
    active_class = sel ? 'layui-this' : ''
    
    <<~HTML
      <div class="layui-tab-item #{active_class}" lay-id="#{tab_id}">
        #{content}
      </div>
    HTML
  end

  # 表格工具栏
  tag :'t-tb' do |tag|
    content = tag.expand
    <<~HTML
      <div class="layui-btn-group">
        #{content}
      </div>
    HTML
  end

  tag :'t-dpbtn' do |tag|
    id = tag.attr['id']
    text = tag.attr['text']
    enum_str = tag.attr['enum'] || ''
    cb = tag.attr['cb'] || ''
    url = tag.attr['url'] || ''
    
    enum_values = enum_str.split(',')
    dropdown_items = enum_values.map { |val| "<li><a href=\"#\" onclick=\"#{cb}({text:'#{val.strip}', url:'#{url}'})\">#{val.strip}</a></li>" }.join("\n")
    
    <<~HTML
      <div class="layui-btn-group">
        <button class="layui-btn" id="#{id}">#{text}</button>
        <button class="layui-btn layui-btn-primary layui-btn-dropdown" lay-dropdown>
          <span class="layui-icon layui-icon-down"></span>
        </button>
        <ul class="layui-dropdown-menu">
          #{dropdown_items}
        </ul>
      </div>
    HTML
  end

  # 表格列配置
  tag :'t-col' do |tag|
    title = tag.attr['title']
    field = tag.attr['field']
    width = tag.attr['width']
    type = tag.attr['type']
    enum_str = tag.attr['enum']
    fk = tag.attr['fk']
    templet = tag.attr['templet']
    content = tag.expand
    
    col_config = {
      field: field,
      title: title,
      width: width
    }
    
    # 处理枚举类型
    if type == 'enum' && enum_str
      enum_values = enum_str.split(',')
      col_config[:templet] = "function(d){ var enum_map = #{enum_values.map.with_index { |v, i| [i, v.strip] }.to_h.to_json}; return enum_map[d.#{field}] || d.#{field}; }"
    end
    
    # 处理FK关联
    if fk
      fk_parts = fk.split(',')
      if fk_parts.length >= 4
        target_collection = fk_parts[0]
        foreign_key = fk_parts[1] 
        display_field = fk_parts[2]
        col_config[:templet] = "function(d){ return d.#{field}_name || d.#{field}; }"
      end
    end
    
    # 处理自定义模板
    if templet
      col_config[:templet] = templet
    end
    
    # 处理操作列
    if type == 'op'
      col_config[:toolbar] = '#' + (tag.attr['id'] || 'op_toolbar')
    end
    
    # 暂时返回简单的列配置
    "<!-- 列配置: #{col_config.to_json} -->"
  end

  tag :'t-btn' do |tag|
    title = tag.attr['title']
    url = tag.attr['url']
    type = tag.attr['type'] || 'url'
    cb = tag.attr['cb']
    confirm = tag.attr['confirm']
    if_condition = tag.attr['if']
    
    if type == 'cmd' && cb
      onclick = "onclick=\"#{cb}\""
    elsif url
      onclick = "onclick=\"window.openurl('#{url}')\""
    else
      onclick = ""
    end
    
    confirm_attr = confirm ? "lay-confirm=\"#{confirm}\"" : ""
    
    <<~HTML
      <a class="layui-btn layui-btn-xs" #{onclick} #{confirm_attr}>#{title}</a>
    HTML
  end

  include TreeTags
  include DataTableTags
end
