## ScriptItem
# 处理脚本标签
#
class ScriptItem < LayuiElement
  def pre_process
    @content = tag.expand
  end

  def output_tag
    # 获取标签属性
    attrs = {}
    tag.attr.each do |k, v|
      next if k == 'id' # 跳过id属性，因为它已经被特殊处理
      attrs[k] = v
    end
    
    # 如果有src属性，则是外部脚本
    if tag.attr['src']
      # 将外部脚本添加到资源池
      tag.context.globals.script_registry.add_library(tag.attr['src'], attrs)
      return ""
    else
      # 将内联脚本添加到资源池
      tag.context.globals.script_registry.add_inline(@content, attrs)
      return ""
    end
  end
end
