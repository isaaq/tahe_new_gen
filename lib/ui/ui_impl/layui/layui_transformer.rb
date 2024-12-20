# frozen_string_literal: true

class LayuiTransformer
  DICT = { :'t-col' => :TableColTarget, :'t-table' => :TableTarget, i: :InputTarget, f: :FormTarget }
  def self.trans(tag, ctx, children)
    clzname = DICT[tag.name.to_sym]
    if !clzname.nil? && Object.const_defined?(clzname)
      ele = Object.const_get(clzname).new
      ele.tag = tag
      ele.context = ctx
      # ele.object_tree = fnd
      ele.children = children
    else
      __p tag.name
      throw
    end
    ele.output
  end
end
