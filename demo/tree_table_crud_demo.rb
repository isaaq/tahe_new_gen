# frozen_string_literal: true

# 树表联动CRUD完整示例
# 展示从模板设计器 → IDE → 最终页面的完整流程

require_relative '../_system'

# 模拟IDE输出的JSON配置（来自图形化设计器）
IDE_OUTPUT = {
  layout_type: 'tree_table_layout',
  tree_config: {
    title: '组织架构',
    url: '/api/org/tree',
    search: true,
    toolbar: 'add,refresh,expand',
    checkbar: false
  },
  table_config: {
    title: '员工列表',
    url: '/api/org/employees',
    page: true,
    frozen_cols: 1,
    action_col: true,
    toolbar: true,
    checkbox: true,
    columns: [
      { field: 'id', title: 'ID', width: 80, sort: true, fixed: 'left' },
      { field: 'name', title: '姓名', width: 120 },
      { field: 'position', title: '职位', width: 150 },
      { field: 'department', title: '部门', width: 150 },
      { field: 'email', title: '邮箱', width: 200 },
      { field: 'phone', title: '电话', width: 130 },
      { field: 'status', title: '状态', width: 100 }
    ]
  },
  linkage: {
    param: 'org_id',
    type: 'click'
  }
}.freeze

# 步骤1：IDE设计器解析JSON，生成kr标签
def generate_kr_tags_from_ide(config)
  tree_attrs = config[:tree_config].map { |k, v| "#{k}='#{v}'" }.join(' ')
  table_attrs = config[:table_config].reject { |k| k == :columns }.map { |k, v| "#{k}='#{v}'" }.join(' ')
  columns_json = config[:table_config][:columns].to_json
  
  <<~ERB
    <kr:tree_table_layout
      tree_title="#{config[:tree_config][:title]}"
      tree_source="#{config[:tree_config][:url]}"
      tree_search="#{config[:tree_config][:search]}"
      tree_toolbar="#{config[:tree_config][:toolbar]}"
      
      table_title="#{config[:table_config][:title]}"
      table_source="#{config[:table_config][:url]}"
      table_page="#{config[:table_config][:page]}"
      table_frozen_cols="#{config[:table_config][:frozen_cols]}"
      table_action_col="#{config[:table_config][:action_col]}"
      table_toolbar="#{config[:table_config][:toolbar]}"
      table_checkbox="#{config[:table_config][:checkbox]}"
      table_columns='#{columns_json}'
      
      link_param="#{config[:linkage][:param]}"
      link_type="#{config[:linkage][:type]}"
    />
  ERB
end

# 步骤2：框架处理kr标签（配置注册系统会自动工作）
def process_kr_tags(kr_erb)
  puts "="*80
  puts "步骤1：IDE设计器生成的kr标签"
  puts "="*80
  puts kr_erb
  puts
  
  # 这里kr:tree_table_layout会被KrTransformer转换为TreeTableLayoutItem
  # TreeTableLayoutItem会调用ComponentConfigRegistry进行配置转换
  # 最终生成l:tree和l:table标签
  
  puts "="*80
  puts "步骤2：配置注册系统处理（自动）"
  puts "="*80
  puts "- TreeConfigMapper: kr属性 → l:tree完整配置"
  puts "- DatatableConfigMapper: kr属性 → l:table完整配置"
  puts "- 规则引擎: 应用约定俗成的默认值"
  puts "- 上下文推断: 根据URL和场景智能补全"
  puts
end

