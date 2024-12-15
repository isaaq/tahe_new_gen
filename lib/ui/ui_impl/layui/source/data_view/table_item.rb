# frozen_string_literal: true

class TableItem < LayuiElement
  attr_accessor :elem, :url, :cols, :data, :id, :toolbar, :defaultToolbar, :width, :height, :maxHeight, :cellMinWidth,
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

  def output_tag
    "<#{prefix}:#{elename} #{props}>#{@children}</#{prefix}:#{elename}>"
  end
end
