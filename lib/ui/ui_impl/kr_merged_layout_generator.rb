# KR 布局与内容合并渲染器
# 将布局和内容结合起来生成最终的HTML页面

require_relative 'kr_layout_parser'
require_relative 'kr_content_parser'
require_relative 'kr_transformer'
require_relative 'improved_kr_transformer'

class KrMergedLayoutGenerator
  
  def self.generate(layout_config, content_map)
    generator = new(layout_config, content_map)
    generator.generate
  end
  
  def self.generate_from_files(layout_file, content_file)
    layout_config = KrLayoutParser.parse_file(layout_file)
    content_map = KrContentParser.parse_file(content_file)
    generate(layout_config, content_map)
  end
  
  def initialize(layout_config, content_map)
    @layout_config = layout_config
    @content_map = content_map
    @grid_items = []
  end
  
  def generate
    parse_grid_items
    
    {
      html: generate_html,
      css: generate_css,
      js: generate_js
    }
  end
  
  private
  
  def parse_grid_items
    @layout_config[:items]&.each do |item|
      # 从内容映射中获取对应的内容
      content = @content_map[item[:id]] || ''
      
      # 如果内容是KR标签，则需要转换为HTML
      if content.include?('<kr:')
        puts "\n=== 发现KR标签，开始转换 ==="
        puts "项目ID: #{item[:id]}"
        puts "原始内容: #{content[0..100]}..."
        
        # 添加一个明显的标记到HTML中，确认代码被执行
        content = "<!-- DEBUG: KR标签转换器被调用 - 项目ID: #{item[:id]} -->\n" + content
        
        # 使用与非分离式表单完全相同的转换逻辑
        content = mock_transform_kr_tags(content)
        
        puts "=== KR标签转换完成 ==="
      else
        puts "项目ID: #{item[:id]} - 无KR标签，跳过转换"
      end
      
      @grid_items << {
        id: item[:id],
        x: item[:x] || 0,
        y: item[:y] || 0,
        w: item[:w] || 1,
        h: item[:h] || 1,
        content: content,
        css_class: item[:css_class] || '',
        section: item[:section] || '',
        resizable: item[:resizable] != false,
        draggable: item[:draggable] != false
      }
    end
  end
  
  def generate_html
    # 生成简化的配置数据，不包含内容
    simplified_config = {
      columns: @layout_config[:columns],
      cellHeight: @layout_config[:cellHeight],
      margin: @layout_config[:margin],
      staticGrid: @layout_config[:staticGrid],
      disableDrag: @layout_config[:disableDrag],
      disableResize: @layout_config[:disableResize],
      animate: @layout_config[:animate],
      items: @grid_items.map do |item|
        {
          id: item[:id],
          x: item[:x],
          y: item[:y],
          w: item[:w],
          h: item[:h],
          resizable: item[:resizable],
          draggable: item[:draggable]
        }
      end
    }
    
    html = []
    html << %(<div class="kr-grid-layout" data-grid-config='#{simplified_config.to_json}'>)
    
    # 按section分组生成HTML
    sections = @grid_items.group_by { |item| item[:section] }
    
    sections.each do |section_name, items|
      next if section_name.nil? || section_name.empty?
      
      html << %(<div class="kr-grid-section" data-section="#{section_name}">)
      
      items.each do |item|
        html << generate_grid_item_html(item)
      end
      
      html << '</div>'
    end
    
    # 处理没有section的item
    unsectioned_items = @grid_items.select { |item| item[:section].nil? || item[:section].empty? }
    unsectioned_items.each do |item|
      html << generate_grid_item_html(item)
    end
    
    html << '</div>'
    html.join("\n")
  end
  
  def generate_grid_item_html(item)
    <<~HTML
      <div class="kr-grid-item #{item[:css_class]}" 
           data-gs-id="#{item[:id]}"
           data-gs-x="#{item[:x]}" 
           data-gs-y="#{item[:y]}" 
           data-gs-w="#{item[:w]}" 
           data-gs-h="#{item[:h]}"
           data-gs-resizable="#{item[:resizable]}"
           data-gs-draggable="#{item[:draggable]}">
        <div class="kr-grid-item-content" style="height: auto !important; min-height: #{item[:h] * (@layout_config[:cellHeight] || 80)}px;">
          #{item[:content]}
        </div>
      </div>
    HTML
  end
  
  def generate_css
    <<~CSS
      .kr-grid-layout {
        position: relative;
        width: 100%;
        height: auto !important;
        min-height: 100px;
        overflow: visible;
        background-color: #fff;
        box-sizing: border-box;
        margin-bottom: 20px;
      }
      
      .kr-grid-section {
        margin-bottom: 20px;
        height: auto !important;
        min-height: 50px;
        overflow: visible;
      }
      
      .kr-grid-item {
        position: absolute;
        background-color: #fff;
        border-radius: 4px;
        box-sizing: border-box;
        padding: 5px;
        overflow: visible;
        height: auto !important;
        min-height: 50px;
        z-index: 1;
      }
      
      .kr-grid-item-content {
        width: 100%;
        height: auto !important;
        min-height: 100%;
        padding: 5px;
        overflow: visible;
        display: block;
      }
      
      .kr-grid-item.ui-draggable-dragging {
        z-index: 100;
      }
      
      .kr-grid-item.ui-resizable-resizing {
        z-index: 100;
      }
      
      .kr-grid-placeholder {
        background-color: rgba(0, 0, 0, 0.1);
        border: 1px dashed #aaa;
        border-radius: 2px;
      }
      
      /* 表单样式定义，与非分离式表单保持一致 */
      .layui-form-label {
        width: 110px;
      }
      .layui-input-inline {
        width: 190px;
      }
      .layui-form-item {
        margin-bottom: 15px;
      }
      .required:before {
        content: "* ";
        color: red;
      }
    CSS
  end
  
  def generate_js
    <<~JAVASCRIPT
      // KR 网格布局初始化
      (function() {
        const gridLayout = document.querySelector('.kr-grid-layout');
        if (!gridLayout) return;
        
        const config = JSON.parse(gridLayout.getAttribute('data-grid-config') || '{}');
        
        // 初始化网格项位置
        function initGridItems() {
          const items = gridLayout.querySelectorAll('.kr-grid-item');
          const cellWidth = gridLayout.offsetWidth / (config.columns || 12);
          const cellHeight = config.cellHeight || 60;
          
          // 计算最大Y坐标和高度，用于设置布局容器高度
          let maxY = 0;
          let maxHeight = 0;
          
          items.forEach(item => {
            const x = parseInt(item.getAttribute('data-gs-x')) || 0;
            const y = parseInt(item.getAttribute('data-gs-y')) || 0;
            const w = parseInt(item.getAttribute('data-gs-w')) || 1;
            const h = parseInt(item.getAttribute('data-gs-h')) || 1;
            
            // 更新最大Y坐标和高度
            const itemBottom = y + h;
            if (itemBottom > maxY) {
              maxY = itemBottom;
            }
            
            item.style.left = (x * cellWidth) + 'px';
            item.style.top = (y * cellHeight) + 'px';
            item.style.width = (w * cellWidth) + 'px';
            item.style.minHeight = (h * cellHeight) + 'px';
            // 移除固定高度，使用最小高度代替
          });
          
          // 设置布局容器的最小高度，确保能容纳所有网格项
          gridLayout.style.minHeight = ((maxY + 1) * cellHeight) + 'px';
        }
        
        // 设计器模式切换
        let designMode = false;
        
        function toggleDesignMode() {
          designMode = !designMode;
          
          const items = gridLayout.querySelectorAll('.kr-grid-item');
          items.forEach(item => {
            if (designMode) {
              item.classList.add('design-mode');
            } else {
              item.classList.remove('design-mode');
            }
          });
          
          // 更新网格布局状态
          gridLayout.setAttribute('data-design-mode', designMode ? 'true' : 'false');
        }
        
        // 窗口大小变化时重新计算位置
        window.addEventListener('resize', initGridItems);
        
        // 初始化
        initGridItems();
        
        // 暴露API
        window.KrGridLayout = {
          initGridItems,
          toggleDesignMode
        };
      })();
    JAVASCRIPT
  end
  
  def transform_kr_tags_directly(content)
    # 直接在这里实现KR标签转换
    
    # 1. 转换 kr:toolbar
    content = content.gsub(/<kr:toolbar[^>]*>(.*?)<\/kr:toolbar>/m) do |match|
      toolbar_content = $1
      buttons = toolbar_content.scan(/<kr:button\s+text="([^"]+)"[^>]*\/>/).map do |text|
        "<button type='button' class='layui-btn layui-btn-sm'>#{text[0]}</button>"
      end.join(" ")
      "<div class='layui-btn-group' style='margin-bottom: 15px;'>#{buttons}</div>"
    end
    
    # 2. 转换 kr:page_title
    content = content.gsub(/<kr:page_title[^>]*title="([^"]+)"[^>]*\/>/) do |match|
      title = $1
      "<h2 style='text-align: center; margin: 20px 0; font-size: 24px; color: #333;'>#{title}</h2>"
    end
    
    # 3. 转换 kr:tabs
    content = content.gsub(/<kr:tabs[^>]*>(.*?)<\/kr:tabs>/m) do |match|
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
    
    # 4. 转换 kr:section
    content = content.gsub(/<kr:section[^>]*title="([^"]+)"[^>]*\/>/) do |match|
      title = $1
      "<fieldset class='layui-elem-field layui-field-title' style='margin-top: 20px;'><legend>#{title}</legend></fieldset>"
    end
    
    # 5. 转换 kr:form_row (重要：需要正确处理行级布局)
    content = content.gsub(/<kr:form_row[^>]*>(.*?)<\/kr:form_row>/m) do |match|
      form_content = $1
      
      # 先转换行内的所有kr:form_field
      transformed_fields = form_content.gsub(/<kr:form_field\s+([^>]*?)\s*\/>/m) do |field_match|
        attrs_string = $1
        
        # 解析属性
        name = extract_attr(attrs_string, 'name') || "field_#{rand(1000)}"
        label = extract_attr(attrs_string, 'label') || name
        type = extract_attr(attrs_string, 'type') || 'text'
        value = extract_attr(attrs_string, 'value') || ''
        placeholder = extract_attr(attrs_string, 'placeholder') || label
        required = extract_attr(attrs_string, 'required') == 'true'
        width = extract_attr(attrs_string, 'width') || '33%'
        
        # 生成字段HTML（在行内布局中，与非分离式保持一致）
        width_style = width ? "style='width: #{width};'" : ""
        
        input_html = generate_input_html(name, type, value, placeholder, required)
        
        "<div class='layui-inline' #{width_style}><label class='layui-form-label'>#{label}</label><div class='layui-input-inline'>#{input_html}</div></div>"
      end
      
      # 包装在layui表单项容器中（与非分离式保持一致）
      "<div class='layui-form-item'>#{transformed_fields}</div>"
    end
    
    # 6. 转换独立的 kr:form_field (不在form_row中的)
    content = content.gsub(/<kr:form_field\s+([^>]*?)\s*\/>/m) do |match|
      attrs_string = $1
      
      # 解析属性
      name = extract_attr(attrs_string, 'name') || "field_#{rand(1000)}"
      label = extract_attr(attrs_string, 'label') || name
      type = extract_attr(attrs_string, 'type') || 'text'
      value = extract_attr(attrs_string, 'value') || ''
      placeholder = extract_attr(attrs_string, 'placeholder') || label
      required = extract_attr(attrs_string, 'required') == 'true'
      width = extract_attr(attrs_string, 'width') || '100%'
      
      # 生成独立字段HTML（与非分离式保持一致）
      width_style = width ? "style='width: #{width};'" : ""
      input_html = generate_input_html(name, type, value, placeholder, required)
      
      "<div class='layui-form-item'><div class='layui-inline' #{width_style}><label class='layui-form-label'>#{label}</label><div class='layui-input-inline'>#{input_html}</div></div></div>"
    end
    
    # 7. 转换 kr:attachment_list
    content = content.gsub(/<kr:attachment_list[^>]*\/>/) do |match|
      "<div class='layui-upload'>
        <button type='button' class='layui-btn layui-btn-normal' id='upload-files'>选择文件</button>
        <div class='layui-upload-list'>
          <table class='layui-table'>
            <thead>
              <tr><th>文件名</th><th>大小</th><th>状态</th><th>操作</th></tr>
            </thead>
            <tbody id='attachment-list'></tbody>
          </table>
        </div>
        <button type='button' class='layui-btn' id='upload-start'>开始上传</button>
      </div>"
    end
    
    content
  end
  
  def extract_attr(attrs_string, attr_name)
    match = attrs_string.match(/#{attr_name}=["']([^"']*)["']/)
    match ? match[1] : nil
  end
  
  # 添加CSS样式定义方法，与非分离式表单保持一致
  def generate_form_css
    <<~CSS
      .layui-form-label {
        width: 110px;
      }
      .layui-input-inline {
        width: 190px;
      }
      .layui-form-item {
        margin-bottom: 15px;
      }
      .required:before {
        content: "* ";
        color: red;
      }
    CSS
  end
  
  def generate_input_html(name, type, value, placeholder, required)
    # 根据字段类型生成输入控件HTML
    case type
    when 'text'
      "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
    when 'number'
      "<input type='number' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
    when 'date'
      "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' id='#{name}' #{required ? 'lay-verify="required"' : ''}>"
    when 'select'
      "<select name='#{name}' #{required ? 'lay-verify="required"' : ''}><option value=''>请选择</option></select>"
    when 'textarea'
      "<textarea name='#{name}' placeholder='#{placeholder}' class='layui-textarea' #{required ? 'lay-verify="required"' : ''}>#{value}</textarea>"
    else
      "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
    end
  end

  def generate_field_html(name, label, type, value, placeholder, required, width)
    # 根据字段类型生成不同的HTML
    input_html = case type
                 when 'text'
                   "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
                 when 'number'
                   "<input type='number' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
                 when 'date'
                   "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' id='#{name}' #{required ? 'lay-verify="required"' : ''}>"
                 when 'select'
                   "<select name='#{name}' #{required ? 'lay-verify="required"' : ''}><option value=''>请选择</option></select>"
                 when 'textarea'
                   "<textarea name='#{name}' placeholder='#{placeholder}' class='layui-textarea' #{required ? 'lay-verify="required"' : ''}>#{value}</textarea>"
                 else
                   "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
                 end
    
    # 根据宽度计算layui网格列数
    col_class = case width
                when '33%', '30%'
                  'layui-col-md4'
                when '50%'
                  'layui-col-md6'
                when '66%', '70%'
                  'layui-col-md8'
                when '100%'
                  'layui-col-md12'
                else
                  'layui-col-md4'
                end
    
    # 根据字段类型决定是否使用layui-input-block或layui-input-inline
    input_container_class = (type == 'textarea' || width == '100%') ? 'layui-input-block' : 'layui-input-inline'
    
    "<div class='#{col_class}'>
      <div class='layui-form-item'>
        <label class='layui-form-label'>#{label}</label>
        <div class='#{input_container_class}'>
          #{input_html}
        </div>
      </div>
    </div>"
  end

  def mock_transform_kr_tags(content)
    # 这是一个简化的KR标签转换实现
    # 在实际项目中，这里应该调用完整的KrTransformer
    
    # 多次处理，确保嵌套标签也能被转换
    5.times do
      # 处理工具栏
      content = content.gsub(/<kr:toolbar[^>]*>(.*?)<\/kr:toolbar>/m) do |match|
        toolbar_content = $1
        buttons = toolbar_content.scan(/<kr:button\s+text="([^"]+)"[^>]*\/>/).map do |text|
          "<button type='button' class='layui-btn layui-btn-sm'>#{text[0]}</button>"
        end.join(" ")
        "<div class='layui-btn-group' style='margin-bottom: 15px;'>#{buttons}</div>"
      end
      
      # 处理页面标题
      content = content.gsub(/<kr:page_title[^>]*title="([^"]+)"[^>]*\/>/) do |match|
        title = $1
        "<h2 style='text-align: center; margin: 20px 0; font-size: 24px; color: #333;'>#{title}</h2>"
      end
      
      # 处理选项卡
      content = content.gsub(/<kr:tabs[^>]*>(.*?)<\/kr:tabs>/m) do |match|
        tabs_content = $1
        tabs = tabs_content.scan(/<kr:tab\s+title="([^"]+)"(?:\s+active="([^"]*)")?\/>/)
        tab_headers = tabs.map.with_index do |(title, active), index|
          class_name = (active == "true" || index == 0) ? "layui-this" : ""
          "<li class='#{class_name}'><a href='javascript:;'>#{title}</a></li>"
        end.join
        
        # 添加内容区域
        tab_contents = tabs.map.with_index do |(title, active), index|
          class_name = (active == "true" || index == 0) ? "layui-show" : ""
          "<div class='layui-tab-item #{class_name}'></div>"
        end.join
        
        "<div class='layui-tab layui-tab-brief' style='margin: 15px 0;'>
          <ul class='layui-tab-title'>#{tab_headers}</ul>
          <div class='layui-tab-content'>#{tab_contents}</div>
        </div>"
      end
      
      # 处理区域标题
      content = content.gsub(/<kr:section[^>]*title="([^"]+)"[^>]*\/>/) do |match|
        title = $1
        "<fieldset class='layui-elem-field layui-field-title' style='margin-top: 20px;'><legend>#{title}</legend></fieldset>"
      end
      
      # 处理表单行
      content = content.gsub(/<kr:form_row[^>]*>(.*?)<\/kr:form_row>/m) do |match|
        form_content = $1
        "<div class='layui-row' style='margin-bottom: 15px;'>#{form_content}</div>"
      end
      
      # 处理简单的表单字段（自闭合标签）
      content = content.gsub(/<kr:form_field\s+([^>]*)\s*\/>/m) do |match|
        attrs = $1
        
        # 解析属性
        name_match = attrs.match(/name="([^"]*)"/)
        name = name_match ? name_match[1] : ""
        label_match = attrs.match(/label="([^"]*)"/)
        label = label_match ? label_match[1] : ""
        type_match = attrs.match(/type="([^"]*)"/)
        type = type_match ? type_match[1] : "text"
        value_match = attrs.match(/value="([^"]*)"/)
        value = value_match ? value_match[1] : ""
        placeholder_match = attrs.match(/placeholder="([^"]*)"/)
        placeholder = placeholder_match ? placeholder_match[1] : ""
        required_match = attrs.match(/required="([^"]*)"/)
        required = required_match && required_match[1] == "true"
        width_match = attrs.match(/width="([^"]*)"/)
        width = width_match ? width_match[1] : "33%"
        
        generate_form_field_html(name, label, type, value, placeholder, required, width, "")
      end
      
      # 处理带内容的表单字段
      content = content.gsub(/<kr:form_field\s+([^>]*)>(.*?)<\/kr:form_field>/m) do |match|
        attrs = $1
        inner_content = $2
        
        # 解析属性
        name_match = attrs.match(/name="([^"]*)"/)
        name = name_match ? name_match[1] : ""
        label_match = attrs.match(/label="([^"]*)"/)
        label = label_match ? label_match[1] : ""
        type_match = attrs.match(/type="([^"]*)"/)
        type = type_match ? type_match[1] : "text"
        value_match = attrs.match(/value="([^"]*)"/)
        value = value_match ? value_match[1] : ""
        placeholder_match = attrs.match(/placeholder="([^"]*)"/)
        placeholder = placeholder_match ? placeholder_match[1] : ""
        required_match = attrs.match(/required="([^"]*)"/)
        required = required_match && required_match[1] == "true"
        width_match = attrs.match(/width="([^"]*)"/)
        width = width_match ? width_match[1] : "33%"
        
        generate_form_field_html(name, label, type, value, placeholder, required, width, inner_content)
      end
      
      # 处理选项
      content = content.gsub(/<kr:option\s+value="([^"]+)"\s+text="([^"]+)"[^>]*\/>/) do |match|
        value = $1
        text = $2
        "<option value='#{value}'>#{text}</option>"
      end
      
      # 处理附件列表
      content = content.gsub(/<kr:attachment_list[^>]*\/>/) do |match|
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
    
    content
  end
  
  # 生成表单字段HTML的辅助方法
  def generate_form_field_html(name, label, type, value, placeholder, required, width, inner_content)
      
      input_html = case type
                   when "text"
                     "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
                   when "number"
                     "<input type='number' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
                   when "date"
                     "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' id='#{name}' #{required ? 'lay-verify="required"' : ''}>"
                    when "select"
                      "<select name='#{name}' #{required ? 'lay-verify="required"' : ''}>#{inner_content}</select>"
                   when "textarea"
                     "<textarea name='#{name}' placeholder='#{placeholder}' class='layui-textarea' #{required ? 'lay-verify="required"' : ''}>#{value}</textarea>"
                   else
                     "<input type='text' name='#{name}' value='#{value}' placeholder='#{placeholder}' class='layui-input' #{required ? 'lay-verify="required"' : ''}>"
                   end
      
      # 根据宽度计算layui网格列数
      col_class = case width
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
      input_container_class = (type == "textarea" || width == "100%") ? "layui-input-block" : "layui-input-inline"
      
      <<~HTML
        <div class="#{col_class}">
          <div class="layui-form-item">
            <label class="layui-form-label">#{label}</label>
            <div class="#{input_container_class}">
              #{input_html}
            </div>
          </div>
        </div>
      HTML
  end

  # 与非分离式表单完全相同的KR标签转换方法
  def mock_transform_kr_tags(content)
    # 简单模拟KR标签转换为HTML
    # 在实际项目中，应该使用KrTransformer
    
    # 处理工具栏
    content = content.gsub(/<kr:toolbar[^>]*>(.*?)<\/kr:toolbar>/m) do |match|
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
end
