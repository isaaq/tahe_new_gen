# frozen_string_literal: true

require_relative "../../../../../model/type/builtin/field_behavior"
require "securerandom"

class NumberRangeInputItem < LayuiElement
  include FieldBehavior

  def initialize
    super
    @placeholder = ""
    @label = ""
    @value = ""
    @min_value = ""
    @max_value = ""
  end

  def elename
    "nri"
  end

  def props
    vals = {
      type: @type,
      name: @name,
      label: @label,
      placeholder: @placeholder,
      value: @value,
    }
    vals.map { |key, value| "#{key}=\"#{value}\"" }.join(" ")
  end

  def output_tag
    "<#{prefix}:#{elename} #{props} />"
  end
end
