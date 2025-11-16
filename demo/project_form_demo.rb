#!/usr/bin/env ruby
# 立项信息登记表单演示
# 展示如何解析和执行网格布局DSL

require_relative '../_system'
require_relative '../lib/util/common'
require_relative '../lib/ui/ui_impl/kr_grid_dsl'
require_relative '../lib/ui/ui_impl/kr_grid_layout'
require_relative '../lib/ui/ui_impl/kr_transformer'

class ProjectFormDemo
  def self.run
    new.run
  end
  
  def run
    # 1. 解析DSL文件
    dsl_file = File.join(__dir__, 'project_registration_form.krdsl')
    puts "解析DSL文件: #{dsl_file}"
    dsl_content = File.read(dsl_file)
    grid_config = KrGridDsl.parse(dsl_content)
    
    # 2. 处理内容中的KR标签
    puts "处理KR标签..."
    process_kr_tags(grid_config)
    
    # 3. 生成网格布局
    puts "生成网格布局..."
    result = KrGridLayout.generate(grid_config)
    
    # 4. 组装完整页面
    puts "组装完整页面..."
    page = generate_complete_page(grid_config, result)
    
    # 5. 保存生成的页面
    output_file = File.join(__dir__, 'project_registration_form.html')
    File.write(output_file, page)
    puts "页面已生成: #{output_file}"
    
    # 6. 打开生成的页面
    puts "正在打开生成的页面..."
    system("open #{output_file}")
  end
  
  private
  
  def process_kr_tags(grid_config)
    grid_config[:items].each do |item|
      puts "处理网格项: #{item[:id]}"
      puts "原始内容: #{item[:content].inspect}"
      
      # 这里应该使用KrTransformer处理KR标签
      # 由于我们可能没有完整的KrTransformer实现，这里做一个简单的模拟
      transformed_content = mock_transform_kr_tags(item[:content])
      puts "转换后内容: #{transformed_content.inspect}"
      
      item[:content] = transformed_content
    end
  end
  
  def mock_transform_kr_tags(content)
    # 简单模拟KR标签转换为HTML
    # 在实际项目中，应该使用KrTransformer
    
    # 处理工具栏
    content = content.gsub(/<kr:toolbar>(.*?)<\/kr:toolbar>/m) do |match|
      toolbar_content = $1
      "<div class='layui-btn-container'>#{toolbar_content}</div>"
    end
    
    # 处理按钮
    content = content.gsub(/<kr:button\s+text="([^"]+)"(?:\s+icon="([^"]+)")?(?:\s+theme="([^"]+)")?[^>]*\/>/) do |match|
      text = $1
      icon = $2 ? "layui-icon-#{$2}" : ""
      theme = $3 ? "layui-btn-#{$3}" : ""
      "<button class='layui-btn #{theme}'><i class='layui-icon #{icon}'></i> #{text}</button>"
    end
    
    # 处理页面标题
    content = content.gsub(/<kr:page_title\s+title="([^"]+)"[^>]*\/>/) do |match|
      title = $1
      "<h2 class='layui-title'>#{title}</h2>"
    end
    
    # 处理选项卡
    content = content.gsub(/<kr:tabs>(.*?)<\/kr:tabs>/m) do |match|
      tabs_content = $1
      "<div class='layui-tab layui-tab-brief'><ul class='layui-tab-title'>#{tabs_content}</ul></div>"
    end
    
    # 处理选项卡项
    content = content.gsub(/<kr:tab\s+title="([^"]+)"(?:\s+active="([^"]+)")?[^>]*\/>/) do |match|
      title = $1
      active = $2 == "true" ? "layui-this" : ""
      "<li class='#{active}'>#{title}</li>"
    end
    
    # 处理区域
    content = content.gsub(/<kr:section\s+title="([^"]+)"[^>]*\/>/) do |match|
      title = $1
      "<fieldset class='layui-elem-field layui-field-title'><legend>#{title}</legend></fieldset>"
    end
    
    # 处理表单行
    content = content.gsub(/<kr:form_row>(.*?)<\/kr:form_row>/m) do |match|
      row_content = $1
      "<div class='layui-form-item'>#{row_content}</div>"
    end
    
    # 处理表单字段
    content = content.gsub(/<kr:form_field\s+name="([^"]+)"(?:\s+label="([^"]+)")?(?:\s+type="([^"]+)")?(?:\s+required="([^"]+)")?(?:\s+value="([^"]+)")?(?:\s+placeholder="([^"]+)")?(?:\s+width="([^"]+)")?[^>]*\/>/) do |match|
      name = $1
      label = $2 || name
      type = $3 || "text"
      required = $4 == "true" ? "required lay-verify='required'" : ""
      value = $5 ? "value='#{$5}'" : ""
      placeholder = $6 ? "placeholder='#{$6}'" : ""
      width = $7 ? "style='width: #{$7};'" : ""
      
      input_html = case type
      when "textarea"
        "<textarea name='#{name}' class='layui-textarea' #{required} #{placeholder}></textarea>"
      when "select"
        "<select name='#{name}' #{required}><option value=''>请选择</option></select>"
      when "date"
        "<input type='text' name='#{name}' class='layui-input' id='#{name}' #{required} #{value} #{placeholder}>"
      else
        "<input type='#{type}' name='#{name}' class='layui-input' #{required} #{value} #{placeholder}>"
      end
      
      "<div class='layui-inline' #{width}><label class='layui-form-label'>#{label}</label><div class='layui-input-inline'>#{input_html}</div></div>"
    end
    
    # 处理文件上传
    content = content.gsub(/<kr:file_upload\s+id="([^"]+)"(?:\s+multiple="([^"]+)")?[^>]*\/>/) do |match|
      id = $1
      multiple = $2 == "true" ? "multiple" : ""
      "<button type='button' class='layui-btn' id='#{id}'><i class='layui-icon'>&#xe67c;</i>上传文件</button>"
    end
    
    # 处理文件列表
    content = content.gsub(/<kr:file_list>(.*?)<\/kr:file_list>/m) do |match|
      columns = $1
      "<table class='layui-table'><thead><tr>#{columns}</tr></thead><tbody></tbody></table>"
    end
    
    # 处理表格列
    content = content.gsub(/<kr:table_column\s+field="([^"]+)"\s+title="([^"]+)"[^>]*\/>/) do |match|
      field = $1
      title = $2
      "<th>#{title}</th>"
    end
    
    content
  end
  
  def generate_complete_page(grid_config, result)
    <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>#{grid_config[:title] || '立项信息登记'}</title>
      
      <!-- 引入Layui -->
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/layui@2.6.8/dist/css/layui.min.css">
      <script src="https://cdn.jsdelivr.net/npm/layui@2.6.8/dist/layui.min.js"></script>
      
      <!-- 引入GridStack -->
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/gridstack@4.2.5/dist/gridstack.min.css">
      <script src="https://cdn.jsdelivr.net/npm/gridstack@4.2.5/dist/gridstack-all.js"></script>
      
      <!-- 添加样式 -->
      <style>
        body {
          padding: 20px;
          background-color: #f2f2f2;
        }
        .container {
          max-width: 1200px;
          margin: 0 auto;
          background-color: #fff;
          padding: 20px;
          box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .layui-form-label {
          width: 110px;
        }
        .layui-input-inline {
          width: 190px;
        }
        .layui-btn-container {
          margin-bottom: 10px;
        }
        .layui-title {
          text-align: center;
          font-size: 24px;
          margin: 20px 0;
        }
        .layui-tab {
          margin-top: 20px;
        }
        .required:before {
          content: "* ";
          color: red;
        }
        #{result[:css]}
      </style>
    </head>
    <body>
      <div class="container layui-form">
        #{result[:html]}
      </div>
      
      <!-- 添加脚本 -->
      <script>
        layui.use(['form', 'laydate', 'upload', 'table'], function(){
          var form = layui.form;
          var laydate = layui.laydate;
          var upload = layui.upload;
          var table = layui.table;
          
          // 初始化日期选择器
          laydate.render({
            elem: '#date'
          });
          laydate.render({
            elem: '#plan_start_date'
          });
          laydate.render({
            elem: '#plan_end_date'
          });
          
          // 初始化上传组件
          upload.render({
            elem: '#attachments',
            url: '/upload/',
            multiple: true,
            done: function(res){
              console.log(res);
            }
          });
          
          // 表单提交
          form.on('submit(formSubmit)', function(data){
            console.log(data.field);
            return false;
          });
        });
        
        #{result[:js]}
        
        // 设计器模式切换
        function toggleDesignMode() {
          if (typeof toggleGridDesignerMode === 'function') {
            toggleGridDesignerMode(true);
          }
        }
      </script>
    </body>
    </html>
    HTML
  end
end

# 运行演示
if __FILE__ == $0
  ProjectFormDemo.run
end
