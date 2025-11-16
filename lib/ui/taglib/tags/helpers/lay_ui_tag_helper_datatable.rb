module LayUITagHelperDatatable
  def datatable(opt, content)
    table_id = opt['id'] || "table_#{gen_id}"
    url = opt['url']
    method = opt['method'] || 'post'
    page = opt['page'] == 'true'
    limit = opt['limit'] || '10'
    limits = opt['limits'] || '[10, 20, 50, 100]'
    skin = opt['skin'] || 'line'
    even = opt['even'] == 'true'
    size = opt['size'] || ''
    
    # 获取其他配置项
    cell_min_width = opt['cell_min_width'] || '60'
    width = opt['width'] || '100%'
    height = opt['height']
    cols = opt['cols'] || '[]'
    response = opt['response'] || '{"statusName": "code", "statusCode": 0, "msgName": "msg", "dataName": "data", "countName": "count"}'
    
    # 生成表格配置对象
    config_options = {
      url: url,
      method: method,
      cellMinWidth: cell_min_width.to_i,
      skin: skin,
      size: size,
      cols: JSON.parse(cols),
      response: JSON.parse(response.gsub('=>', ':'))
    }
    
    # 添加分页配置
    if page
      config_options[:page] = true
      config_options[:limit] = limit.to_i
      config_options[:limits] = JSON.parse(limits.gsub('=>', ':'))
    end
    
    # 添加其他配置项
    config_options[:even] = true if even
    config_options[:width] = width
    config_options[:height] = height if height
    
    # 添加工具栏配置
    if opt['toolbar']
      config_options[:toolbar] = "##{opt['toolbar']}"
      config_options[:defaultToolbar] = opt['default_toolbar'] ? JSON.parse(opt['default_toolbar'].gsub('=>', ':')) : ['filter', 'exports', 'print']
    end
    
    # 将配置对象转换为JSON字符串
    config_json = config_options.to_json
    
    # 生成表格渲染代码
    out = <<~EOF
      <div class="layui-table-container" style="width: #{width};">
        <table id="#{table_id}" lay-filter="#{table_id}_filter"></table>
      </div>

@layui_script
layui.use(['table', 'jquery'], function() {
  // 使用运行时库创建数据表格
  var #{table_id}_inst = KR.UI.createDataTable('#{table_id}', #{config_json});
  
  #{content}
});
@/layui_script
    EOF
    
    out
  end
  
  # 表格工具栏点击事件
  def toolbar_event(opt, content)
    table_id = opt['table_id']
    out = <<~EOF
      #{table_id}_inst.onToolbarEvent(function(obj) {
        var checkStatus = table.checkStatus(obj.config.id);
        var data = checkStatus.data;
        var event = obj.event;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 表格行工具条点击事件
  def tool_event(opt, content)
    table_id = opt['table_id']
    out = <<~EOF
      #{table_id}_inst.onToolEvent(function(obj) {
        var data = obj.data;
        var event = obj.event;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 表格行点击事件
  def row_event(opt, content)
    table_id = opt['table_id']
    out = <<~EOF
      #{table_id}_inst.onRowEvent(function(obj) {
        var data = obj.data;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 表格单元格编辑事件
  def edit_event(opt, content)
    table_id = opt['table_id']
    out = <<~EOF
      #{table_id}_inst.onEditEvent(function(obj) {
        var value = obj.value;
        var data = obj.data;
        var field = obj.field;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 表格排序事件
  def sort_event(opt, content)
    table_id = opt['table_id']
    out = <<~EOF
      #{table_id}_inst.onSortEvent(function(obj) {
        var field = obj.field;
        var type = obj.type;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 表格复选框选择事件
  def checkbox_event(opt, content)
    table_id = opt['table_id']
    out = <<~EOF
      #{table_id}_inst.onCheckboxEvent(function(obj) {
        var checked = obj.checked;
        var data = obj.data;
        var type = obj.type;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 重载表格数据
  def reload_table(opt)
    table_id = opt['table_id']
    url = opt['url']
    where = opt['where'] || '{}'
    out = <<~EOF
      #{table_id}_inst.reload("#{url}", #{where});
    EOF
    
    out
  end
end