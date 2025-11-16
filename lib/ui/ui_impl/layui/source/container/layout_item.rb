class LayoutItem < LayuiElement
  def elename
    'l_layout'
  end

  def output_tag
    "<#{prefix}:#{elename}>#{@children}</#{prefix}:#{elename}>"
  end
end