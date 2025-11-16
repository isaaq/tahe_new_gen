module DataTableTags
  def self.included(base)
    base.class_eval do
      # 主表格标签
      tag 'dt' do |t|
        datatable(t.attr, t.expand)
      end
      
      # 表格工具栏事件
      tag 'toolbar_event' do |t|
        toolbar_event(t.attr, t.expand)
      end
      
      # 表格行工具条事件
      tag 'tool_event' do |t|
        tool_event(t.attr, t.expand)
      end
      
      # 表格行点击事件
      tag 'row_event' do |t|
        row_event(t.attr, t.expand)
      end
      
      # 表格单元格编辑事件
      tag 'edit_event' do |t|
        edit_event(t.attr, t.expand)
      end
      
      # 表格排序事件
      tag 'sort_event' do |t|
        sort_event(t.attr, t.expand)
      end
      
      # 表格复选框选择事件
      tag 'checkbox_event' do |t|
        checkbox_event(t.attr, t.expand)
      end
      
      # 重载表格数据
      tag 'reload_table' do |t|
        reload_table(t.attr)
      end
    end
  end
end