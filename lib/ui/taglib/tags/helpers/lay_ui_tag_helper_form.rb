def form_block(content)
  out = <<-EOF
      <div class="layui-form-item">
        #{content}
      </div>
  EOF
end

def input(opt)
  ac = opt['ac'].nil? ? 'off' : opt['ac']
  ver = opt['ver'].nil? ? '' : opt['ver']
  if opt['lbl'].nil?
    input = <<~EOF
      <input type="text" name="#{opt['name']}" lay-verify="#{ver}" autocomplete="#{ac}" placeholder="#{opt['ph']}" class="layui-input" value="#{opt['value']}">
    EOF
  else
    input = <<~EOF
      <label class="layui-form-label">#{opt['lbl']}</label>
      <div class="layui-input-block">
        <input type="text" name="#{opt['name']}" lay-verify="#{ver}" autocomplete="#{ac}" placeholder="#{opt['ph']}" class="layui-input" value="#{opt['value']}">
      </div>
    EOF
    form_block(input)
  end
end

def tag_date(opt)
  id = gen_id
  out = <<~EOF
    @layui_script
    laydate.render({
      elem: '#date_#{id}',
      format: 'yyyy-MM-dd HH:mm:ss'
    });
    @/layui_script

    <label class="layui-form-label">#{opt['lbl']}</label>
    <div class="layui-input-block">
      <input type="text" class="layui-input" id="date_#{id}" name="#{opt['name']}">
    </div>
  EOF
end

def tag_radio(opt)
  enums = opt['enum'].split(',')
  input_str = ''
  enums.each do |e|
    arr = e.split(':')
    input_str += "<input type=\"radio\" name=\"#{opt['name']}\" value=\"#{arr[1]}\" title=\"#{arr[0]}\">"
  end
  out = <<~EOF
     <label class="layui-form-label">#{opt['lbl']}</label>
        <div class="layui-input-block">
        #{input_str}
    </div>
  EOF
end

def tag_textarea(opt, content)
  out = <<~EOF
    <label class="layui-form-label">#{opt['lbl']}</label>
     <div class="layui-input-block">
       <textarea name="#{opt['name']}" placeholder="请输入" class="layui-textarea"></textarea>
     </div>
  EOF
end

def tag_formbtn(opt, content)
  out = <<~EOF
    @formbtn
    #{content}
    @/formbtn
  EOF
end

def label(opt)
  out = <<~EOF
    <label class="layui-form-label">#{opt['lbl']}</label>
    <div class="layui-input-block">
      <input type="text" class="layui-label" name="#{opt['name']}" disabled="disabled" />
    </div>
  EOF
end

def sel(opt)
  optstr = make_option(opt)

  out = <<~EOF
    <label class="layui-form-label">#{opt['lbl']}</label>
    <div class="layui-input-block">
      <select name="#{opt['name']}" lay-verify="">
        <option value="">请选择</option>
        #{optstr}
      </select>
    </div>
  EOF
  form_block(out)
end

def switch(opt)
  out = <<~EOF
    @edit_script
    form.on('switch(sw_#{opt['name']})', function(data){
        let val = this.checked ? 'true' : 'false';
        $("input[name='#{opt['name']}']").attr("value",val);
    });
    let counter = 0;
    _spin(() => {
      counter ++;
      if(layui.form.val('').#{opt['name']} == '1' || layui.form.val('').#{opt['name']} == 'on' || layui.form.val('').#{opt['name']} == 'true') {
        _spin(() => {
          $('#sw_#{opt['name']}').attr( "checked", true);
          return true;
        });
        return counter > 5;
      }
      else {
        return counter > 5;
      }
    });
    
    @/edit_script

    <label class="layui-form-label">#{opt['lbl']}</label>
    <div class="layui-input-block">
      <input type="hidden" name="#{opt['name']}" />
      <input type="checkbox" id="sw_#{opt['name']}" name="sw_#{opt['name']}" lay-skin="switch" lay-filter="sw_#{opt['name']}"/>
    </div>
  EOF
  form_block(out)
end

def dtree(opt, evt)
  tree_id = opt['bind_id']
  url = opt['url']
  # toolbar = opt['toolbar']
  btns = opt['btns']
  toolbar_str = ''
  unless btns.nil?
    toolbar_str = <<~EOF
      toolbar: true,
      toolbarWay: "follow",
      toolbarShow: [],
      toolbarExt: #{btns},
    EOF
  end
  out = <<~EOF
    layui.use(['dtree'], function () {
      dtree = layui.dtree;

      dtree.render({
          elem: "##{tree_id}",
          initLevel: "1",
          method: 'post',
          url: "#{url}",
          #{toolbar_str}
        });
      #{evt}
    });
  EOF
end

def item_click(content)
  out = <<~EOF
    dtree.on("node('tree')" ,function(obj) {
      #{content}
    });
  EOF
end

