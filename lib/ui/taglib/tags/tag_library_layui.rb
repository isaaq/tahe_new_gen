class TagLibraryLayui < Tags::TagLibrary
  extend LayUITagHelper
  prefix :l

  register_root_tag :layui, :'t', :f, :nri
  register_child_tag :layui, :'col', :i, :nri
end
