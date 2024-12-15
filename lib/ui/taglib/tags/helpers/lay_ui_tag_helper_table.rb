def table_search_item(label, field, opt = {})
  input_item = <<-EOF
    <div class="layui-form-item layui-inline">
      <label class="layui-form-label">#{label}</label>
      <div class="layui-input-inline">
        <input type="text" name="#{field}" placeholder="" class="layui-input">
      </div>
    </div>
  EOF
end

def table_search_item_select(attr, content)
  label = attr['text']
  field = attr['field']
  fk = attr['fk']

  opt = make_option(attr)
  sel_item = <<~EOF
    <div class="layui-form-item layui-inline">
      <label class="layui-form-label">#{label}</label>
      <div class="layui-input-inline">
        <select name="#{field}" lay-verify="">
          <option value="">请选择</option>
          #{opt}
        </select>
      </div>
    </div>
  EOF
end

def table_search_dlg(attr, content)
  label = attr['text']
  field = attr['field']
  url = attr['url']
  title = attr['title'] || label
  area = attr['area'].nil? ? "700,830" : "[#{attr['area']}]"

  out = <<~EOF
  <div class="layui-form-item layui-inline">
    <label class="layui-form-label">#{label}</label>
    <div class="layui-input-inline">
       <input type="text" name="#{field}" placeholder="" class="layui-input search-icon" onclick="_dlg('#{title}', '#{area}', '#{url}', '#{field}')">
    </div>
  </div>
  EOF
end

def table_search_date(attr, content)
  label = attr['text']
  field = attr['field']

  out = <<~EOF
  <div class="layui-form-item layui-inline">
    <label class="layui-form-label">#{label}</label>
    <div class="layui-input-inline">
       <input id="#{field}" type="text" name="#{field}" placeholder="" class="layui-input" autocomplete="off">
    </div>
  </div>

  @layui_script
    laydate.render({
      elem: '##{field}',
      range: ['##{field}'],
      rangeLinked: true
    });
  @/layui_script
  EOF
end

def table_toolbar_dpbtn(attr, content)
  label = attr['text']
  id = attr['id']
  enumstr = attr['enum']
  cb = attr['cb']
  url = attr['url']
  enum = enumstr.split(',')
  url = url.split(',')
  enum = enum.each_with_index.map {|m, i| o={}; o[:title] = m; o[:id] = i; o[:url] = url[i]; o}
  uniqid = SecureRandom.base64(8).gsub("/","_").gsub(/=+$/,"")

  out = <<~EOF
  <button id="#{id}" class="layui-btn demo-dropdown-base">
    <span>#{label}</span>
    <i class="layui-icon layui-icon-down layui-font-12"></i>
  </button>

  @layui_script
  
  let _attachdp_#{uniqid} = function() {
    setTimeout(()=>{dropdown.render({
        elem: '##{id}',
        data: #{enum.to_json},
        click: function(obj){
          #{cb}(obj);
        }
      });
    }, 500);
  }
  _attachdp_#{uniqid}();
  @/layui_script
  EOF
end

def make_table_search_items(items)
  items.inject([]) do |t, i|
    t << table_search_item(i[:label, i[:field]], i[:opt])
  end
end

def table_search(items)
  code = <<-EOF
    <div class="top-search layui-card" id="top_search">
			<div class="layui-card-body">
				<form class="layui-form" action="" lay-filter="_search" autocomplete="off">
					 <div class="layui-form-item">
              #{items}
              <div class="layui-form-item layui-inline cmd">
                <button type="button" class="pear-btn pear-btn-md pear-btn-primary" lay-submit lay-filter="top-query">
                  <i class="layui-icon layui-icon-search"></i>
                  查询
                </button>
                <button type="reset" class="pear-btn pear-btn-md">
                  <i class="layui-icon layui-icon-refresh"></i>
                  重置
                </button>
              </div>
					 </div>
				</form>
			</div>
		</div>
  EOF
end

