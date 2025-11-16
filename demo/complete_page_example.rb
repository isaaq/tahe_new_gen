# frozen_string_literal: true

# 完整页面示例 - 基于内置模板的用户管理页面
# 演示从模板到完整页面的全流程

require_relative '../_system'
require_relative '../lib/ui/_config'

def demo_complete_page
  puts "\n" + "="*80
  puts "完整页面示例：基于模板的用户管理系统"
  puts "="*80
  puts
  
  # ========== Step 1: 使用内置模板生成kr标签 ==========
  puts "Step 1: 使用内置模板生成 kr 标签"
  puts "-" * 40
  
  # 自定义配置
  customizations = {
    'tree_config' => {
      'title' => '组织架构',
      'data_source' => {
        'url' => '/api/org/tree'
      }
    },
    'table_config' => {
      'title' => '员工列表',
      'data_source' => {
        'url' => '/api/org/employees'
      },
      'pagination' => {
        'default_limit' => 15
      }
    }
  }
  
  kr_tags = TemplateManager.instantiate('user_management', customizations)
  puts "生成的 kr 标签:"
  puts kr_tags
  puts
  
  # ========== Step 2: 手动创建完整的ERB页面（使用kr:col FK和枚举） ==========
  puts "Step 2: 创建完整的 ERB 页面（使用 kr:col FK 和枚举）"
  puts "-" * 40
  
  complete_erb = <<~ERB
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>员工管理系统</title>
      <link rel="stylesheet" href="/matrix/templates/pear/component/layui/css/layui.css">
      <link rel="stylesheet" href="/matrix/templates/pear/component/pear/css/pear.css">
    </head>
    <body>
      <div class="layui-fluid">
        <div class="layui-card">
          <div class="layui-card-header">
            <h2>员工管理</h2>
          </div>
          <div class="layui-card-body">
            
            <!-- 使用 kr:datatable 和 kr:col -->
            <kr:datatable id="employee_table" source="org_employees" page="true" limit="15">
              
              <!-- 普通列 -->
              <kr:col title="工号" field="employee_id" width="100" sort="true" />
              <kr:col title="姓名" field="name" width="120" sort="true" />
              
              <!-- FK列1: 所属部门（使用 relation） -->
              <kr:col 
                title="所属部门" 
                field="department_id"
                relation="department"
                relation_field="name"
                relation_key="department_id"
                width="150" />
              
              <!-- FK列2: 职位 -->
              <kr:col 
                title="职位" 
                field="position_id"
                relation="position"
                relation_field="name"
                relation_key="position_id"
                width="120" />
              
              <!-- 普通列 -->
              <kr:col title="邮箱" field="email" width="180" />
              <kr:col title="手机号" field="phone" width="120" />
              
              <!-- 枚举列1: 性别 -->
              <kr:col 
                title="性别" 
                field="gender" 
                type="enum"
                enum="男,女,未知"
                width="80" />
              
              <!-- 枚举列2: 状态 -->
              <kr:col 
                title="状态" 
                field="status" 
                type="enum"
                enum="在职,离职,试用期"
                width="100" />
              
              <kr:col title="入职日期" field="entry_date" width="120" sort="true" />
            </kr:datatable>
            
          </div>
        </div>
      </div>
      
      <script src="/matrix/templates/pear/component/layui/layui.js"></script>
    </body>
    </html>
  ERB
  
  puts "完整 ERB 页面:"
  puts complete_erb
  puts
  
  # ========== Step 3: 生成模拟数据 ==========
  puts "Step 3: 准备模拟数据"
  puts "-" * 40
  
  # 模拟MongoDB数据
  mock_data = {
    org_employees: [
      {
        _id: 'emp_001',
        employee_id: 'E001',
        name: '张三',
        department_id: 'dept_001',
        position_id: 'pos_001',
        email: 'zhangsan@company.com',
        phone: '13800138000',
        gender: 0,  # 男
        status: 0,  # 在职
        entry_date: '2024-01-15'
      },
      {
        _id: 'emp_002',
        employee_id: 'E002',
        name: '李四',
        department_id: 'dept_002',
        position_id: 'pos_002',
        email: 'lisi@company.com',
        phone: '13800138001',
        gender: 1,  # 女
        status: 0,  # 在职
        entry_date: '2024-02-20'
      }
    ],
    org_departments: [
      { _id: 'dept_001', name: '技术部', code: 'TECH' },
      { _id: 'dept_002', name: '市场部', code: 'MARKET' }
    ],
    org_positions: [
      { _id: 'pos_001', name: '高级工程师', code: 'SE_SENIOR' },
      { _id: 'pos_002', name: '市场经理', code: 'MKT_MGR' }
    ]
  }
  
  puts "模拟数据:"
  puts "  员工: #{mock_data[:org_employees].size} 条"
  puts "  部门: #{mock_data[:org_departments].size} 条"
  puts "  职位: #{mock_data[:org_positions].size} 条"
  puts
  
  # ========== Step 4: 模拟查询协议生成 ==========
  puts "Step 4: 生成查询协议（自动）"
  puts "-" * 40
  
  query_protocol = {
    collection: 'org_employees',
    filter: {},
    expand: [
      {
        relation: 'department',
        collection: 'org_departments',
        foreign_key: 'department_id',
        display_field: 'name',
        result_field: 'department_name'
      },
      {
        relation: 'position',
        collection: 'org_positions',
        foreign_key: 'position_id',
        display_field: 'name',
        result_field: 'position_name'
      }
    ],
    sort: { entry_date: -1 },
    page: 1,
    limit: 15
  }
  
  puts "查询协议 JSON:"
  puts JSON.pretty_generate(query_protocol)
  puts
  
  # ========== Step 5: 模拟后端查询处理 ==========
  puts "Step 5: 后端处理（模拟）"
  puts "-" * 40
  
  # 模拟 MongoQueryEngine.execute
  def simulate_query(protocol, mock_data)
    # 1. 查询主集合
    employees = mock_data[:org_employees]
    puts "  1. 查询主集合: org_employees (#{employees.size} 条)"
    
    # 2. 处理关联
    protocol[:expand].each do |expand|
      # 提取外键
      foreign_keys = employees.map { |e| e[expand[:foreign_key].to_sym] }.compact.uniq
      puts "  2. 提取外键 #{expand[:foreign_key]}: #{foreign_keys}"
      
      # 批量查询关联集合
      related_collection = mock_data[expand[:collection].to_sym]
      related_map = related_collection.each_with_object({}) do |item, map|
        map[item[:_id]] = item
      end
      puts "  3. 批量查询 #{expand[:collection]}: #{related_collection.size} 条"
      
      # 合并数据
      employees.each do |emp|
        fk_value = emp[expand[:foreign_key].to_sym]
        related = related_map[fk_value]
        if related
          emp[expand[:result_field].to_sym] = related[expand[:display_field].to_sym]
        end
      end
      puts "  4. 合并数据到主记录"
    end
    
    employees
  end
  
  result_employees = simulate_query(query_protocol, mock_data)
  
  puts "\n合并后的数据:"
  result_employees.each do |emp|
    puts "  #{emp[:employee_id]} - #{emp[:name]} - #{emp[:department_name]} - #{emp[:position_name]}"
  end
  puts
  
  # ========== Step 6: 模拟HTTP请求/响应 ==========
  puts "Step 6: HTTP 请求/响应（模拟）"
  puts "-" * 40
  
  puts "请求:"
  puts "  POST /api/query"
  puts "  Content-Type: application/json"
  puts "  Body: #{query_protocol.to_json[0..100]}..."
  puts
  
  response_data = {
    code: 0,
    msg: 'success',
    data: result_employees,
    count: result_employees.size
  }
  
  puts "响应:"
  puts "  Status: 200 OK"
  puts "  Body:"
  puts JSON.pretty_generate(response_data)[0..500] + "..."
  puts
  
  # ========== Step 7: 演示三种协议模式 ==========
  puts "Step 7: 三种协议模式对比"
  puts "-" * 40
  
  # 完整协议
  full_json = query_protocol.to_json
  puts "完整协议（development）:"
  puts "  体积: #{full_json.bytesize} 字节"
  puts "  可读性: ⭐⭐⭐⭐⭐"
  puts "  内容: #{full_json[0..80]}..."
  puts
  
  # 紧凑协议
  require_relative '../lib/biz/query/compact_protocol'
  compact = CompactProtocol.encode(query_protocol)
  compact_json = compact.to_json
  puts "紧凑协议（staging）:"
  puts "  体积: #{compact_json.bytesize} 字节 (#{(compact_json.bytesize.to_f / full_json.bytesize * 100).round(1)}%)"
  puts "  可读性: ⭐⭐⭐"
  puts "  内容: #{compact_json}"
  puts
  
  # 加密协议
  require_relative '../lib/biz/query/secure_protocol'
  session_key = SecureProtocol.generate_session_key
  encrypted = SecureProtocol.encrypt(compact, session_key)
  encrypted_json = encrypted.to_json
  puts "加密协议（production）:"
  puts "  体积: #{encrypted_json.bytesize} 字节 (#{(encrypted_json.bytesize.to_f / full_json.bytesize * 100).round(1)}%)"
  puts "  可读性: ❌ 完全不可读"
  puts "  内容: #{encrypted_json[0..80]}..."
  puts
  
  # ========== Step 8: 生成完整页面HTML ==========
  puts "Step 8: 生成完整页面 HTML"
  puts "-" * 40
  
  # 使用 UIPage 解析 ERB
  begin
    page = UIPage.new(:kr)
    # 注意：实际解析需要完整的渲染环境，这里只展示流程
    puts "✅ 页面已准备好渲染"
    puts "   使用引擎: kr -> layui"
    puts "   包含功能:"
    puts "     - 2个FK列（部门、职位）"
    puts "     - 2个枚举列（性别、状态）"
    puts "     - 自动生成查询协议"
    puts "     - 根据环境选择协议模式"
    puts
  rescue => e
    puts "⚠️  解析失败: #{e.message}"
  end
  
  # ========== Step 9: 前端代码示例 ==========
  puts "Step 9: 生成的前端代码示例"
  puts "-" * 40
  
  frontend_code = <<~JS
    <script>
    layui.use(['table', 'dtree'], function() {
      var table = layui.table;
      
      // 查询协议（自动生成）
      var queryProtocol = {
        "collection": "org_employees",
        "expand": [
          {
            "relation": "department",
            "collection": "org_departments",
            "foreign_key": "department_id",
            "display_field": "name",
            "result_field": "department_name"
          },
          {
            "relation": "position",
            "collection": "org_positions",
            "foreign_key": "position_id",
            "display_field": "name",
            "result_field": "position_name"
          }
        ],
        "page": 1,
        "limit": 15
      };
      
      // 根据环境选择端点
      var endpoint = '/api/query';  // development/staging
      // var endpoint = '/api/query/secure';  // production
      
      // 渲染表格
      table.render({
        elem: '#employee_table',
        url: endpoint,
        method: 'POST',
        contentType: 'application/json',
        where: queryProtocol,
        
        cols: [[
          {field: 'employee_id', title: '工号', width: 100, sort: true},
          {field: 'name', title: '姓名', width: 120, sort: true},
          {field: 'department_name', title: '部门', width: 150},
          {field: 'position_name', title: '职位', width: 120},
          {field: 'email', title: '邮箱', width: 180},
          {field: 'phone', title: '手机号', width: 120},
          {field: 'gender', title: '性别', width: 80, templet: '#enum_gender'},
          {field: 'status', title: '状态', width: 100, templet: '#enum_status'},
          {field: 'entry_date', title: '入职日期', width: 120, sort: true}
        ]],
        
        page: true,
        limit: 15
      });
    });
    </script>
    
    <!-- 枚举模板：性别 -->
    <script type="text/html" id="enum_gender">
      {{# 
        var enumMap = { 0: '男', 1: '女', 2: '未知' };
        var label = enumMap[d.gender] || '未知';
        var colorMap = ['blue', 'pink', 'gray'];
        var color = colorMap[d.gender] || 'gray';
      }}
      <span class="layui-badge layui-bg-{{ color }}">{{ label }}</span>
    </script>
    
    <!-- 枚举模板：状态 -->
    <script type="text/html" id="enum_status">
      {{# 
        var enumMap = { 0: '在职', 1: '离职', 2: '试用期' };
        var label = enumMap[d.status] || '未知';
        var colorMap = ['green', 'gray', 'orange'];
        var color = colorMap[d.status] || 'gray';
      }}
      <span class="layui-badge layui-bg-{{ color }}">{{ label }}</span>
    </script>
  JS
  
  puts frontend_code
  puts
  
  # ========== Step 10: 后端路由代码（已自动生成） ==========
  puts "Step 10: 后端路由（通用引擎，零业务代码）"
  puts "-" * 40
  
  backend_code = <<~RUBY
    # api/routes/query_routes.rb
    # 这个路由已经自动创建，支持所有表！
    
    post '/api/query' do
      content_type :json
      
      # 解析协议
      protocol = JSON.parse(request.body.read)
      
      # 安全验证
      validate_protocol!(protocol)
      
      # 执行查询（通用引擎）
      result = MongoQueryEngine.execute(protocol)
      
      # 返回结果
      { code: 0, **result }.to_json
    end
    
    # 无需为每个表写单独的路由！
  RUBY
  
  puts backend_code
  puts
  
  # ========== Step 11: 完整工作流总结 ==========
  puts "Step 11: 完整工作流总结"
  puts "-" * 40
  puts <<~FLOW
    1️⃣  开发者写 ERB 模板
       └─> 使用 <kr:datatable> 和 <kr:col>
       └─> 声明 relation="department" （语义化）
       └─> 声明 enum="在职,离职,试用期"
    
    2️⃣  系统第一次编译（kr -> l）
       └─> TableColItem.pre_process 解析 FK 和枚举
       └─> RelationRegistry.resolve 自动发现集合
           ├─> 优先级1: kr:col 显式配置
           ├─> 优先级2: 模型定义（MOrgEmployee）
           └─> 优先级3: 自动发现（命名约定）
       └─> 生成查询协议和模板脚本
    
    3️⃣  系统第二次编译（l -> HTML）
       └─> LayuiTarget 渲染 Layui 组件
       └─> 嵌入查询协议到 JavaScript
       └─> 输出完整 HTML 页面
    
    4️⃣  用户访问页面
       └─> 浏览器加载 HTML
       └─> Layui 初始化表格
       └─> 根据环境选择协议模式：
           ├─> development: 完整协议（透明）
           ├─> staging: 紧凑协议（高效）
           └─> production: 加密协议（安全）
    
    5️⃣  前端发送查询请求
       └─> POST /api/query （或 /api/query/secure）
       └─> 携带查询协议（自动生成）
    
    6️⃣  后端通用引擎处理
       └─> MongoQueryEngine.execute
           ├─> 查询主集合（org_employees）
           ├─> 批量查询关联（org_departments, org_positions）
           └─> 内存合并数据
       └─> FormatterRegistry.apply_formatters（可选）
       └─> 返回合并后的数据
    
    7️⃣  前端渲染表格
       └─> Layui 接收数据
       └─> 应用枚举模板（性别、状态）
       └─> 显示关联数据（部门名、职位名）
       └─> 用户看到完整表格 ✨
  FLOW
  
  puts
  puts "🎉 完整页面示例演示完成！"
  puts
  puts "核心价值:"
  puts "  ✅ 开发者只需写声明式的 kr:col"
  puts "  ✅ 系统自动发现关联关系"
  puts "  ✅ 后端零业务代码（通用引擎）"
  puts "  ✅ 前端自动生成查询逻辑"
  puts "  ✅ 根据环境自动选择协议"
  puts "  ✅ 生产环境自动加密通信"
  puts
end

# 运行演示
if __FILE__ == $PROGRAM_NAME
  demo_complete_page
end




