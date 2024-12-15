# frozen_string_literal: true

class LayuiTransformer
  DICT = { :'t-col' => :TableColTarget, :'t-table' => :TableTarget }
  def self.trans(tag, ctx, children)
    clzname = DICT[tag.name.to_sym]
    if Object.const_defined?(clzname)
      ele = Object.const_get(clzname).new
      ele.tag = tag
      ele.context = ctx
      # ele.object_tree = fnd
      ele.children = children
    end
    ele.output
  end
end
