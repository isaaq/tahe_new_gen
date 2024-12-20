class UIPage
  attr_accessor :_kr_ui_scope_var, :type, :context

  def initialize(type)
    @_kr_ui_scope_var = {}
    @type = type
    @page = Object.const_get("#{type.capitalize}Page").new
  end

  ##
  # 处理预编译区域
  def parse_reg_area(point, code, method)
    @_kr_ui_scope_var[point.to_sym] = [code, method]
  end

  def reg_context(key, value)
    @context[key] = value
  end

  def parse(source = @page.default_page, b = binding, layout: nil)
    layout = @page.default_layout if layout == :default
    front_code = server_compile(source, b, layout)
    front_compile(front_code)
  end

  private

  def front_compile(code)
    code.gsub(/#(.+?)\{\s*(.+?)\s*#\}|#(.+?)\{\s*(.+?)\s*\}/) do |_m|
      unless ::Regexp.last_match(1).nil?
        if @_kr_ui_scope_var.key?(::Regexp.last_match(1).to_sym)
          code, method = @_kr_ui_scope_var[::Regexp.last_match(1).to_sym]
          if method == :append
            "#{::Regexp.last_match(2)}\n#{code}\n"
          elsif ::Regexp.last_match(1)[0] == :prepend
            "#{code}\n#{::Regexp.last_match(2)}\n"
          else
            code
          end
        else
          ::Regexp.last_match(2).to_s
        end
      else
        ::Regexp.last_match(2).to_s
      end
    end
  end

  def server_compile(source, b, layout)
    clz = Object.const_get("TagLibrary#{@type.capitalize}")
    o = clz.parse(source)

    if layout.nil?
      o2 = ERB.new(o)
      output = o2.result(b)
    else
      o2 = parse(layout) do
        ERB.new(o).result(b)
      end
      output = o2
    end
    output
  end
end