def form(opt, content)
  cb = get_form_cb(content) || ''
  data = get_form_data(content) || 'data.field'
  edit_script = get_form_edit_script(content)
  id = opt['id']
  strid = "id=\"#{id}\""
  params = Util.find_var('@params')
  paramid = params[:_id] || ''
  env = Util.find_var('@env')
  params = env['rack.request.query_hash']
  params_str = params.inject('?') { |t,i| t += i[0] + '=' + i[1] + '&'}

  formbtn = content.fetch_token('formbtn')
  content.gsub!(/@formbtn[\s]*(.+)?[\s]*@\/formbtn/m, '')
  formbtn_str = ''
  formbtn.each do |btn|
    formbtn_str += <<~EOF
        <button type="button" class="pear-btn pear-btn-sm" lay-submit=""
      lay-filter="">
          <i class="layui-icon layui-icon"></i>#{btn}
        </button>
    EOF
  end

  # TODO 这里能优化 变成约定俗成模式
  if opt['tbl'].nil?
    submit_url = (opt['submit'] || '') + "?_id=" + paramid
    get_url = opt['get'] + params_str if opt['type'] == "edit" || opt['type'] == "show" #"?_id=" + paramid
  else
    submit_url = "/matrix/q/#{opt['tbl']}/save?_id=" + paramid
    get_url = "/matrix/q/#{opt['tbl']}/#{paramid}/get"
  end

  no_submit = opt['submit'].nil? && opt['tbl'].nil?

  if opt['type'] == "edit" || opt['type'] == "show"
    edit_code = <<~EOF
      var _id = _getUrlParam('_id');

      $.ajax({
        url: '#{get_url}',
        dataType: 'json',
        contentType: 'application/json',
        type: 'post',
        success: function(result) {
          _filter_data(result.data);
          form.val('#{id}', result.data);
          if(typeof(oneditget) != 'undefined')
            oneditget(result.data);
        }
      })

    EOF
  end
  submit_str = <<~EOF
    form.on('submit(save)', function(data) {
      let json = #{data};
    
      $.ajax({
          url: '#{submit_url}',
          data: JSON.stringify(json),
          dataType: 'json',
          contentType: 'application/json',
          type: 'post',
          success: function(result) {
              if (result.code==0) {
                  layer.msg(result.msg, {
                      icon: 1,
                      time: 1000
                  }, function() {
                      parent.layer.close(parent.layer.getFrameIndex(window
                          .name)); //关闭当前页
                      #{cb}
                  });
              } else {
                  layer.msg(result.msg, {
                      icon: 2,
                      time: 1000
                  });
              }
          }
      })
      return false;
    });
  EOF
  if no_submit
    submit_str = <<~EOF
      form.on('submit(save)', function(data) {
        let json = #{data};
        #{cb}
      });
    EOF
  end
  btns = <<~EOF
    <div class="button-container">
      #{formbtn_str}
      <button type="submit" class="pear-btn pear-btn-primary pear-btn-sm" lay-submit=""
              lay-filter="save">
        <i class="layui-icon layui-icon-ok"></i>
        提交
      </button>
      <button type="reset" class="pear-btn pear-btn-sm">
        <i class="layui-icon layui-icon-refresh"></i>
        重置
      </button>
    </div>
  EOF
  btns = '' if opt['type'] == 'show'
  out = <<~EOF
      <form #{strid} class="layui-form" action="" lay-filter="#{id}">
        <div class="mainBox">
          <div class="main-container">
            #{content}
          </div>
        </div>

        <div class="bottom">
          #{btns}
        </div>
      </form>

      <script src="/matrix/templates/pear/component/layui/layui.js"></script>
      <script src="/matrix/templates/pear/component/pear/pear.js"></script>
      <script>
        layui.use(['form', 'jquery', 'laydate'], function() {
          let form = layui.form;
          let laydate = layui.laydate;
          let $ = layui.jquery;
          let element = layui.element;

          @layui_block
          @/layui_block

          #{edit_code}

          #{edit_script}

          #{submit_str}
        })
    </script>

  EOF
end

def form_data(opt, content)
  <<~EOF
    @formdata
     #{content}
    @/formdata
  EOF
end

def form_cb(opt, content)
  <<~EOF
    @cb
    #{content}
    @/cb
  EOF
end

def get_form_cb(content)
  arr = content.scan(/@cb[\s]*(.+)?[\s]*@\/cb/m)
  content.gsub!(/@cb[\s]*(.+)?[\s]*@\/cb/m, '')
  arr[0][0] if arr.length > 0
end

def get_form_data(content)
  arr = content.scan(/@formdata[\s]*(.+)?[\s]*@\/formdata/m)
  content.gsub!(/@formdata[\s]*(.+)?[\s]*@\/formdata/m, '')
  arr[0][0] if arr.length > 0
end

def get_form_edit_script(content)
  arr = content.fetch_token('edit_script')
  content.gsub!(/@edit_script.+?@\/edit_script/m, '')
  arr.join("\n")
end

def get_form_layui_script(content)
  arr = content.fetch_token('layui_script')
  content.gsub!(/@layui_script.+?@\/layui_script/m, '')
  arr.join("\n")
end