def table(attr, opt = {})
  name = attr['bind_id']

  unless opt[:fk].nil? || opt[:fk] == ''
    arr_strfk = opt[:fk].split("\n").select { |s| s != '' }
    # .gsub("\n", '').gsub(" ", '')
    strfk = arr_strfk.to_s.gsub(" ", '')
    base64 = CGI.escape(Base64.encode64(strfk))
    fk = "?fk=#{base64}".gsub('%0A', '')
  end
  #TODO 多个fk
  unless opt[:dict].nil? || opt[:dict] == ''
    strfk = opt[:dict].gsub("\n", '').gsub(" ", '')
    base64 = CGI.escape(Base64.encode64(strfk))
    fk = "?dict=#{base64}".gsub('%0A', '')
  end

  unless attr['cond'].nil?
    prefix = fk.nil? ? '?' : '&'
    base64 = CGI.escape(Base64.encode64(attr['cond']))
    cond = "#{prefix}cond=#{base64}".gsub('%0A', '')
  end

  unless attr['sub'].nil?
    prefix = prefix.nil? ? '?' : '&'
    base64 = CGI.escape(Base64.encode64(attr['sub']))
    sub = "#{prefix}sub=#{base64}".gsub('%0A', '')
  end
  str_url = nil
  if attr['url'] != nil
    if attr['url'].index('/matrix') == nil
      str_url = C['apihost'] + attr['url']
    else
      str_url = attr['url']
    end
  end
  url = str_url || "/matrix/q/#{attr['model']}#{fk}#{cond}#{sub}"

  return '' if name.nil? || name == ''
  # p "url===>" + url
  tu = TableUtil.new
  tu.element_id = name
  tu.data_url = url

  tbl = tu.make_table(name)

  toolbar_id = gen_id
  tu.toolbar_id = "toolbar_#{toolbar_id}"

  edit_del_id = gen_id
  if opt[:cols].nil?
    cols = tu.gen_cols("edit_del_#{edit_del_id}").to_json.to_parsed
  else
    cols = "[[#{opt[:cols].gsub('##id##', edit_del_id).to_parsed}]]"
  end
  toolbar_block = script_block("toolbar_#{toolbar_id}", table_toolbar(opt[:toolbar]))
  edit_delete_block = script_block("edit_del_#{edit_del_id}", col_edit_del(opt))
  no_edit_delete_block = script_block("no_edit_del_#{edit_del_id}", opt[:colbtn])
  block = reg_block(edit_delete_block + no_edit_delete_block + toolbar_block + opt[:templets])
  opt[:del] = nil if opt[:del] == ''
  opt[:disable] = nil if opt[:disable] == ''

  del = opt[:del] || <<~EOF
    window.remove = function (obj) {
      layer.confirm('确定要删除该记录吗?', {
        icon: 3,
        title: '提示'
      }, function (index) {
        layer.close(index);
        let loading = layer.load();
        $.ajax({
          url: "/matrix/q/#{attr['model'] || name}/del/" + obj.data._id,
          dataType: 'json',
          type: 'delete',
          success: function (result) {
            layer.close(loading);
            if (result.code == 0) {
              layer.msg(result.msg, {
                icon: 1,
                time: 1000
              }, function () {
                obj.del();
              });
            } else {
              layer.msg(result.msg, {
                icon: 2,
                time: 1000
              });
            }
          }
        })
      });
    }
  EOF

  disable_url = opt[:disable] || "'/matrix/q/#{attr['model'] || name}/disable/' + obj.data._id"

  disable = <<~EOF
    window.disable = function(obj) {
      layer.confirm('确定要操作该记录吗?', {
        icon: 3,
        title: '提示'
      }, function (index) {
        layer.close(index);
        let loading = layer.load();
        $.ajax({
          url: #{disable_url},
          dataType: 'json',
          type: 'post',
          success: function (result) {
            layer.close(loading);
            if (result.code == 0) {
              layer.msg(result.msg, {
                icon: 1,
                time: 1000
              }, function () {
                table.reload(obj.__table_name, {url: obj.__table_url, where: obj.field});
              });
            } else {
              layer.msg(result.msg, {
                icon: 2,
                time: 1000
              });
            }
          }
        })
      });
    }
  EOF

  cols_str = <<-EOF
    #{block}
    var cols = #{cols};
    table.render(#{tu.gen_script_body});

    table.on('tool(#{name})', function (obj) {
      obj.__table_name = '#{name}';
      obj.__table_url = '#{url}';
      if (obj.event === 'del') {
        window.remove(obj);
      } else if (obj.event === 'edit') {
        window.edit(obj);
      } else if (obj.event === 'disable') {
         window.disable(obj);
      } else {
          console.log(obj.event);
        if(window[obj.event] !== undefined) {
          window[obj.event](obj);
        }
      }
      
    });

    table.on('toolbar(#{name})', function(obj) {
      if (obj.event === 'add') {
        window.add();
      } else if (obj.event === 'refresh') {
        window.refresh();
      } else if (obj.event === 'batchRemove') {
        window.batchRemove(obj);
      } else {
          console.log(obj.event);
        if(window[obj.event] !== undefined) {
          window[obj.event](obj);
        }
      }
    });

    #{opt[:add]}
    #{opt[:edit]}
    #{del}
    #{disable}

    form.on('switch', function (obj) {
        $.ajax({
                url: '/matrix/q/#{name}/switch/'+ obj.value,
                data: JSON.stringify({checked: obj.elem.checked}),
                dataType: 'json',
                contentType: 'application/json',
                type: 'post',
                success: function(result) {
                  
                }
        });
    });

    form.on('submit(top-query)', function(obj) {
      table.reload('#{name}', {url: '#{url}', where: obj.field})
      _attachdp();
    })

    form.on('checkbox', function(obj) {
      let _id = obj.elem.dataset.id;
      let field = obj.elem.name;
      let f = table.cache['#{name}'].find((f)=>f._id == _id);
      f[field] = obj.elem.checked;
    })
  EOF
end

def table_col(opt, content)
  optstr = opt.to_json
  opt[:align] = 'center'
  if opt['type'].nil?
    opt['width'] = '120' if opt['width'].nil?
    optstr = opt.to_json.gsub(/"(function.+?)"/,'\1')
    out = <<~EOF
      @col
        #{optstr}
      @/col
    EOF
  else
    if opt['type'] == 'op'
      struct = {
        title: "操作",
        toolbar: opt['custom'] == 'true' ? "#no_edit_del_##id##" : "#edit_del_##id##",
        align: "left",
        width: opt['width'] || '220',
        fixed: "right"
      }
      out = <<~EOF
        @col
          #{struct.to_json}
        @/col

        #{content}
      EOF
    else
      opt[:templet] = "##{opt['type']}"
      case opt['type']
      when 'sex'
        opt['width'] = '90' if opt['width'].nil?
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
            <script type="text/html" id="#{opt[:templet][1..-1]}">
              {{#if (d.sex == 1) { }}
                <span>男</span>
                {{# }else if(d.sex == 2){ }}
                <span>女</span>
                {{# } }}
            </script>
          @/templet
        EOF
      when 'switch', 'sw'
        opt['width'] = '120' if opt['width'].nil?
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
            <script type="text/html" id="#{opt[:templet][1..-1]}">
                <input type="checkbox" name="#{opt['field']}" value="{{d._id}}" lay-skin="switch" lay-text="是|否" lay-filter="#{opt['field']}-enable" {{ d.#{opt['field']}== true||d.#{opt['field']}==1 ? 'checked' : '' }} />
            </script>
          @/templet
        EOF
      when 'img'
        opt['width'] = '120' if opt['width'].nil?
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
            <script type="text/html" id="#{opt[:templet][1..-1]}">
                <img src="{{d.#{opt['field']}}}" alt="" style="height:30px;" onclick="_previewImg(this)"/>
            </script>
          @/templet
        EOF
      when 'bool'
        opt['width'] = '90' if opt['width'].nil?
        enumarr = opt['enum']&.split(',')
        if enumarr.nil?
          str = "{{['否','是'][[false,true].indexOf(d." + opt['field'] + ")]|| '否'}}"
        else
          str = "{{[#{enumarr.map { |m| "'#{m}'" }.join(',')}][[false,true].indexOf(d." + opt['field'] + ")]|| ''}}"
        end
        opt[:templet] = "#{opt[:templet]}_#{gen_id}"
        opt[:event] = opt['event']
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
          <script type="text/html" id="#{opt[:templet][1..-1]}">  
            <button lay-id="11" type="button" class="layui-btn {{# if (d.#{opt['field']}) { }} tag-item layui-btn-primary  {{# } else { }} layui-btn-warm {{# } }}  layui-btn-xs">#{str}</button>
          </script>
          @/templet
        EOF
      when 'enum'
        opt['width'] = '90' if opt['width'].nil?
        enumarr = opt['enum']&.split(',')
        # if !!opt['field'] == opt['field']
        #   idx = [false, true].index(opt['field'])
        #   str = "{{[#{enumarr.map { |m| "'#{m}'" }.join(',')}].indexOf(d." + opt['field'] + ") || '#{enumarr[0]}'}}"
        # end
        if enumarr.nil?
          str = "{{d." + opt['field'] + "|| ''}}"
        else
          str = "{{[#{enumarr.map { |m| "'#{m}'" }.join(',')}][d." + opt['field'] + "] || '#{enumarr[0]}'}}"
        end
        opt[:templet] = "#{opt[:templet]}_#{gen_id}"
        opt[:event] = opt['event']
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
          <script type="text/html" id="#{opt[:templet][1..-1]}">
            <button lay-id="11" type="button" class="layui-btn {{['tag-item layui-btn-primary','layui-btn-normal','layui-btn-warm','layui-btn-danger'][d.#{opt['field']}%4]}} layui-btn-xs">#{str}</button>
          </script>
          @/templet
        EOF
      when 'date'
        opt['width'] = '110' if opt['width'].nil?
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
            <script type="text/html" id="#{opt[:templet][1..-1]}">
              {{layui.util.toDateString(d.#{opt['field']}, 'yyyy-MM-dd')}}
            </script>
          @/templet
        EOF
      when 'datetime'
        opt['width'] = '160' if opt['width'].nil? || opt['width'] == '120'
        opt[:templet] = "#{opt[:templet]}_#{gen_id}"
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
            <script type="text/html" id="#{opt[:templet][1..-1]}_#{gen_id}">
              {{_datetime(d.#{opt['field']}, 'yyyy-MM-dd hh:mm:ss')}}
            </script>
          @/templet
        EOF
      when 'daterange'

      when 'timerange'
      when 'templet'
        opt[:templet] = "#templet_#{gen_id}"

        out = <<~EOF
          @col
            #{opt.to_json}
          @/col

          @templet
            <script type="text/html" id="#{opt[:templet][1..-1]}">
                #{content}
            </script>
          @/templet
        EOF
      else
        out = <<~EOF
          @col
            #{opt.to_json}
          @/col
        EOF
      end
    end
  end
  unless opt['fk'].nil?
    out += <<~EOF
      @fk
        #{opt['fk']}
      @/fk
    EOF
  end
  unless opt['dict'].nil?
    out += <<~EOF
      @dict
        #{opt['dict']}
      @/dict
    EOF
  end
  out
end

def table_col_btn(opt)
  clk = ""
  unless opt['url'].nil?
    area = opt['area'].nil? ? "['900px', '700px']" : "[#{opt['area']}]"
    paramstr = get_params_colbtn(opt)
    paramstr = "''" if paramstr.nil? || paramstr == ''
    unless opt['url'].include?('?')
      opt['url'] += "?"
    end
    cmdstr = ''
    if opt['type'] == 'cmd'
      cmdstr = <<~EOF
        $.ajax({
          type:'post',
          url:'#{C['apihost']}#{opt['url']}' + #{paramstr},
          dataType:'json',
          success: function(msg) {
            if (msg.code === 0) {
              #{opt['cb']};
              layer.msg(msg.msg,
                {
                    icon: 1,
                    offset: 'rt',
                    anim: 6,
                    time: 3000,
                    skin: 'layui-bg-green'
                },
                function() {
                  
                });
            } else {
              layer.msg(msg.msg,{
                    icon: 2,
                    offset: 'rt',
                    anim: 6,
                    time: 3000,
                    skin: 'layui-bg-red'
                },
                function() {
                  #{opt['cb']};
              });
            }
          }
        })
      EOF
    else
      urlstr = opt['url'] #opt['url'].include?('/matrix') ? opt['url'] : _C['apihost'] + opt['url']
      cmdstr = "_openurl('#{opt['title']}',#{area},'#{urlstr}')"
    end

    if opt['confirm'] == "true"
      string = "layer.confirm('您确定要执行该操作吗?', {icon: 3,title: '提示'}, function (index) {#{cmdstr}})"
      clk = string
    else
      clk = cmdstr
    end
  end
  ifstr, ifstr2 = '', ''
  unless opt['if'].nil?
    ifstr = "{{# if(#{opt['if']}) { }}"
    ifstr2 = "{{# } }}"
  end
  <<~EOF
    @colbtn
    #{ifstr}
    <a class="layui-btn layui-btn-xs #{opt['style'] || 'layui-btn-normal'}" lay-event="#{opt['evt']}" onclick="#{clk}">#{opt['title']}</a>
    #{ifstr2}
    @/colbtn
  EOF
end

def get_custom_cols(content)
  # arr = content.scan(/@col[\s]*(.+)?[\s]*@\/col/)
  arr = content.fetch_token('col')
  arr.map do |e|
    e[0]
  end
  arr.join(',')
end

def get_custom_cols_templets(content)
  # arr = content.scan(/@templet[\s]*(.+)?[\s]*@\/templet/)
  arr = content.fetch_token('templet')
  arr.map do |e|
    e[0]
  end
  arr.join("\n")
end

def get_cols_btn(content)
  arr = content.fetch_token('colbtn')
  arr.map do |e|
    e[0]
  end
  arr.join("\n")
end

def get_table_add(content)
  # arr = content.scan(/@add[\s]*(.+)?[\s]*@\/add/m)
  arr = content.fetch_token('add')
  arr.join("\n")
end

def get_table_edit(content)
  # arr = content.scan(/@edit[\s]*(.+)?[\s]*@\/edit/m)
  arr = content.fetch_token('edit')
  arr.join("\n")
end

def get_table_del(content)
  # arr = content.scan(/@del[\s]*(.+)?[\s]*@\/del/m)
  arr = content.fetch_token('del')
  arr.join("\n")
end

def get_table_disable(content)
  arr = content.fetch_token('disable')
  arr.join("\n")
end

def get_table_fk(content)
  arr = content.fetch_token('fk')
  arr.join('')
end

def get_table_dict(content)
  arr = content.fetch_token('dict')
  arr.join('')
end

def get_table_toolbar(content)
  arr = content.fetch_token('table_toolbar')
  arr.join('')
end

def get_table_seearch_script_date(content)
  arr = content.fetch_token('script_date')
  # content.gsub!(/@script_date.+?@\/script_date/m, '')
  arr.join("\n")
end

def col_edit_del(opt)
  out = <<~EOF
    <a class="layui-btn layui-btn-xs" lay-event="edit">编辑</a>
    {{# if(d.enabled || d.enabled != undefined) { }}<a class="layui-btn layui-btn-xs" lay-event="disable">禁用</a> {{# } else { }} <a class="layui-btn layui-btn-xs" lay-event="disable">启用</a> {{# } }}
    <a class="layui-btn layui-btn-danger layui-btn-xs" lay-event="del">删除</a>
    #{opt[:colbtn]}
  EOF
end

def table_toolbar(toolbar)
  #p toolbar
  if toolbar.length > 0
    out = <<~EOF
      #{toolbar}
    EOF
  else
    out = <<~EOF
      <button class="pear-btn pear-btn-primary pear-btn-md" lay-event="add">
        <i class="layui-icon layui-icon-add-1"></i>
        新增
      </button>
      <button class="pear-btn pear-btn-danger pear-btn-md" lay-event="batchRemove">
        <i class="layui-icon layui-icon-delete"></i>
        删除
      </button>
    EOF
  end
  out
end

def table_toolbar_custom(opt, content)
  out = <<~EOF
    @table_toolbar
    #{content}
    @/table_toolbar
  EOF
end

def table_add(opt, content)
  area = opt['area'] || "'900px', '700px'"
  paramstr = get_params(opt)
  paramstr = "''" if paramstr.nil? || paramstr == ''
  if content.nil? || content == ""
    cnt = paramstr.nil? ? "'#{opt['url']}'" : "'#{opt['url']}?'+#{paramstr}"
    out = <<~EOF
      @add
      window.add = function() {
        layer.open({
          type: 2,
          title: '新增',
          shade: 0.1,
          area: [#{area}],
          content: #{cnt}
        });
      }
      @/add
    EOF
  else
    out = <<~EOF
      @add
      window.add = function() {
        #{content}
      }
      @/add
    EOF
  end
end

def table_edit(opt)
  area = opt['area'] || "'900px', '700px'"
  params = opt['params']
  if params.nil?
    str = "'#{opt['url']}?_id=' + obj.data._id"
  else
    ar_params = params.split('=')
    str = "'#{opt['url']}?#{ar_params[0]}=' + obj.data.#{ar_params[1]}"
  end
  out = <<~EOF
    @edit
    window.edit = function (obj) {
      layer.open({
        type: 2,
        title: '修改',
        shade: 0.1,
        area: [#{area}],
        content: #{str}
      });
    }
    @/edit
  EOF
end

def table_del(opt)
  # paramstr = get_params(opt)
  # cnt = paramstr.nil? ? "'#{opt['url']}'" : "'#{opt['url']}?'+#{paramstr}"
  params = opt['params']
  if params.nil?
    str = "'#{opt['url']}?_id=' + obj.data._id"
  else
    ar_params = params.split('=')
    str = "'#{opt['url']}?#{ar_params[0]}=' + obj.data.#{ar_params[1]}"
  end

  url = !opt['url'].nil? ? str : "'/matrix/q/##table_name##/del/'+obj.data._id"
  out = <<~EOF
    @del
    window.remove = function (obj) {
      _itemremove(#{url}, ()=>{obj.del();})
    }
    @/del
  EOF
end

def table_disable(opt)
  url = !opt['url'].nil? ? "'#{opt['url']}?_id='+obj.data._id" : "'/matrix/q/##table_name##/disable/'+obj.data._id"
  out = <<~EOF
    @disable
      #{url}
    @/disable
  EOF
  # window.disable = function (obj) {
  #   _disable(#{url}, ()=>{obj.disable();})
  # }
end