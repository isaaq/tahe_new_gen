# frozen_string_literal: true

class TagLibraryKr < Tags::TagLibrary
  extend KrTagHelper
  prefix :kr

  tag :test do |_tag|
    "<%=_kr_ui_scope_var%>"
  end

  tag :test2 do |_tag|
    "<%parse_reg_area('global_func','a=1;b=2', :append)%>"
  end

  tag :test3 do |_tag|
  end

  # 定义 datatable 标签的处理逻辑
  tag :datatable do |tag|
    # 手动处理 datatable 标签
    id = tag.attr["id"] || "datatable_#{SecureRandom.hex(4)}"
    
    # 获取子内容（包含 kr:col 标签）
    children_content = tag.expand
    
    # 直接创建 TableItem 并处理
    table_item = TableItem.new
    table_item.tag = tag
    table_item.context = @context
    table_item.children = children_content
    table_item.output
  end
  
  # 定义 col 标签，返回原始标签字符串（保留用于后续解析）
  tag :col do |tag|
    # 重新构建原始标签字符串
    attrs = tag.attr.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    "<kr:col #{attrs} />"
  end

  register_root_tag :kr, :table, :form, :page, :number_range_input, :layout, :script, :layout_panel
  register_child_tag :kr, :input, :number_range_input
end
