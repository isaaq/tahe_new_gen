# frozen_string_literal: true

# kr:col 列级FK和枚举功能演示

require_relative '../_system'
require_relative '../lib/ui/_config'

def demo_kr_column_features
  puts "\n" + "="*80
  puts "kr:col 列级FK和枚举功能演示"
  puts "="*80
  puts
  
  # ========== 演示1: 基本FK列声明 ==========
  puts "演示1: 基本FK列声明"
  puts "-" * 40
  
  erb_basic_fk = <<~ERB
    <kr:datatable id="order_table" source="b_orders" page="true">
      <kr:col title="订单ID" field="id" width="80" />
      
      <!-- FK列：语义化关联声明 -->
      <kr:col 
        title="套餐名" 
        field="package_id"
        relation="package"
        relation_field="name" />
      
      <kr:col title="金额" field="amount" width="100" />
    </kr:datatable>
  ERB
  
  puts "输入ERB:"
  puts erb_basic_fk
  puts
  
  # ========== 演示2: 多个FK列 ==========
  puts "演示2: 多个FK列（参考老系统）"
  puts "-" * 40
  
  erb_multiple_fk = <<~ERB
    <kr:datatable id="order_table" source="b_orders" page="true">
      <kr:col title="订单ID" field="id" width="80" />
      
      <!-- FK列1: 套餐 -->
      <kr:col 
        title="原套餐" 
        field="customer__meal_id_original"
        relation="package"
        relation_field="package_name"
        relation_key="customer__meal_id_original" />
      
      <!-- FK列2: 渠道 -->
      <kr:col 
        title="渠道名" 
        field="order__code"
        relation="channel"
        relation_field="name"
        relation_key="order__code" />
      
      <kr:col title="金额" field="amount" width="100" />
    </kr:datatable>
  ERB
  
  puts "输入ERB:"
  puts erb_multiple_fk
  puts
  
  # ========== 演示3: 枚举列 ==========
  puts "演示3: 枚举列声明"
  puts "-" * 40
  
  erb_enum = <<~ERB
    <kr:datatable id="order_table" source="b_orders" page="true">
      <kr:col title="订单ID" field="id" width="80" />
      
      <!-- 枚举列 -->
      <kr:col 
        title="订单状态" 
        field="order__status" 
        type="enum"
        enum="待支付,已支付,已完成,退款中,已退款,已取消,已核销" />
      
      <kr:col title="金额" field="amount" width="100" />
    </kr:datatable>
  ERB
  
  puts "输入ERB:"
  puts erb_enum
  puts
  
  # ========== 演示4: FK + 枚举组合 ==========
  puts "演示4: FK + 枚举组合（完整示例）"
  puts "-" * 40
  
  erb_combined = <<~ERB
    <kr:datatable id="order_table" source="b_orders" page="true" limit="20">
      <kr:col title="订单ID" field="id" width="80" sort="true" />
      
      <!-- FK列：套餐 -->
      <kr:col 
        title="原套餐" 
        field="customer__meal_id_original"
        relation="package"
        relation_field="package_name"
        relation_key="customer__meal_id_original"
        width="150" />
      
      <!-- FK列：渠道 -->
      <kr:col 
        title="渠道名" 
        field="order__code"
        relation="channel"
        relation_field="name"
        relation_key="order__code"
        width="120" />
      
      <!-- 枚举列：状态 -->
      <kr:col 
        title="订单状态" 
        field="order__status" 
        type="enum"
        enum="待支付,已支付,已完成,退款中,已退款,已取消,已核销"
        width="100" />
      
      <kr:col title="金额" field="amount" width="100" sort="true" />
      <kr:col title="创建时间" field="created_at" width="150" sort="true" />
    </kr:datatable>
  ERB
  
  puts "输入ERB:"
  puts erb_combined
  puts
  
  # ========== 演示5: 解析并查看生成的查询协议 ==========
  puts "演示5: 解析ERB并查看生成的结果"
  puts "-" * 40
  
  begin
    # 使用UIPage解析
    page = UIPage.new(:kr)
    
    # 注意：这里只能演示解析过程，实际渲染需要完整的环境
    puts "✅ UIPage已创建"
    puts "   解析引擎: kr"
    puts
    
    # 演示RelationRegistry的自动发现
    puts "演示6: RelationRegistry 自动发现功能"
    puts "-" * 40
    
    if defined?(RelationRegistry)
      puts "✅ RelationRegistry 已加载"
      
      # 测试自动发现
      test_relations = [
        { name: 'package', key: 'package_id', source: 'b_orders' },
        { name: 'department', key: 'department_id', source: 'org_employees' },
        { name: 'channel', key: 'channel_id', source: 'b_orders' }
      ]
      
      test_relations.each do |rel|
        config = RelationRegistry.resolve(
          rel[:name],
          rel[:key],
          rel[:source]
        )
        
        puts "   关联: #{rel[:name]}"
        puts "     目标集合: #{config[:collection]}"
        puts "     外键: #{config[:foreign_key]}"
        puts "     来源: #{config[:source]}"
        puts
      end
    else
      puts "⚠️  RelationRegistry 未加载"
    end
    
  rescue => e
    puts "❌ 解析失败: #{e.message}"
    puts e.backtrace.first(3).join("\n")
  end
  
  # ========== 演示7: 查询协议示例 ==========
  puts "演示7: 生成的查询协议示例"
  puts "-" * 40
  
  sample_protocol = {
    "collection" => "b_orders",
    "filter" => {},
    "expand" => [
      {
        "relation" => "package",
        "collection" => "b_packages",
        "foreign_key" => "customer__meal_id_original",
        "display_field" => "package_name",
        "result_field" => "package_package_name"
      },
      {
        "relation" => "channel",
        "collection" => "b_channel_names",
        "foreign_key" => "order__code",
        "display_field" => "name",
        "result_field" => "channel_name"
      }
    ],
    "sort" => { "created_at" => -1 },
    "page" => 1,
    "limit" => 20
  }
  
  puts "查询协议 JSON:"
  puts JSON.pretty_generate(sample_protocol)
  puts
  
  # ========== 演示8: 前后端通信流程说明 ==========
  puts "演示8: 前后端通信流程"
  puts "-" * 40
  puts <<~FLOW
    1. 用户写 kr:col 标签（声明关联）
       ↓
    2. TableColItem.pre_process 解析关联配置
       ↓
    3. RelationRegistry.resolve 自动发现目标集合
       ↓
    4. TableItem.build_query_protocol 生成查询协议
       ↓
    5. 前端 Layui 发送 POST /api/query（携带协议）
       ↓
    6. 后端 MongoQueryEngine.execute 处理：
       - 查询主集合（b_orders）
       - 批量查询关联集合（b_packages, b_channel_names）
       - 内存合并数据
       ↓
    7. FormatterRegistry.apply_formatters 应用自定义格式化
       ↓
    8. 返回合并后的数据给前端
       ↓
    9. Layui 渲染表格
  FLOW
  
  puts
  puts "🎉 kr:col 列级FK和枚举功能演示完成！"
  puts
  puts "核心特性:"
  puts "  ✅ 列级FK声明（语义化）"
  puts "  ✅ 列级枚举声明（简单）"
  puts "  ✅ 自动集合发现（零配置）"
  puts "  ✅ MongoDB元数据缓存（持久化）"
  puts "  ✅ 通用查询引擎（零业务代码）"
  puts "  ✅ 完全透明的前后端通信"
  puts
end

# 运行演示
if __FILE__ == $PROGRAM_NAME
  demo_kr_column_features
end




