require_relative '../util/common_func'

class UIPage
  include Common
  attr_accessor :_kr_ui_scope_var, :type, :context

  def initialize(type)
    @_kr_ui_scope_var = {}
    @type = type
    @page = Object.const_get("#{type.capitalize}Page").new
    @processing_layout = false
  end

  ##
  # 处理预编译区域
  def parse_reg_area(point, code, method)
    @_kr_ui_scope_var[point.to_sym] = [code, method]
  end

  def reg_context(key, value)
    @context[key] = value
  end

  def parse_code(source = @page.default_page, b = binding, layout: nil)
    layout = @page.default_layout if layout == :default
    front_code = server_compile(source, b, layout)
    front_compile(front_code)
  end

  private

  def front_compile(code)
    code.gsub!(/#([^{]+?)\{(.*?)#\}/m) do |m|
      key = $1.strip
      original_content = $2
      
      if @_kr_ui_scope_var.key?(key.to_sym)
        replacement_code, method = @_kr_ui_scope_var[key.to_sym]
        
        if method == :append
          # 在区域尾部追加内容
          "#{original_content}#{replacement_code}\n"
        elsif method == :prepend
          # 在区域头部追加内容
          "#{replacement_code}\n#{original_content}"
        else
          # 替换整个区域内容
          replacement_code
        end
      else
        original_content
      end
    end
    kr_del_objtree!(code) if @type != :kr
    code
  end

  def server_compile(source, b, layout)
    clz = Object.const_get("TagLibrary#{@type.capitalize}")
    o = clz.parse(source)
    
    # 处理 @layui_script 标记（如果是 layui 类型）
    # 注释掉脚本处理部分，直接处理 @layui_script 标记
    if @type == :layui && o.include?('@layui_script')
      # 直接使用正则表达式处理 @layui_script 标记
      o = o.gsub(/@layui_script(.*?)@\/layui_script/m) do |match|
        script_content = $1.strip
        # 将脚本内容包裹在 script 标签中
        "<script>#{script_content}</script>"
      end
    end
    
    layout = clz.context.globals.layout
    if @type != 'kr' && (layout.nil? || @processing_layout)
      o2 = ERB.new(o)
      output = o2.result(b)
    else
      @processing_layout = true
      begin
        o2 = parse_code(layout) do
          ERB.new(o).result(b)
        end
        output = o2
      ensure
        @processing_layout = false
      end
    end
    output
  end
end
