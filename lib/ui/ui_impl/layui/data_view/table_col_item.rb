# frozen_string_literal: true

class TableColItem
  attr_accessor :type, :fixed, :field, :width, :title, :sort, :totalRow, :fieldTitle, :hide, :expandedMode, :edit, :minWidth, :expandedWidth, :templet

  def output
    {
      type: @type,
      fixed: @fixed,
      field: @field,
      width: @width,
      title: @title,
      sort: @sort,
      totalRow: @totalRow,
      fieldTitle: @fieldTitle,
      hide: @hide,
      expandedMode: @expandedMode,
      edit: @edit,
      minWidth: @minWidth,
      expandedWidth: @expandedWidth,
      templet: @templet
    }
  end
end
