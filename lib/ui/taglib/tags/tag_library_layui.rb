class TagLibraryLayui < Tags::TagLibrary
  extend LayUITagHelper
  prefix :l

  tag 't-col' do |tag|
    parent_id = tag.parent['id']
    id = kr_id(tag)
    make_ctx(tag, id, parent_id)
    make_target(tag, :layui)
  end

  tag 't-table' do |tag|
    parent_id = tag.parent['id']
    id = kr_id(tag)
    make_ctx(tag, id, parent_id)
    make_target(tag, :layui)
  end
end
