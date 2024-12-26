class LayuiElementTarget
  include Common
  attr_accessor :id, :children, :object_tree, :tag, :context

  def output
    output_target
  end
end