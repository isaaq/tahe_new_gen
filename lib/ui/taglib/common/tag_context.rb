# AX TAGS
# Flexible, extensible custom tag and template-parsing framework built
# around the Radius templating framework.
#
# AxContext - A context contains a dictionary of tags that can be used
#  in template parsing. Context objects are passed to parsers alongside
#  templates to enable parsing.
#

module Tags
  class TagContext < Radius::Context

    # 处理未支持的标签，使用div元素替代，并保持子元素渲染逻辑不变
    def tag_missing(tag, attr, &block)
      # 从配置中获取替代标签，默认为div
      missing_tag = Common::C[:missing_tag] || 'div'
      
      # 将属性转换为HTML属性字符串
      attr_str = attr.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
      attr_str = " #{attr_str}" unless attr_str.empty?
      
      # 添加原标签名作为类名，便于样式定义
      class_attr = attr['class'] ? "#{attr['class']} missing-tag-#{tag}" : "missing-tag-#{tag}"
      attr_str = attr_str.sub(/class=\"([^\"]*)\"/i, "class=\"#{class_attr}\"") if attr['class']
      attr_str = attr_str + " class=\"missing-tag-#{tag}\"" unless attr['class']
      
      # 渲染子元素
      content = block ? block.call : ''
      
      # 返回替代标签的HTML
      %{<!-- 未定义标签 "#{tag}" 替换为 #{missing_tag} -->
<#{missing_tag}#{attr_str} data-original-tag="#{tag}">#{content}</#{missing_tag}>}
    end

    # A method in-reserve for generic error-reporting to the end-user:
    def tag_error(tag, error_text)
      %{<span class="error parse-error ui-state-error">Error in rendering tag \"#{tag}\"; #{error_text}</span>}
    end

  end
end
