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
    kr_del_objtree!(code)
    code.gsub(/#([^{]+?)\{.*?#\}/m) do |_m|
      key = $1.strip
      if @_kr_ui_scope_var.key?(key.to_sym)
        replacement_code, method = @_kr_ui_scope_var[key.to_sym]
        if method == :append
          "#{replacement_code}\n"
        elsif method == :prepend
          "#{replacement_code}\n"
        else
          replacement_code
        end
      else
        ""
      end
    end
  end

  def server_compile(source, b, layout)
    clz = Object.const_get("TagLibrary#{@type.capitalize}")
    o = clz.parse(source)
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
