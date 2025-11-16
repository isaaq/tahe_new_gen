module TreeTags
  def self.included(base)
    base.class_eval do
      # 树组件标签
      tag 'tree' do |t|
        tree(t.attr, t.expand)
      end

      # 节点点击事件
      tag 'node_click' do |t|
        node_click(t.attr, t.expand)
      end

      # 节点双击事件
      tag 'node_dbclick' do |t|
        node_dbclick(t.attr, t.expand)
      end

      # 复选框点击事件
      tag 'check_change' do |t|
        check_change(t.attr, t.expand)
      end

      # 菜单点击事件
      tag 'menu_click' do |t|
        menu_click(t.attr, t.expand)
      end

      # 工具栏点击事件
      tag 'toolbar_click' do |t|
        toolbar_click(t.attr, t.expand)
      end
    end
  end
end