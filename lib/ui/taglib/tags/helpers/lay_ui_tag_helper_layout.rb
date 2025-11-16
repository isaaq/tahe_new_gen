# frozen_string_literal: true

# LayUI 布局标签辅助模块
module LayUITagHelperLayout
  # 处理 layout 标签
  def layout(opt, content)
    puts "DEBUG: layout 方法被调用，参数: #{opt.inspect}"
    type = opt['type'] || 'row'
    style = opt['style'] || ''
    id = opt['id'] ? "id=\"#{opt['id']}\"" : ''
    
    case type
    when 'row'
      # 行布局
      <<~EOF
      <div class="layui-row" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    when 'col'
      # 列布局
      <<~EOF
      <div class="layui-col" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    when 'card'
      # 卡片布局
      <<~EOF
      <div class="layui-card" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    else
      # 默认布局
      <<~EOF
      <div class="layui-container" #{id} style="#{style}">
        #{content}
      </div>
      EOF
    end
  end

  # 处理 layout_panel 标签
  def layout_panel(opt, content)
    width = opt['width'] || '100%'
    height = opt['height'] || 'auto'
    style = opt['style'] || ''
    id = opt['id'] ? "id=\"#{opt['id']}\"" : ''
    
    # 计算 layui 的栅格系统宽度
    grid_width = if width.end_with?('%')
                   (width.to_f / 100 * 12).round
                 else
                   6 # 默认为一半宽度
                 end
    
    <<~EOF
    <div class="layui-col-md#{grid_width}" #{id} style="#{style}; height: #{height};">
      #{content}
    </div>
    EOF
  end
end
