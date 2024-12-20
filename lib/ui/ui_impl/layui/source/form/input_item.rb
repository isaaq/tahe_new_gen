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
    'i'
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
    # merge field的属性
    instance_variables.each do |var|
      next if [:@id, :@children, :@object_tree, :@tag, :@context].include?(var)
      var_name = var.to_s.delete('@').to_sym
      vals[var_name] = instance_variable_get(var) unless instance_variable_get(var).nil?
    end
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
