# frozen_string_literal: true

require_relative '../../layui_element'

# TreeItem - 树形控件项
# 使用配置注册系统将kr:tree转换为l:tree
class TreeItem < LayuiElement
  attr_accessor :elem, :data, :id, :showCheckbox, :edit, :accordion, :onlyIconControl, :isJump, :showLine, :customName, :text
  
  def pre_process
    # 提取kr配置
    @kr_attrs = extract_kr_attributes
  end
  
  def output_tag
    # 构建上下文
    context = build_context
    
    # 使用配置注册表转换（关键！）
    l_attrs = ComponentConfigRegistry.transform('tree', @kr_attrs, context)
    
    # 生成l:tree标签
    attrs_str = serialize_attrs(l_attrs)
    "<l:tree #{attrs_str}>#{@children}</l:tree>"
  end
  
  private
  
  def extract_kr_attributes
    kr_attrs = {}
    
    # 从tag属性中提取配置
    tag.attr.each do |key, value|
      kr_attrs[key] = value
    end
    
    kr_attrs
  end
  
  def build_context
    {
      scenario: 'single_tree',
      parent_component: self,
      linkage: false
    }
  end
  
  def serialize_attrs(attrs)
    attrs.map do |key, value|
      case value
      when Hash
        "#{key}='#{value.to_json}'"
      when Array
        "#{key}='#{value.to_json}'"
      when String
        "#{key}='#{value}'"
      when true
        "#{key}='true'"
      when false
        "#{key}='false'"
      else
        "#{key}=#{value}"
      end
    end.join(' ')
  end
end
