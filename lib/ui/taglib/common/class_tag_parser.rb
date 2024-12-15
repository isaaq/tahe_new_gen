class TagParser
  def self.parse!(content)
    content.replace TagLibraryDC.parse(content)
    content.replace TagLibraryLayui.parse(content)
  end

  def self.parse(content)
    content = TagLibraryDC.parse(content)
    content = TagLibraryLayui.parse(content)
  end
end
