class TagLibraryLayui < Tags::TagLibrary
  extend LayUITagHelper
  prefix :l

  register_root_tag  :layui, :'t', :f
  register_child_tag :layui, :'col', :i

end
