# frozen_string_literal: true

require_relative '../../../../../model/type/builtin/field_behavior'

class InputItem < LayuiElement
  include FieldBehavior

  def initialize
    super
    @placeholder = ''
    @label = ''
    @value = ''
  end

  def elename
    'input'
  end

  def props
    vals = {
      type: @type,
      name: @name,
      label: @label,
      placeholder: @placeholder,
      value: @value
    }
    vals.merge!(form_additional_attr) if form_additional_attr
    vals.reject! { |_, v| v.nil? || v.empty? }
    vals.map { |key, value| "#{key}=\"#{value}\"" }.join(' ')
  end

  def set_to_var
    @tag.attr.keys.each do |k|
        self.class.instance_variable_set("@#{k}", nil) unless self.class.instance_variable_defined?("@#{k}")
        instance_variable_set("@#{k}", @tag[k])
    end
  end

  def output_tag
    set_to_var

    "<#{prefix}:#{elename} #{props} />"
  end
end
