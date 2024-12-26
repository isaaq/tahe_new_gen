# frozen_string_literal: true

##
# FormTarget
# Form的Layui目标类
#

class FormTarget < LayuiElementTarget

    ##
    # 输出目标
    # layui表单分为两部分
    # 1. 布局部分
    # 2. 代码部分
    # 这两部分分别输出到对应的位置才行
    def output_target
        if @tag['objtree']
            str = @tag['objtree'].gsub(/\/\/\[(.+?)\]\/\//, "\\1")
            json = JSON.parse(str)


        else
            # TODO 没有objtree的话 需要解析标签
        end
    end

end