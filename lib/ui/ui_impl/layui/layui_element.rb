# frozen_string_literal: true

class LayuiElement < BaseUIElement
  attr_accessor :id, :children, :object_tree, :tag, :context, :props

  def prefix
    'l'
  end

  def pre_process; end

  def output
    pre_process
    '//[' + object_tree.to_json  + ']//'+ "\n" + output_tag
  end
end
