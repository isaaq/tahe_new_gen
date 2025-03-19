# frozen_string_literal: true

class TagLibraryKr < Tags::TagLibrary
  extend KrTagHelper
  prefix :kr

  tag :test do |_tag|
    "<%=_kr_ui_scope_var%>"
  end

  tag :test2 do |_tag|
    "<%parse_reg_area('global_func','a=1;b=2', :append)%>"
  end

  tag :test3 do |_tag|
  end

  register_root_tag :kr, :table, :form, :page, :number_range_input
  register_child_tag :kr, :col, :input, :number_range_input
end
