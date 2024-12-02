class UIPage
  attr_accessor :_kr_ui_scope_var

  def initialize(type)
    @_kr_ui_scope_var = {}
    @page = Object.const_get("#{type.capitalize}Page").new
  end

  ##
  # 处理预编译区域
  def parse_reg_area(point, code, method)
    @_kr_ui_scope_var[point.to_sym] = [code, method]
  end

  def parse(source = @page.default_page, b = binding, layout: nil)
    layout = @page.default_layout if layout == :default
    front_code = server_compile(source, b, layout)
    output = front_compile(front_code)
    webpack(output)
  end

  private

  def webpack(output)
    output
  end

  def front_compile(code)
    code.gsub(/#(.+?)\{[\n\s]*(.+)[\n\s]*#\}\n*|#(.+?)\{\s*(.+?)*\s*\}\n*/) do |m|
      unless $1.nil?
        if @_kr_ui_scope_var.key?($1.to_sym)
          code, method = @_kr_ui_scope_var[$1.to_sym]
          if method == :append
            "#{$2}\n#{code}\n"
          elsif $1[0] == :prepend
            "#{code}\n#{$2}\n"
          else
            code
          end
        else
          "#{$2}"
        end
      end
      # ERB.new(pre).result(binding)
    end
  end

  def server_compile(source, b, layout)
    o = TagLibraryKr.parse(source)

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
