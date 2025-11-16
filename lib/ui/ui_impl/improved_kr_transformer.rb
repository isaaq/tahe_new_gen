# 改进的KR标签转换器
# 专门用于处理分离式布局中的KR标签转换问题

class ImprovedKrTransformer
  
  def self.transform(content)
    transformer = new
    transformer.transform(content)
  end
  
  def initialize
    @iteration_count = 0
    @max_iterations = 10
  end
  
  def transform(content)
    original_content = content
    
    puts "=== KR标签转换开始 ==="
    puts "原始内容长度: #{content.length}"
    puts "原始内容预览: #{content[0..200]}..."
    
    # 持续转换直到没有更多KR标签或达到最大迭代次数
    while @iteration_count < @max_iterations
      @iteration_count += 1
      
      puts "\n--- 第#{@iteration_count}轮转换 ---"
      
      # 执行一轮转换
      transformed_content = transform_once(content)
      
      puts "转换后内容长度: #{transformed_content.length}"
      
      # 如果内容没有变化，说明转换完成
      if transformed_content == content
        puts "内容无变化，转换完成"
        break
      end
      
      content = transformed_content
    end
    
    puts "\n=== KR标签转换完成 ==="
    puts "最终内容长度: #{content.length}"
    puts "迭代次数: #{@iteration_count}"
    puts "最终内容预览: #{content[0..300]}..."
    
    content
  end
  
  private
  
  def transform_once(content)
    # 处理工具栏
    content = transform_toolbar(content)
    
    # 处理页面标题
    content = transform_page_title(content)
    
    # 处理选项卡
    content = transform_tabs(content)
    
    # 处理区域标题
    content = transform_section(content)
    
    # 处理表单行
    content = transform_form_row(content)
    
    # 处理表单字段（最复杂的部分）
    content = transform_form_fields(content)
    
    # 处理选项
    content = transform_options(content)
    
    # 处理附件列表
    content = transform_attachment_list(content)
    
    content
  end
  
  def transform_toolbar(content)
    content.gsub(/<kr:toolbar[^>]*>(.*?)<\/kr:toolbar>/m) do |match|
      toolbar_content = $1
      buttons = toolbar_content.scan(/<kr:button\s+text="([^"]+)"[^>]*\/>/).map do |text|
        "<button type='button' class='layui-btn layui-btn-sm'>#{text[0]}</button>"
      end.join(" ")
      "<div class='layui-btn-group' style='margin-bottom: 15px;'>#{buttons}</div>"
    end
  end
  
  def transform_page_title(content)
    content.gsub(/<kr:page_title[^>]*title="([^"]+)"[^>]*\/>/) do |match|
      title = $1
      "<h2 style='text-align: center; margin: 20px 0; font-size: 24px; color: #333;'>#{title}</h2>"
    end
  end
  
  def transform_tabs(content)
    content.gsub(/<kr:tabs[^>]*>(.*?)<\/kr:tabs>/m) do |match|
      tabs_content = $1
      tabs = tabs_content.scan(/<kr:tab\s+title="([^"]+)"(?:\s+active="([^"]*)")?\/>/)
      tab_headers = tabs.map.with_index do |(title, active), index|
        class_name = (active == "true" || index == 0) ? "layui-this" : ""
        "<li class='#{class_name}'><a href='javascript:;'>#{title}</a></li>"
      end.join
      
      tab_contents = tabs.map.with_index do |(title, active), index|
        class_name = (active == "true" || index == 0) ? "layui-show" : ""
        "<div class='layui-tab-item #{class_name}'></div>"
      end.join
      
      "<div class='layui-tab layui-tab-brief' style='margin: 15px 0;'>
        <ul class='layui-tab-title'>#{tab_headers}</ul>
        <div class='layui-tab-content'>#{tab_contents}</div>
      </div>"
    end
  end
  
  def transform_section(content)
    content.gsub(/<kr:section[^>]*title="([^"]+)"[^>]*\/>/) do |match|
      title = $1
      "<fieldset class='layui-elem-field layui-field-title' style='margin-top: 20px;'><legend>#{title}</legend></fieldset>"
    end
  end
  
  def transform_form_row(content)
    content.gsub(/<kr:form_row[^>]*>(.*?)<\/kr:form_row>/m) do |match|
      form_content = $1
      "<div class='layui-row' style='margin-bottom: 15px;'>#{form_content}</div>"
    end
  end
  
  def transform_form_fields(content)
    # 先处理自闭合的表单字段
    content = transform_self_closing_form_fields(content)
    
    # 再处理带内容的表单字段
    content = transform_container_form_fields(content)
    
    content
  end
  
  def transform_self_closing_form_fields(content)
    # 匹配自闭合的kr:form_field标签
    content.gsub(/<kr:form_field\s+([^>]*?)\s*\/>/m) do |match|
      attrs_string = $1
      attrs = parse_attributes(attrs_string)
      generate_form_field_html(attrs, "")
    end
  end
  
  def transform_container_form_fields(content)
    # 匹配带内容的kr:form_field标签
    content.gsub(/<kr:form_field\s+([^>]*?)>(.*?)<\/kr:form_field>/m) do |match|
      attrs_string = $1
      inner_content = $2
      attrs = parse_attributes(attrs_string)
      generate_form_field_html(attrs, inner_content)
    end
  end
  
  def parse_attributes(attrs_string)
    attrs = {}
    
    # 解析各种属性，提供更好的默认值
    attrs[:name] = extract_attribute(attrs_string, 'name') || ""
    attrs[:label] = extract_attribute(attrs_string, 'label') || ""
    attrs[:type] = extract_attribute(attrs_string, 'type') || "text"
    attrs[:value] = extract_attribute(attrs_string, 'value') || ""
    attrs[:placeholder] = extract_attribute(attrs_string, 'placeholder') || attrs[:label] || "请输入"
    attrs[:required] = extract_attribute(attrs_string, 'required') == "true"
    attrs[:width] = extract_attribute(attrs_string, 'width') || "33%"
    
    # 调试输出
    puts "解析字段属性: name=#{attrs[:name]}, label=#{attrs[:label]}, type=#{attrs[:type]}"
    
    attrs
  end
  
  def extract_attribute(attrs_string, attr_name)
    # 支持双引号和单引号
    match = attrs_string.match(/#{attr_name}=["']([^"']*)["']/)
    if match
      result = match[1]
      puts "提取属性 #{attr_name}: #{result}"
      result
    else
      puts "未找到属性 #{attr_name} 在: #{attrs_string}"
      nil
    end
  end
  
  def generate_form_field_html(attrs, inner_content)
    # 为缺失的属性提供默认值，确保所有字段都能被渲染
    attrs[:name] = "field_#{rand(1000)}" if attrs[:name].empty?
    attrs[:label] = attrs[:name] if attrs[:label].empty?
    
    input_html = case attrs[:type]
                 when "text"
                   "<input type='text' name='#{attrs[:name]}' value='#{attrs[:value]}' placeholder='#{attrs[:placeholder]}' class='layui-input' #{attrs[:required] ? 'lay-verify="required"' : ''}>"
                 when "number"
                   "<input type='number' name='#{attrs[:name]}' value='#{attrs[:value]}' placeholder='#{attrs[:placeholder]}' class='layui-input' #{attrs[:required] ? 'lay-verify="required"' : ''}>"
                 when "date"
                   "<input type='text' name='#{attrs[:name]}' value='#{attrs[:value]}' placeholder='#{attrs[:placeholder]}' class='layui-input' id='#{attrs[:name]}' #{attrs[:required] ? 'lay-verify="required"' : ''}>"
                 when "select"
                   "<select name='#{attrs[:name]}' #{attrs[:required] ? 'lay-verify="required"' : ''}>#{inner_content}</select>"
                 when "textarea"
                   "<textarea name='#{attrs[:name]}' placeholder='#{attrs[:placeholder]}' class='layui-textarea' #{attrs[:required] ? 'lay-verify="required"' : ''}>#{attrs[:value]}</textarea>"
                 else
                   "<input type='text' name='#{attrs[:name]}' value='#{attrs[:value]}' placeholder='#{attrs[:placeholder]}' class='layui-input' #{attrs[:required] ? 'lay-verify="required"' : ''}>"
                 end
    
    # 根据宽度计算layui网格列数
    col_class = case attrs[:width]
                when "33%", "30%"
                  "layui-col-md4"
                when "50%"
                  "layui-col-md6"
                when "66%", "70%"
                  "layui-col-md8"
                when "100%"
                  "layui-col-md12"
                else
                  "layui-col-md4"
                end
    
    # 根据字段类型决定是否使用layui-input-block或layui-input-inline
    input_container_class = (attrs[:type] == "textarea" || attrs[:width] == "100%") ? "layui-input-block" : "layui-input-inline"
    
    <<~HTML
      <div class="#{col_class}">
        <div class="layui-form-item">
          <label class="layui-form-label">#{attrs[:label]}</label>
          <div class="#{input_container_class}">
            #{input_html}
          </div>
        </div>
      </div>
    HTML
  end
  
  def transform_options(content)
    content.gsub(/<kr:option\s+value="([^"]+)"\s+text="([^"]+)"[^>]*\/>/) do |match|
      value = $1
      text = $2
      "<option value='#{value}'>#{text}</option>"
    end
  end
  
  def transform_attachment_list(content)
    content.gsub(/<kr:attachment_list[^>]*\/>/) do |match|
      <<~HTML
        <div class="layui-upload">
          <button type="button" class="layui-btn layui-btn-normal" id="upload-files">选择文件</button>
          <div class="layui-upload-list">
            <table class="layui-table">
              <thead>
                <tr><th>文件名</th><th>大小</th><th>状态</th><th>操作</th></tr>
              </thead>
              <tbody id="attachment-list"></tbody>
            </table>
          </div>
          <button type="button" class="layui-btn" id="upload-start">开始上传</button>
        </div>
      HTML
    end
  end
end
