#!/usr/bin/env ruby
# 布局与内容分离演示
# 展示如何解析和执行分离的布局和内容文件

require_relative '../_system'
require_relative '../lib/util/common'
require_relative '../lib/ui/ui_impl/kr_layout_parser'
require_relative '../lib/ui/ui_impl/kr_content_parser'
require_relative '../lib/ui/ui_impl/kr_merged_layout_generator'

class SeparatedLayoutDemo
  def self.run
    new.run
  end
  
  def run
    # 1. 解析布局文件
    layout_file = File.join(__dir__, 'project_registration_layout.json')
    puts "解析布局文件: #{layout_file}"
    layout_config = KrLayoutParser.parse_file(layout_file)
    puts "布局配置: #{layout_config.inspect}"
    
    # 2. 解析内容文件
    content_file = File.join(__dir__, 'project_registration_content.xml')
    puts "解析内容文件: #{content_file}"
    content_map = KrContentParser.parse_file(content_file)
    puts "内容映射: #{content_map.keys.inspect}"
    
    # 3. 合并布局和内容，生成页面
    puts "合并布局和内容，生成页面..."
    result = KrMergedLayoutGenerator.generate(layout_config, content_map)
    
    # 4. 保存生成的页面
    output_file = File.join(__dir__, 'project_registration_separated.html')
    page = generate_complete_page(result)
    File.write(output_file, page)
    puts "页面已生成: #{output_file}"
    
    # 5. 打开生成的页面
    puts "正在打开生成的页面..."
    system("open #{output_file}")
  end
  
  private
  
  def generate_complete_page(result)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <title>立项信息登记表单 - 布局与内容分离版</title>
        <link rel="stylesheet" href="https://www.layuicdn.com/layui-v2.5.6/css/layui.css">
        <style>
          #{result[:css]}
          
          /* 自定义样式 */
          body {
            padding: 20px;
            background-color: #f2f2f2;
          }
          
          .container {
            width: 100%;
            background-color: #fff;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
          }
          
          .layui-form-label {
            width: 120px;
          }
          
          .layui-input-inline {
            width: 220px;
          }
          
          .layui-elem-field legend {
            font-size: 16px;
            font-weight: bold;
          }
          
          .design-mode {
            border: 1px dashed #f00 !important;
          }
          
          .design-mode:hover {
            background-color: rgba(255, 0, 0, 0.05);
          }
        </style>
      </head>
      <body>
        <div class="layui-fluid">
          <div class="layui-row">
            <div class="layui-col-md12">
              <div class="container">
                <div class="layui-form" lay-filter="project-form">
                  #{result[:html]}
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <script src="https://www.layuicdn.com/layui-v2.5.6/layui.js"></script>
        <script>
          #{result[:js]}
          
          // Layui模块初始化
          layui.use(['form', 'laydate', 'upload'], function(){
            var form = layui.form;
            var laydate = layui.laydate;
            var upload = layui.upload;
            
            // 日期选择器
            laydate.render({
              elem: '#date'
            });
            
            laydate.render({
              elem: '#start_date'
            });
            
            laydate.render({
              elem: '#end_date'
            });
            
            laydate.render({
              elem: '#application_date'
            });
            
            // 文件上传
            upload.render({
              elem: '#upload-files',
              url: '',
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
        </script>
      </body>
      </html>
    HTML
  end
end

# 运行演示
if __FILE__ == $0
  SeparatedLayoutDemo.run
end
