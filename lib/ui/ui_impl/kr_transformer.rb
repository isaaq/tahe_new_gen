# frozen_string_literal: true

class KrTransformer
  include Common
  DICT = { col: :TableColItem, table: :TableItem, form: :FormTag, input: :InputItem }
  def self.trans(tag, ctx, children = nil)
    # TODO: kr tag -> layui tag 策略模板
    # 这里应该读取NodeEditor编辑过的内容
    file = M[:sys_files].query(Name: 'test_node.krnode').to_a[0]
    file_content = file[:Content]
    # 解析内容, 这里解析的应该是默认的策略
    KrNodeBuilder.build(file_content)
    # 结构树元数据内容
    if !children.nil?
      fnd = ctx[tag['id'].to_sym]
    else
      fnd = ctx[tag.parent['id'].to_sym][tag.name.to_sym].find { |f| f[:id] == tag['id'] } unless tag.parent['id'].nil?
    end

    clzname = DICT[tag.name.to_sym]
    if clzname && Object.const_defined?(clzname)
      ele = Object.const_get(clzname).new
      ele.tag = tag
      ele.context = ctx
      ele.object_tree = fnd
      ele.children = children
    else
      __p "未找到#{tag.name}对应的类"
    end
    ele&.output
  end
end
