class TagLibraryLayui < Tags::TagLibrary
  extend LayUITagHelper
  prefix :'l'
  # tag 'ds' do |t|
  #   type = t.attr['type']
  #
  # end
  tag 't-item' do |t|
    table_search_item(t.attr['text'], t.attr['field'])
  end
  tag 't-item-sel' do |t|
    table_search_item_select(t.attr, t.≈)
  end
  tag 't-item-dlg' do |t|
    table_search_dlg(t.attr, t.attr)
  end
  tag 't-item-date' do |t|
    table_search_date(t.attr, t.attr)
  end
  tag 't-dpbtn' do |t|
    table_toolbar_dpbtn(t.attr, t.attr)
  end
  tag 't-top' do |t|
    content = t.expand
    table_search(content)
  end
  tag 't' do |t|
    # opt = {toolbar_id: t.attr['toolbar_id']}
    opt= {}
    content = t.expand
    opt[:cols] = get_custom_cols(content)
    opt[:templets] = get_custom_cols_templets(content)
    opt[:add] = get_table_add(content)
    opt[:edit] = get_table_edit(content)
    opt[:del] = get_table_del(content)
    opt[:disable] = get_table_disable(content)
    opt[:colbtn] = get_cols_btn(content)
    opt[:fk] = get_table_fk(content)
    opt[:dict] = get_table_dict(content)
    opt[:toolbar] = get_table_toolbar(content)

    table(t.attr, opt)
  end
  tag 't-add' do |t|
    table_add(t.attr, t.expand)
  end
  tag 't-edit' do |t|
    table_edit(t.attr)
  end
  tag 't-del' do |t|
    table_del(t.attr)
  end
  tag 't-disable' do |t|
    table_disable(t.attr)
  end
  tag 't-col' do |t|
    table_col(t.attr, t.expand)
  end
  tag 't-btn' do |t|
    table_col_btn(t.attr)
  end
  tag 't-tb' do |t|
    table_toolbar_custom(t.attr, t.expand)
  end
  # tag 's-tpl-itemop' do |t|
  #   id = t.attr['id'] ls
  # || gen_id
  #   script_block(id, col_edit_del())
  # end
  tag 'layui' do |t|
    layui(t.expand)
  end
  tag 'tab' do |t|
    tab(t.attr, t.expand)
  end
  tag 'tab-item' do |t|
    tab_item(t.attr, t.expand)
  end
  tag 'input' do |t|
    input(t.attr)
  end
  tag 'date' do |t|
    tag_date(t.attr)
  end
  tag 'radio' do |t|
    tag_radio(t.attr)
  end
  tag 'label' do |t|
    label(t.attr)
  end
  tag 'sel' do |t|
    sel(t.attr)
  end
  tag 'switch' do |t|
    switch(t.attr)
  end
  tag 'tree' do |t|
    evt = t.expand
    dtree(t.attr, evt)
  end
  tag 'item-click' do |t|
    item_click(t.expand)
  end
  tag 'form' do |t|
    form(t.attr, t.expand)
  end
  tag 'cb' do |t|
    form_cb(t.attr, t.expand)
  end
  tag 'data' do |t|
    form_data(t.attr, t.expand)
  end
  tag 'ta' do |t|
    tag_textarea(t.attr, t.expand)
  end
  tag 'form-btn' do |t|
    tag_formbtn(t.attr, t.expand)
  end
end