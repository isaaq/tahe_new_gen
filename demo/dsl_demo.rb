# DSL 使用示例
# 展示如何使用页面级 DSL 生成完整的业务页面
require_relative '../_system'
require_relative '../lib/util/common'
require_relative '../lib/ui/ui_impl/kr_page_dsl_generator'
require_relative '../lib/ui/ui_impl/kr_business_aggregator'
require 'ostruct'

class DslDemo
  def self.run
    puts "=== KR 页面级 DSL 生成器示例 ==="
    
    # 1. 从 DSL 文件生成页面
    dsl_content = File.read('demo/product_management.krdsl')
    result = KrPageDslGenerator.generate_from_dsl(dsl_content)
    
    puts "\n1. 生成的 HTML 结构:"
    puts result[:html]
    
    puts "\n2. 生成的 JavaScript 代码:"
    puts result[:script]
    
    # 2. 从配置对象生成页面
    config = {
      page: {
        title: "用户管理",
        layout: "admin",
        theme: "default"
      },
      components: [
        {
          type: "search_table",
          config: {
            table_title: "用户列表",
            table_source: "/api/users",
            search_fields: [
              {
                type: "input",
                name: "username",
                label: "用户名",
                placeholder: "请输入用户名"
              },
              {
                type: "select",
                name: "status",
                label: "状态",
                options: [
                  {value: "active", text: "激活"},
                  {value: "inactive", text: "禁用"}
                ]
              }
            ],
            columns: [
              {field: "id", title: "ID", width: 80},
              {field: "username", title: "用户名", width: 150},
              {field: "email", title: "邮箱", width: 200},
              {field: "status", title: "状态", width: 100}
            ]
          }
        }
      ]
    }
    
    result2 = KrPageDslGenerator.generate_from_config(config)
    
    puts "\n3. 从配置生成的完整页面:"
    puts result2[:full_page]
    
    # 3. 展示业务聚合标签的使用
    puts "\n4. 业务聚合标签示例:"
    demo_business_aggregation
  end
  
  def self.demo_business_aggregation
    # 模拟 kr:tree_table_layout 标签
    tree_table_tag = OpenStruct.new(
      name: 'tree_table_layout',
      attributes: {
        'tree_source' => '/api/categories',
        'table_source' => '/api/products'
      }
    )
    
    children = [
      '<kr:tree source="/api/categories" />',
      '<kr:table source="/api/products" />'
    ]
    
    result = KrBusinessAggregator.process(tree_table_tag, {}, children)
    puts result
    
    # 模拟 kr:search_table 标签
    search_table_tag = OpenStruct.new(
      name: 'search_table',
      attributes: {
        'table_source' => '/api/search'
      }
    )
    
    search_children = [
      '<kr:search_form>',
      '  <kr:input name="keyword" />',
      '  <kr:select name="category" />',
      '</kr:search_form>',
      '<kr:table source="/api/products" />'
    ]
    
    result2 = KrBusinessAggregator.process(search_table_tag, {}, search_children)
    puts "\n搜索表格聚合结果:"
    puts result2
  end
end

# 运行示例
DslDemo.run if __FILE__ == $0