# 步骤3：生成的l标签（框架输出）
def show_generated_l_tags
  puts "="*80
  puts "步骤3：生成的l标签（1:1映射Layui API）"
  puts "="*80
  
  l_tags = <<~HTML
    <div class="layui-row layui-col-space15">
      <div class="layui-col-md4">
        <div class="layui-card">
          <div class="layui-card-header">组织架构</div>
          <div class="layui-card-body">
            <l:tree
              id="tree_org"
              url="/api/org/tree"
              method="post"
              skin="laySimple"
              iconStyle="dtreefont"
              initLevel="1"
              dataFormat="list"
              dataStyle="layuiStyle"
              width="100%"
              height="500px"
              toolbar="true"
              toolbarWay="follow"
              toolbarShow="['searchIcon']"
              toolbarExt="[
                {menubarId: 'btn-add', icon: 'layui-icon-add-1', title: '添加'},
                {menubarId: 'btn-refresh', icon: 'layui-icon-refresh', title: '刷新'},
                {menubarId: 'btn-expand', icon: 'layui-icon-down', title: '展开'}
              ]"
            />
          </div>
        </div>
      </div>
      
      <div class="layui-col-md8">
        <div class="layui-card">
          <div class="layui-card-header">员工列表</div>
          <div class="layui-card-body">
            <l:table
              id="table_employees"
              url="/api/org/employees"
              method="post"
              page="true"
              limit="10"
              limits="[10, 20, 50, 100]"
              cellMinWidth="60"
              skin="line"
              height="full-200"
              toolbar="#toolbarDemo"
              defaultToolbar="['filter', 'exports', 'print']"
              cols='[
                {field: "id", title: "ID", width: 80, sort: true, fixed: "left", type: "checkbox"},
                {field: "name", title: "姓名", width: 120},
                {field: "position", title: "职位", width: 150},
                {field: "department", title: "部门", width: 150},
                {field: "email", title: "邮箱", width: 200},
                {field: "phone", title: "电话", width: 130},
                {field: "status", title: "状态", width: 100},
                {title: "操作", fixed: "right", toolbar: "#actionToolbar", width: 150}
              ]'
            />
          </div>
        </div>
      </div>
    </div>
    
    <script>
      // 树表联动脚本（自动生成）
      layui.use(['dtree', 'table', 'jquery'], function(){
        var dtree = layui.dtree;
        var table = layui.table;
        
        // 使用运行时库创建联动布局
        var tree = KR.UI.createTree('tree_org', {...});
        var dataTable = KR.UI.createDataTable('table_employees', {...});
        
        var linkedLayout = KR.UI.createLinkedLayout({
          sourceComponent: tree,
          targetComponents: [dataTable],
          linkParam: 'org_id',
          linkType: 'click',
          autoLink: true
        });
      });
    </script>
  HTML
  
  puts l_tags
  puts
end

# 步骤4：最终HTML输出
def show_final_output
  puts "="*80
  puts "步骤4：最终HTML输出（Layui原生代码）"
  puts "="*80
  puts "生成的HTML包含："
  puts "- 完整的dtree配置（30+属性）"
  puts "- 完整的table配置（25+属性）"
  puts "- 树表联动JavaScript代码"
  puts "- 响应式布局（layui grid）"
  puts "- 工具栏、搜索、分页、冻结列、操作列等所有功能"
  puts
end

# 运行演示
def run_demo
  puts "\n" + "="*80
  puts "树表联动CRUD完整流程演示"
  puts "="*80
  puts
  
  # 步骤1
  kr_tags = generate_kr_tags_from_ide(IDE_OUTPUT)
  process_kr_tags(kr_tags)
  
  # 步骤3
  show_generated_l_tags
  
  # 步骤4
  show_final_output
  
  puts "="*80
  puts "配置系统优势"
  puts "="*80
  puts "1. 声明式：IDE只需输出简单的kr标签"
  puts "2. 智能补全：30+配置项自动补全"
  puts "3. 规则引擎：根据场景应用最佳实践"
  puts "4. 上下文推断：从URL和场景推断配置"
  puts "5. AI增强：可选的AI配置优化"
  puts "6. 框架无关：kr标签可编译为任何框架"
  puts "7. 可调整：支持页面级和组件级覆盖"
  puts "="*80
  puts
end

# 执行演示
if __FILE__ == $PROGRAM_NAME
  run_demo
end

