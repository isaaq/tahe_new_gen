# frozen_string_literal: true
class TagLibraryKr < Tags::TagLibrary
  # extend KrTagHelper
  prefix :kr

  tag :input do |tag|
    "<% _kr_ui_scope_var[:xx]=1 %>"
  end

  tag :test do |tag|
    "<%=_kr_ui_scope_var%>"
  end

  tag :test2 do |tag|
    "<%parse_reg_area('global_func','a=1;b=2', :append)%>"
  end
end