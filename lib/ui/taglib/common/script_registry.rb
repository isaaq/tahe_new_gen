require 'set'

module Tags
  # 脚本资源池，用于管理和去重JavaScript资源
  class ScriptRegistry
    attr_reader :scripts, :libraries, :inline_scripts
    
    def initialize
      # 存储外部脚本引用（如<script src="..."></script>）
      @libraries = Set.new
      # 存储内联脚本代码（如<script>...</script>）
      @inline_scripts = Set.new
      # 存储所有脚本（用于输出）
      @scripts = []
    end
    
    # 添加外部脚本库
    def add_library(src, attributes = {})
      # 构建属性字符串
      attrs = attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
      attrs = " #{attrs}" unless attrs.empty?
      
      script_tag = "<script src=\"#{src}\"#{attrs}></script>"
      
      # 如果库不存在，则添加
      unless @libraries.include?(src)
        @libraries.add(src)
        @scripts << script_tag
      end
      
      script_tag
    end
    
    # 添加内联脚本
    def add_inline(code, attributes = {})
      # 构建属性字符串
      attrs = attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
      attrs = " #{attrs}" unless attrs.empty?
      
      # 如果内联脚本不存在，则添加
      unless @inline_scripts.include?(code)
        @inline_scripts.add(code)
        script_tag = "<script#{attrs}>#{code}</script>"
        @scripts << script_tag
        return script_tag
      end
      
      # 返回空字符串，因为脚本已存在
      ""
    end
    
    # 清空注册表
    def clear
      @libraries.clear
      @inline_scripts.clear
      @scripts.clear
    end
    
    # 获取所有脚本的HTML字符串
    def to_html
      @scripts.join("\n")
    end
    
    # 获取所有脚本代码（用于注入到模板中）
    def to_s
      to_html
    end
    
    # 支持<<操作符添加脚本
    def <<(script)
      if script.start_with?("<script src=")
        # 提取src属性
        src = script.match(/src=["']([^"']+)["']/)[1]
        attributes = {}
        
        # 提取其他属性
        script.scan(/(\w+)=["']([^"']+)["']/).each do |attr, value|
          attributes[attr] = value unless attr == 'src'
        end
        
        add_library(src, attributes)
      else
        # 提取内联脚本代码
        code_match = script.match(/<script[^>]*>(.*?)<\/script>/m)
        if code_match
          code = code_match[1]
          attributes = {}
          
          # 提取属性
          script.scan(/(\w+)=["']([^"']+)["']/).each do |attr, value|
            attributes[attr] = value
          end
          
          add_inline(code, attributes)
        else
          # 如果不是标准脚本标签，直接添加
          @scripts << script
        end
      end
      
      self
    end
  end
end
