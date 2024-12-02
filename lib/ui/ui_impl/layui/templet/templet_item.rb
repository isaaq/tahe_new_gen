# frozen_string_literal: true

class TempletItem

  attr_accessor :id, :content

  ##
  # <td title="{{d.introduce}}" class="layui-table-link">{{d.name}}</td>
  def output
    <<~OUTPUT
     <script type="text/html" id="#{@id}">
        #{@content}
     </script>
    OUTPUT
  end

  def self.from_db(name)
    templet = M[:sys_ui_layui_templet].query(name: name).to_a[0]
    @content = templet[:content]
    @id = "templet_#{gen_id}"
    output
  end
end
