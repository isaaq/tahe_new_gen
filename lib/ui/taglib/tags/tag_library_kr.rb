# frozen_string_literal: true

class TagLibraryKr < Tags::TagLibrary
  extend KrTagHelper
  prefix :kr

  private 
  def self.setup_parent_tag(tag)
    parent_id = tag.parent['id']
    id = kr_id(tag)
    make_ctx(tag, id, parent_id)
    make_target(tag, :kr)
  end

  def self.setup_root_tag(tag)
    id = kr_id(tag)
    make_ctx(tag, id)
    make_target(tag, :kr, tag.expand)
  end

  def self.register_root_tag(*names)
    names.each do |name|
      tag name do |tag|
        setup_root_tag(tag)
      end
    end
  end

  def self.register_child_tag(*names)
    names.each do |name|
      tag name do |tag|
        setup_parent_tag(tag)
      end
    end
  end

  tag :test do |_tag|
    '<%=_kr_ui_scope_var%>'
  end

  tag :test2 do |_tag|
    "<%parse_reg_area('global_func','a=1;b=2', :append)%>"
  end

  register_root_tag :table, :form
  register_child_tag :col, :input
 
end
