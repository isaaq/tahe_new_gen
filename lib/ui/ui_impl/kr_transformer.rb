# frozen_string_literal: true

require_relative '../../util/common'

class KrTransformer
  include Common
  
  # kr 标签到 layui 标签的映射字典
  DICT = { 
    # 基础组件
    col: :TableColItem, 
    table: :TableItem, 
    form: :FormTag, 
    input: :InputItem, 
    page: :PageItem, 
    layout: :LayoutItem, 
    layout_panel: :LayoutPanel,
    button: :ButtonItem,
    
    # 表单组件
    select: :SelectItem,
    textarea: :TextareaItem,
    checkbox: :CheckboxItem,
    radio: :RadioItem,
    switch: :SwitchItem,
    slider: :SliderItem,
    rate: :RateItem,
    colorpicker: :ColorpickerItem,
    
    # 数据组件
    datatable: :TableItem,
    tree: :TreeItem,
    tree_table: :TreeTableItem,
    transfer: :TransferItem,
    
    # 时间日期组件
    date_picker: :DatePickerItem,
    datetime_picker: :DatetimePickerItem,
    time_picker: :TimePickerItem,
    
    # 上传组件
    upload: :UploadItem,
    
    # 自定义聚合组件
    number_range_input: :NumberRangeInputItem,
    
    # 交互组件
    dropdown: :DropdownItem,
    layer: :LayerItem,
    
    # 导航组件
    menu: :MenuItem,
    breadcrumb: :BreadcrumbItem,
    
    # 布局组件
    grid: :GridItem,
    card: :CardItem,
    tabs: :TabsItem,
    
    # 业务聚合组件
    tree_table_layout: :TreeTableLayoutItem,
    search_table: :SearchTableItem,
    master_detail_form: :MasterDetailFormItem,
    crud_panel: :CrudPanelItem,
    filter_panel: :FilterPanelItem
  }
  
  def self.trans(tag, ctx, children = nil)
    transformer = new
    transformer.transform(tag, ctx, children)
  end
  
  def initialize
    @node_context = nil
  end
  
  def transform(tag, ctx, children = nil)
    # 加载节点配置上下文
    load_node_context()
    
    # 查找对应的元数据
    metadata = find_metadata(tag, ctx, children)
    
    # 根据标签类型创建对应的处理器
    clzname = DICT[tag.name.to_sym]
    
    if clzname && Object.const_defined?(clzname)
      create_element(clzname, tag, ctx, metadata, children)
    else
      # 尝试动态处理未知标签
      handle_unknown_tag(tag, ctx, children)
    end
  end
  
  private
  
  def load_node_context
    return @node_context if @node_context
    
    begin
      # 读取节点配置文件
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
  
  def find_metadata(tag, ctx, children)
    # 查找标签对应的元数据
    if !children.nil?
      # 根节点查找
      ctx[tag['id'].to_sym] if tag['id']
    else
      # 子节点查找
      if tag.parent && tag.parent['id']
        parent_ctx = ctx[tag.parent['id'].to_sym]
        if parent_ctx && parent_ctx[tag.name.to_sym]
          parent_ctx[tag.name.to_sym].find { |f| f[:id] == tag['id'] }
        end
      end
    end
  end
  
  def create_element(clzname, tag, ctx, metadata, children)
    begin
      ele = Object.const_get(clzname).new
      ele.tag = tag
      ele.context = ctx
      ele.object_tree = metadata
      ele.children = children
      
      # 注入节点配置上下文
      ele.node_context = @node_context if ele.respond_to?(:node_context=)
      
      ele.output
    rescue => e
      __p "创建元素失败 #{clzname}: #{e.message}"
      generate_fallback_output(tag, children)
    end
  end
  
  def handle_unknown_tag(tag, ctx, children)
    __p "未找到#{tag.name}对应的类，尝试动态处理"
    
    # 根据标签名称尝试推断处理方式
    case tag.name.to_s
    when /form/i
      generate_form_fallback(tag, children)
    when /table|datatable/i
      generate_table_fallback(tag, children)
    when /input|field/i
      generate_input_fallback(tag, children)
    else
      generate_fallback_output(tag, children)
    end
  end
  
  def generate_form_fallback(tag, children)
    # 生成表单的后备输出
    form_attrs = extract_attributes(tag)
    child_content = children ? (children.is_a?(Array) ? children.join("\n") : children.to_s) : ""
    
    <<~HTML
      <form class="layui-form" #{form_attrs}>
        #{child_content}
        <div class="layui-form-item">
          <div class="layui-input-block">
            <button class="layui-btn" type="submit">提交</button>
          </div>
        </div>
      </form>
    HTML
  end
  
  def generate_table_fallback(tag, children)
    # 生成表格的后备输出
    table_attrs = extract_attributes(tag)
    
    <<~HTML
      <table class="layui-table" #{table_attrs}>
        <thead>
          <tr>
            #{children ? (children.is_a?(Array) ? children.join("\n") : children.to_s) : "<th>列1</th><th>列2</th>"}
          </tr>
        </thead>
        <tbody>
          <!-- 动态内容 -->
        </tbody>
      </table>
    HTML
  end
  
  def generate_input_fallback(tag, children)
    # 生成输入框的后备输出
    input_attrs = extract_attributes(tag)
    label = tag['label'] || tag['name'] || '输入'
    
    <<~HTML
      <div class="layui-form-item">
        <label class="layui-form-label">#{label}</label>
        <div class="layui-input-block">
          <input type="text" class="layui-input" #{input_attrs}>
        </div>
      </div>
    HTML
  end
  
  def generate_fallback_output(tag, children)
    # 通用后备输出
    attrs = extract_attributes(tag)
    child_content = children ? (children.is_a?(Array) ? children.join("\n") : children.to_s) : ""
    
    <<~HTML
      <div class="kr-unknown-tag" data-tag="#{tag.name}" #{attrs}>
        #{child_content}
      </div>
    HTML
  end
  
  def extract_attributes(tag)
    return "" unless tag.respond_to?(:attributes) || tag.respond_to?(:[]) 
    
    attrs = []
    
    # 提取常见属性
    ['id', 'class', 'name', 'value', 'placeholder', 'required'].each do |attr|
      if tag[attr]
        attrs << "#{attr}=\"#{tag[attr]}\""
      end
    end
    
    attrs.join(' ')
  end
end
