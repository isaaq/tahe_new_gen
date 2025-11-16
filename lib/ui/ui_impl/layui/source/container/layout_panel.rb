class LayoutPanel < LayuiElement
  def elename
    'l_layout_panel'
  end

  def output_tag
    "<#{prefix}:#{elename}>#{@children}</#{prefix}:#{elename}>"
  end
end