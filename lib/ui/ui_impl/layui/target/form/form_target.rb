# frozen_string_literal: true

##
# FormTarget
# Form的Layui目标类
#

class FormTarget < LayuiElementTarget

  ##
  # 输出目标
  # layui表单分为两部分
  # 1. 展示部分, TODO 得考虑布局
  # 2. 代码部分
  # 这两部分分别输出到对应的位置才行
  def output_target
    if @tag['objtree']
      json = kr_get_objtree(@tag['objtree'])

      <<~CODE
        <form class="layui-form" lay-filter="#{json[:id]}">
        #{tag.expand}
        </form>
      CODE
    else
      <<~CODE
        <form class="layui-form" lay-filter="#{tag['id']}">
        #{tag.expand}
        </form>
      CODE
      # TODO 没有objtree的话 需要解析标签
    end
  end

end