# frozen_string_literal: true

class LayuiElement < BaseUIElement
  attr_accessor :id, :children, :object_tree, :tag, :context, :props

  def prefix
    'l'
  end

  def pre_process; end

  def output
    pre_process
    # 暂时禁用JSON前缀，专注于标签转换
    output_tag
  end
end
