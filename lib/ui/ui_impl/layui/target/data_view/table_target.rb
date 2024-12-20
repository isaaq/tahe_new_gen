class TableTarget < LayuiElementTarget
  attr_accessor :tag, :context, :childrem, :elem, :url, :cols, :data, :id, :toolbar, :defaultToolbar, :width, :height, :maxHeight, :cellMinWidth,
                :cellMaxWidth, :lineStyle, :className, :css, :cellExpandedMode, :cellExpandedWidth, :escape, :totalRow, :page

  def elename
      't-table'
  end

  def props
    vals = {
      url: @url,
      cols: @cols
    }
    vals.map { |key, value| "#{key}=\"#{value}\"" }.join(' ')
  end


  def output_target
    if @tag['objtree']
      str = @tag['objtree'].gsub(/\/\/\[(.+?)\]\/\//, "\\1")
      json = JSON.parse(str)
      cols = json['col']
      
    else
      # TODO 没有objtree的话 需要解析标签
    end
  end
end