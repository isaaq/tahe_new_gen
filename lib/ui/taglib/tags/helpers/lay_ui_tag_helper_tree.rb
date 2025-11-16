module LayUITagHelperTree
  # dtree 组件的基本实现
  def tree(opt, content)
    tree_id = opt['id'] || "dtree_#{gen_id}"
    url = opt['url']
    method = opt['method'] || 'post'
    init_level = opt['init_level'] || '1'
    skin = opt['skin'] || 'laySimple'  # laySimple, layui
    icon_style = opt['icon_style'] || 'dtreefont'  # dtreefont, layui
    
    # 工具栏配置
    toolbar = opt['toolbar'] == 'true'
    toolbar_way = opt['toolbar_way'] || 'follow'  # contextmenu, follow, fixed
    toolbar_show = opt['toolbar_show'] || '[]'
    toolbar_ext = opt['toolbar_ext'] || '[]'
    
    # 复选框配置
    checkbar = opt['checkbar'] == 'true'
    check_type = opt['check_type'] || '"all"'  # all, only, no
    
    # 菜单配置
    contextmenu = opt['contextmenu'] == 'true'
    menu_items = opt['menu_items'] || '[]'
    
    # 样式配置
    width = opt['width'] || '100%'
    height = opt['height'] || '100%'
    
    # 数据配置
    data_format = opt['data_format'] || 'list'  # list, tree
    data_style = opt['data_style'] || 'layuiStyle'  # layuiStyle, defaultStyle
    response = opt['response'] || '{ "statusName": "code", "statusCode": 0, "message": "msg", "rootName": "data" }'
    
    # 生成 dtree 配置
    dtree_config = <<~EOF
      elem: "##{tree_id}",
      url: "#{url}",
      method: "#{method}",
      initLevel: #{init_level},
      skin: "#{skin}",
      iconStyle: "#{icon_style}",
      width: "#{width}",
      height: "#{height}",
      dataFormat: "#{data_format}",
      dataStyle: "#{data_style}",
      response: #{response},
    EOF
    
    # 添加工具栏配置
    if toolbar
      dtree_config += <<~EOF
        toolbar: true,
        toolbarWay: "#{toolbar_way}",
        toolbarShow: #{toolbar_show},
        toolbarExt: #{toolbar_ext},
      EOF
    end
    
    # 添加复选框配置
    if checkbar
      dtree_config += <<~EOF
        checkbar: true,
        checkbarType: #{check_type},
      EOF
    end
    
    # 添加右键菜单配置
    if contextmenu
      dtree_config += <<~EOF
        contextmenu: true,
        menubar: true,
        menubarFun: {
          remove: function(checkbarNodes) { 
            return checkbarNodes;
          }
        },
        menuItems: #{menu_items},
      EOF
    end
    
    # 生成 dtree 渲染代码
    out = <<~EOF
      <div class="layui-dtree-container" style="width: #{width}; height: #{height};">
        <ul id="#{tree_id}" class="dtree" data-id="#{tree_id}"></ul>
      </div>
      
      @layui_script
      layui.extend({
        dtree: '{/}/matrix/templates/pear/component/pear/module/dtree/dtree'
      }).use(['dtree', 'jquery'], function() {
        var dtree = layui.dtree;
        var $ = layui.jquery;
        
        // 渲染树
        var #{tree_id}_inst = dtree.render({
          #{dtree_config}
        });
        
        #{content}
      });
      @/layui_script
    EOF
    
    out
  end
  
  # 节点点击事件
  def node_click(opt, content)
    tree_id = opt['tree_id']
    out = <<~EOF
      dtree.on("node('#{tree_id}')" ,function(obj) {
        var param = obj.param;
        var $div = obj.div;
        var done = obj.done;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 节点双击事件
  def node_dbclick(opt, content)
    tree_id = opt['tree_id']
    out = <<~EOF
      dtree.on("nodedblclick('#{tree_id}')" ,function(obj) {
        var param = obj.param;
        var $div = obj.div;
        var done = obj.done;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 复选框点击事件
  def check_change(opt, content)
    tree_id = opt['tree_id']
    out = <<~EOF
      dtree.on("checkChange('#{tree_id}')" ,function(obj) {
        var param = obj.param;
        var $div = obj.div;
        var checked = obj.checked;
        var checkData = obj.checkData;
        
        #{content}
      });
    EOF
    
    out
  end
  
  # 菜单点击事件
  def menu_click(opt, content)
    tree_id = opt['tree_id']
    menu_id = opt['menu_id']
    out = <<~EOF
      dtree.on("menuClick('#{tree_id}')" ,function(obj) {
        var param = obj.param;
        var $div = obj.div;
        var menuId = obj.menuId;
        
        if(menuId == "#{menu_id}") {
          #{content}
        }
      });
    EOF
    
    out
  end
  
  # 工具栏点击事件
  def toolbar_click(opt, content)
    tree_id = opt['tree_id']
    tool_id = opt['tool_id']
    out = <<~EOF
      dtree.on("toolbarClick('#{tree_id}')" ,function(obj) {
        var param = obj.param;
        var $div = obj.div;
        var toolId = obj.toolId;
        
        if(toolId == "#{tool_id}") {
          #{content}
        }
      });
    EOF
    
    out
  end
  
  # 获取选中节点
  def get_checked_nodes(opt)
    tree_id = opt['tree_id']
    out = <<~EOF
      var checkedData = dtree.getCheckbarNodesParam("#{tree_id}");
    EOF
    
    out
  end
  
  # 获取当前选中节点
  def get_selected_node(opt)
    tree_id = opt['tree_id']
    out = <<~EOF
      var selectedNode = dtree.getNowParam("#{tree_id}");
    EOF
    
    out
  end
  
  # 重载树
  def reload_tree(opt)
    tree_id = opt['tree_id']
    url = opt['url']
    out = <<~EOF
      dtree.reload("#{tree_id}", {
        url: "#{url}"
      });
    EOF
    
    out
  end
end
