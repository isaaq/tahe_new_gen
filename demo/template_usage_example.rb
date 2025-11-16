# frozen_string_literal: true

# 内置模板使用示例
# 演示如何在实际项目中使用内置模板

require_relative '../_system'
require_relative '../lib/ui/_config'

def demo_template_usage
  puts "\n" + "="*80
  puts "内置模板实际使用示例"
  puts "="*80
  puts
  
  # 示例1: 基本使用 - 生成用户管理页面
  puts "示例1: 生成用户管理页面"
  puts "-" * 40
  
  # 直接使用模板生成kr标签
  user_mgmt_kr = TemplateManager.instantiate('user_management')
  puts "生成的kr标签:"
  puts user_mgmt_kr
  puts
  
  # 示例2: 自定义配置 - 修改为产品管理
  puts "示例2: 自定义配置 - 产品管理页面"
  puts "-" * 40
  
  product_customizations = {
    'tree_config' => {
      'title' => '产品分类',
      'data_source' => {
        'url' => '/api/product_categories'
      }
    },
    'table_config' => {
      'title' => '产品列表',
      'data_source' => {
        'url' => '/api/products'
      },
      'pagination' => {
        'default_limit' => 25
      }
    },
    'linkage' => {
      'param' => 'category_id'
    }
  }
  
  product_mgmt_kr = TemplateManager.instantiate('user_management', product_customizations)
  puts "自定义产品管理kr标签:"
  puts product_mgmt_kr
  puts
  
  # 示例3: 在ERB中使用模板
  puts "示例3: 在ERB模板中使用"
  puts "-" * 40
  
  erb_example = <<~ERB
    <!DOCTYPE html>
    <html>
    <head>
      <title>管理系统</title>
      <link rel="stylesheet" href="/layui/css/layui.css">
    </head>
    <body>
      <div class="layui-container">
        <h1>用户管理</h1>
        
        <!-- 使用内置模板生成页面内容 -->
        <%= #{user_mgmt_kr.inspect} %>
        
        <!-- 或者使用自定义配置 -->
        <%
          custom_config = {
            'tree_config' => {
              'title' => '我的组织架构',
              'data_source' => { 'url' => '/api/my_org' }
            }
          }
          custom_kr = TemplateManager.instantiate('user_management', custom_config)
        %>
        <%= custom_kr %>
      </div>
      
      <script src="/layui/layui.js"></script>
    </body>
    </html>
  ERB
  
  puts "ERB模板示例:"
  puts erb_example
  puts
  
  # 示例4: 动态模板选择
  puts "示例4: 动态模板选择"
  puts "-" * 40
  
  # 根据用户权限或配置动态选择模板
  def generate_page_for_user(user_type)
    case user_type
    when 'admin'
      # 管理员使用完整功能模板
      TemplateManager.instantiate('user_management', {
        'table_config' => {
          'features' => {
            'export' => true,
            'import' => true,
            'action_col' => true
          }
        }
      })
    when 'manager'
      # 经理使用只读模板
      TemplateManager.instantiate('user_management', {
        'table_config' => {
          'features' => {
            'export' => false,
            'import' => false,
            'action_col' => false
          }
        }
      })
    when 'viewer'
      # 查看者使用简化模板
      TemplateManager.instantiate('user_management', {
        'table_config' => {
          'features' => {
            'export' => false,
            'import' => false,
            'action_col' => false,
            'checkbox' => false
          }
        }
      })
    end
  end
  
  # 测试不同用户类型
  ['admin', 'manager', 'viewer'].each do |user_type|
    page_kr = generate_page_for_user(user_type)
    puts "#{user_type.capitalize}用户页面:"
    puts page_kr
    puts
  end
  
  # 示例5: 模板配置验证
  puts "示例5: 模板配置验证"
  puts "-" * 40
  
  # 验证模板是否存在
  if TemplateManager.template_exists?('user_management')
    puts "✅ 用户管理模板存在"
  else
    puts "❌ 用户管理模板不存在"
  end
  
  # 列出所有可用模板
  templates = TemplateManager.list_templates
  puts "📋 可用模板列表:"
  templates.each do |template|
    puts "   - #{template[:name]} (#{template[:id]}) - #{template[:description]}"
  end
  puts
  
  # 示例6: 错误处理
  puts "示例6: 错误处理"
  puts "-" * 40
  
  begin
    # 尝试使用不存在的模板
    TemplateManager.instantiate('non_existent_template')
  rescue => e
    puts "✅ 正确处理了不存在的模板错误: #{e.message}"
  end
  
  begin
    # 尝试使用无效的自定义配置
    TemplateManager.instantiate('user_management', {
      'invalid_config' => 'invalid_value'
    })
  rescue => e
    puts "✅ 正确处理了无效配置错误: #{e.message}"
  rescue
    puts "✅ 系统正常运行，未抛出异常"
  end
  
  puts "\n🎉 内置模板使用示例演示完成！"
  puts "   现在您可以在实际项目中集成这些模板了。"
  puts
end

# 运行示例
if __FILE__ == $PROGRAM_NAME
  demo_template_usage
end

