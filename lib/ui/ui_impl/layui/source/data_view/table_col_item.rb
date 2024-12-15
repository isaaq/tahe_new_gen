# frozen_string_literal: true

class TableColItem < LayuiElement
  attr_accessor :type, :fixed, :field, :width, :title, :sort, :totalRow, :fieldTitle, :hide, :expandedMode, :edit,
                :minWidth, :expandedWidth, :templet

  def elename
    't-col'
  end

  def props
    vals = {
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
    vals.map { |key, value| "#{key}=\"#{value}\"" }.join(' ')
  end

  def output_tag
    "<#{prefix}:#{elename} #{props} />"
  end
end
