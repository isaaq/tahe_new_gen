class Object
  def to_parsed
    self.gsub('"##', '').gsub('##"', '').gsub('\"', '"')
  end

  def fetch_token(name)
    lastidx = 0
    arr = []
    loop do
      lastidx = self.index("@#{name}\n", lastidx)
      break if lastidx.nil?
      lastidx2 = self.index("@/#{name}", lastidx)
      arr << self[lastidx..(lastidx2 + name.size + 1)].gsub("@#{name}", '').gsub("@/#{name}", '')
      lastidx = lastidx2
    end
    arr
  end
end

module LayUITagHelper
  include TagHelper

  def self.extended(base)
    # p base
  end

  # def _C
  #   Util.find_var('@_C')
  # end
  def reg_block(content)
    out = <<-EOF
    @script_block
    #{content}
    @/script_block
    EOF
  end

  require_relative 'lay_ui_tag_helper_table'
  require_relative 'lay_ui_tag_helper_form'

  def layui(content)
    out = <<-EOF
    <script src="../templates/pear/component/layui/layui.js"></script>
		<script src="../templates/pear/component/pear/pear.js"></script>
		<script>
      

			layui.use(['table', 'form', 'jquery', 'drawer', 'dropdown', 'element', 'laytpl', 'laydate'], function() {
				let table = layui.table;
				let form = layui.form;
				let $ = layui.jquery;
				let drawer = layui.drawer;
				let dropdown = layui.dropdown;
        let element = layui.element;
        let laytpl = layui.laytpl;
        let laydate = layui.laydate;
        _pagedata.window_name = window.name;

        @layui_block
        @/layui_block
        
        #{content}
      })
		</script>
    EOF
  end

  def tab(opt, content)
    titles = content.fetch_token('tab_item_title')
    titles_str = ''
    first = ''
    selflag = false
    selindex = 0
    titles.each_with_index do |e, i|
      temp = e.split(',')
      if temp.length > 2
        selflag = true
        selindex = i
      end
    end

    titles.each_with_index do |e, i|
      idstr = ''
      selstr = ''
      sel = nil
      if e.include?(',')
        temp = e.split(',')
        id = temp[1]
        e = temp[0]
        sel = temp[2] if temp.length >= 2
        idstr = "lay-id=\"#{id}\""
      end
      unless selflag
        first = i == 0 ? "class=\"layui-this\"" : ""
      end
      selstr = "class=\"layui-this\"" unless sel.nil?
      titles_str += "<li #{first} #{idstr} #{selstr}>#{e}</li>"

    end

    contents = content.fetch_token('tab_item_content')
    contents_str = ''
    first2 = ''
    contents.each_with_index do |e, i|
      unless selflag
        first2 = i == 0 ? "layui-show" : ""
      end
      showstr = i == selindex ? "layui-show" : ""
      contents_str += "<div class=\"layui-tab-item #{first2} #{showstr}\">#{e}</div>"
    end
    filter = opt['filter']
    filterstr = filter.nil? || filter == '' ? '' : "lay-filter=\"#{opt['filter']}\""
    scriptstr = ''
    if filterstr != ''
      scriptstr = <<~EOF
        @layui_script
          let layid = location.hash.replace(/^#tabsel=/, '');
          element.tabChange('#{filter}', layid); 
          element.on('tab(#{filter})', function(){
            location.hash = 'tabsel='+ this.getAttribute('lay-id');
            console.log('on tab' + location.hash)
            try {
              window.tab(this.getAttribute('lay-id'));
            } catch {}
          });
        @/layui_script
      EOF
    end
    id = opt['id']
    out = <<~EOF
      #{scriptstr}
      <div id="#{id}" class="layui-tab layui-tab-card" #{filterstr}>
        <ul class="layui-tab-title">
          #{titles_str}
        </ul>
        <div class="layui-tab-content" style="height: 100%;">
          #{contents_str}
        </div>
      </div>
    EOF
  end

  def tab_item(opt, content)
    layid = opt['id']
    idstr = layid.nil? ? '' : ",#{layid}"
    sel = opt['sel'].nil? ? '' : ",#{opt['sel']}"
    out = <<~EOF
      @tab_item_title
        #{opt['lbl']}#{idstr}#{sel}
      @/tab_item_title

      @tab_item_content
        #{content}
      @/tab_item_content
    EOF
  end

  def gen_id
    SecureRandom.base64(8).gsub("/", "_").gsub(/[=+$]/, "")
  end

  def script_block(id, content)
    out = <<-EOF
      <script type="text/html" id="#{id}">
        #{content}
      </script>
    EOF
  end

  def make_option(opt)
    fk = opt['fk']
    enum = opt['enum']
    optstr = ''
    unless fk.nil?
      arr = fk.split(',')
      _m_my_db = Util.find_var('@_m_my_db')
      h_cond = {}
      # TODO 编辑时态绑定
      # h_cond[arr[1].to_sym] = value

      list = _m_my_db[arr[0].to_sym].find().to_a
      optstr = list.map { |m| { _id: m[:_id], value: m[arr[2]] } }.inject('') { |t, i| t += "<option value=\"#{i[:_id]}\">#{i[:value]}</option>"; t }
    end
    unless enum.nil?
      arr = enum.split(',')
      bool_flag = !opt['type'].nil? ? opt['type'] == 'bool' : false
      optstr = arr.each_with_index.map { |m, i| { _id: bool_flag ? [false, true][i] : i, value: m } }.inject('') { |t, i| t += "<option value=\"#{i[:_id]}\">#{i[:value]}</option>"; t }
    end
    optstr
  end

  private

  def get_params(opt)
    paramstr = nil
    unless opt['params'].nil?
      params = opt['params'].split(',')
      paramstr = params.map do |m|
        args = m.split('=')
        "'#{args[0]}='+_pagedata.params.#{args[1]}"
      end.join('&')
    end
    paramstr
  end

  def get_params_colbtn(opt)
    paramstr = nil
    unless opt['params'].nil?
      params = opt['params'].split(',')
      paramstr = params.map do |m|
        args = m.split('=')
        "'#{args[0]}='+_getUrlParam('#{args[1]}')"
      end.join('&')
    end
    paramstr
  end
end
