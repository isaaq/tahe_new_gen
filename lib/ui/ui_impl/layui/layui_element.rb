# frozen_string_literal: true

class LayuiElement < BaseUIElement
  attr_accessor :id, :children, :object_tree, :tag, :context

  def prefix
    'l'
  end

  def output
    '//[' + object_tree.to_json  + ']//'+ "\n" + output_tag
  end
end
