require_relative 'test_common'

class TestDatatable < Test::Unit::TestCase
  # 测试基本表格组件
  def test_basic_datatable
    code = <<~CODE
      <l:dt id="demo_table" url="/api/table/data" page="true" limit="15">
        <l:toolbar_event table_id="demo_table">
          if(event === 'add'){
            layer.msg('添加');
          } else if(event === 'delete'){
            layer.msg('删除');
          }
        </l:toolbar_event>
      </l:dt>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试带工具栏的表格组件
  def test_datatable_with_toolbar
    code = <<~CODE
      <l:dt id="demo_table_toolbar" url="/api/table/data" page="true" toolbar="toolbar_demo" default_toolbar='["filter", "print"]'>
        <l:toolbar_event table_id="demo_table_toolbar">
          if(event === 'add'){
            layer.msg('添加');
          } else if(event === 'delete'){
            layer.msg('批量删除');
          }
        </l:toolbar_event>
      </l:dt>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试带行工具栏的表格组件
  def test_datatable_with_tool
    code = <<~CODE
      <l:dt id="demo_table_tool" url="/api/table/data" page="true" tool="true">
        <l:tool_event table_id="demo_table_tool">
          if(event === 'edit'){
            layer.msg('编辑行：' + data.id);
          } else if(event === 'delete'){
            layer.msg('删除行：' + data.id);
          }
        </l:tool_event>
      </l:dt>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试表格行点击事件
  def test_datatable_row_event
    code = <<~CODE
      <l:dt id="demo_table_row" url="/api/table/data" page="true">
        <l:row_event table_id="demo_table_row">
          // 点击行
          layer.msg('选中行数据：' + JSON.stringify(data));
        </l:row_event>
      </l:dt>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试表格单元格编辑事件
  def test_datatable_edit_event
    code = <<~CODE
      <l:dt id="demo_table_edit" url="/api/table/data" page="true">
        <l:edit_event table_id="demo_table_edit">
          // 单元格编辑
          layer.msg('修改单元格：' + field + ' = ' + value);
        </l:edit_event>
      </l:dt>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试完整表格配置
  def test_datatable_full_config
    code = <<~CODE
      <l:dt id="demo_table_full" 
            url="/api/table/data" 
            page="true" 
            limit="20" 
            limits="[10, 20, 50, 100, 200]"
            skin="line" 
            even="true"
            size="sm"
            toolbar="toolbar_demo"
            default_toolbar='["filter", "exports"]'
            width="100%"
            height="500"
            cell_min_width="80"
            cols='[[
              {type: "checkbox", fixed: "left"},
              {field: "id", title: "ID", width: 80, sort: true, fixed: "left"},
              {field: "username", title: "用户名", width: 120, edit: "text"},
              {field: "email", title: "邮箱", width: 150},
              {field: "sex", title: "性别", width: 80, sort: true},
              {field: "city", title: "城市", width: 100},
              {field: "sign", title: "签名", width: 150},
              {field: "experience", title: "积分", width: 80, sort: true},
              {field: "ip", title: "IP", width: 120},
              {field: "createTime", title: "创建时间", width: 180},
              {fixed: "right", title: "操作", toolbar: "#tableBar", width: 150}
            ]]'>
        <l:toolbar_event table_id="demo_table_full">
          if(event === 'add'){
            layer.msg('添加');
          } else if(event === 'delete'){
            layer.msg('批量删除');
          }
        </l:toolbar_event>
        
        <l:tool_event table_id="demo_table_full">
          if(event === 'edit'){
            layer.msg('编辑行：' + data.id);
          } else if(event === 'delete'){
            layer.msg('删除行：' + data.id);
          }
        </l:tool_event>
        
        <l:checkbox_event table_id="demo_table_full">
          layer.msg(type === 'all' ? (checked ? '全选' : '取消全选') : (checked ? '选中' : '取消选中'));
        </l:checkbox_event>
      </l:dt>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end
end
