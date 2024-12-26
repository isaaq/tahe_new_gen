# frozen_string_literal: true

## KrPageItem
# 整个页面
#
class PageItem < LayuiElement

  def pre_process
    if File.exist?(tag['layout'])
      tag.context.globals.layout = File.read(tag['layout'])
    end

  end

  def output_tag
    out = <<~EOF
    <%parse_reg_area('global_view','a=1;b=2', :append)%>
    <%parse_reg_area('global_script','a=3;b=4', :append)%>
    <div class="layui-container" style="margin-top: 20px;">
      #global_view{
      #}
    </div>
    #global_script{
    #}
    EOF
  end
end