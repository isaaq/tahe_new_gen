require_relative 'test_common'

class TestTree < Test::Unit::TestCase
  include Common

  # 测试基本树组件
  def test_basic_tree
    code = <<~CODE
      <l:tree id="demo_tree" url="/api/tree/data" toolbar="true">
        <l:node_click tree_id="demo_tree">
          console.log("点击了节点:", param.nodeId);
          // 可以在这里处理节点点击事件
        </l:node_click>
      </l:tree>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试带复选框的树组件
  def test_tree_with_checkbox
    code = <<~CODE
      <l:tree id="demo_tree_checkbox" url="/api/tree/data" checkbar="true" check_type="all">
        <l:check_change tree_id="demo_tree_checkbox">
          console.log("复选框状态变化:", checkData);
          // 可以在这里处理复选框状态变化事件
        </l:check_change>
      </l:tree>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试带右键菜单的树组件
  def test_tree_with_contextmenu
    code = <<~CODE
      <l:tree id="demo_tree_menu" url="/api/tree/data" contextmenu="true" menu_items='[{"name": "添加", "icon": "dtree-icon-roundadd", "menubarId": "add"}, {"name": "删除", "icon": "dtree-icon-delete1", "menubarId": "delete"}]'>
        <l:menu_click tree_id="demo_tree_menu" menu_id="add">
          console.log("点击了添加菜单，当前节点:", param.nodeId);
          // 处理添加操作
        </l:menu_click>
        <l:menu_click tree_id="demo_tree_menu" menu_id="delete">
          console.log("点击了删除菜单，当前节点:", param.nodeId);
          // 处理删除操作
        </l:menu_click>
      </l:tree>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试带工具栏的树组件
  def test_tree_with_toolbar
    code = <<~CODE
      <l:tree id="demo_tree_toolbar" url="/api/tree/data" toolbar="true" toolbar_way="follow" toolbar_ext='[{"toolbarId": "add", "icon": "dtree-icon-roundadd", "title": "添加"}, {"toolbarId": "edit", "icon": "dtree-icon-bianji", "title": "编辑"}]'>
        <l:toolbar_click tree_id="demo_tree_toolbar" tool_id="add">
          console.log("点击了添加工具按钮，当前节点:", param.nodeId);
          // 处理添加操作
        </l:toolbar_click>
        <l:toolbar_click tree_id="demo_tree_toolbar" tool_id="edit">
          console.log("点击了编辑工具按钮，当前节点:", param.nodeId);
          // 处理编辑操作
        </l:toolbar_click>
      </l:tree>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  # 测试完整的树组件示例
  def test_complete_tree
    code = <<~CODE
      <l:layui>
        <l:tree id="demo_complete_tree" 
                url="/api/tree/data" 
                method="post"
                init_level="2"
                skin="laySimple"
                icon_style="dtreefont"
                width="300px"
                height="400px"
                data_format="list"
                data_style="layuiStyle"
                toolbar="true"
                toolbar_way="follow"
                toolbar_ext='[{"toolbarId": "add", "icon": "dtree-icon-roundadd", "title": "添加"}, {"toolbarId": "delete", "icon": "dtree-icon-delete1", "title": "删除"}]'
                checkbar="true"
                check_type="all"
                contextmenu="true"
                menu_items='[{"name": "添加", "icon": "dtree-icon-roundadd", "menubarId": "add"}, {"name": "删除", "icon": "dtree-icon-delete1", "menubarId": "delete"}]'>
          
          <l:node_click tree_id="demo_complete_tree">
            console.log("点击了节点:", param.nodeId);
            // 可以在这里处理节点点击事件
          </l:node_click>
          
          <l:node_dbclick tree_id="demo_complete_tree">
            console.log("双击了节点:", param.nodeId);
            // 可以在这里处理节点双击事件
          </l:node_dbclick>
          
          <l:check_change tree_id="demo_complete_tree">
            console.log("复选框状态变化:", checkData);
            // 可以在这里处理复选框状态变化事件
          </l:check_change>
          
          <l:menu_click tree_id="demo_complete_tree" menu_id="add">
            console.log("点击了添加菜单，当前节点:", param.nodeId);
            // 处理添加操作
          </l:menu_click>
          
          <l:menu_click tree_id="demo_complete_tree" menu_id="delete">
            console.log("点击了删除菜单，当前节点:", param.nodeId);
            // 处理删除操作
          </l:menu_click>
          
          <l:toolbar_click tree_id="demo_complete_tree" tool_id="add">
            console.log("点击了添加工具按钮，当前节点:", param.nodeId);
            // 处理添加操作
          </l:toolbar_click>
          
          <l:toolbar_click tree_id="demo_complete_tree" tool_id="delete">
            console.log("点击了删除工具按钮，当前节点:", param.nodeId);
            // 处理删除操作
          </l:toolbar_click>
        </l:tree>
      </l:layui>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  def test_kr_tree
    
  end
end
