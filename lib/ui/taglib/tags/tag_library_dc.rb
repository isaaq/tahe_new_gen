class TagLibraryDC < Tags::TagLibrary
  prefix :'dc'
  tag "webpart" do |t|
    %{123}
  end
  tag 'ds' do |t|
    type = t.attr['type'] || 'get'
    bind = t.attr['bind'] || 'ds_' + SecureRandom.base64(8).gsub("/","_").gsub(/=+$/,"")
    url = t.attr['url'] || ''
    <<-EOF
    @mounted axios.#{type}('#{url}').then(response=>(this.#{bind}=response.data))
    EOF
  end
  tag 'dp' do |t|
    <<-EOF
    <el-date-picker
      v-model="#{t.attr['bind']}"
      type="date"
      placeholder="选择日期">
    </el-date-picker>
    @data #{t.attr['bind']}:'#{t.attr['value']}'
    EOF
  end
  tag 'am' do |t|
    <<-EOF
    <el-input
      placeholder="保存后自动生成"
      :disabled="true">
    </el-input>
    EOF
  end
  tag 'in' do |t|
    bind = t.attr['bind'] || "text_#{SecureRandom.base64(8).gsub("/","_").gsub(/=+$/,"")}"
    <<-EOF
      <el-input v-model="#{bind}" placeholder="请输入内容"></el-input>
      @data #{bind}:'#{t.attr['value']}'
    EOF
  end
  tag 'ta' do |t|
    <<-EOF
    <el-input
      type="textarea"
      :rows="#{t.attr['rows']||3}"
      placeholder="请输入内容"
      v-model="#{t.attr['bind']}">
    </el-input>
    @data #{t.attr['bind']}:'#{t.attr['value']}'
    EOF
  end
  tag 'sl' do |t|
    datastr = t.attr['data']&.force_encoding('UTF-8')
    unless datastr.nil?
      data = []
      temp = datastr.split(',')
      unless datastr.include?(':')
        data = temp.map {|m| {value: m, label: m}}
      else
        data = temp.map {|m| ms=m.split(':');{value: ms[1], label: m[0]}}
      end
    end
    dsstr = t.attr['ds']
    unless dsstr.nil?

    end
    <<-EOF
    <el-select v-model="value" placeholder="请选择">
      <el-option
        v-for="item in #{t.attr['bind']}"
        :key="item.value"
        :label="item.label"
        :value="item.value">
      </el-option>
    </el-select>
    @data #{t.attr['bind']}:#{data.to_json||'""'}
    EOF
  end
  tag 'sd' do |t|
    <<-EOF
    <el-input
      placeholder="请输入内容"
      v-model="#{t.attr['bind']}">
      <i slot="prefix" class="el-input__icon el-icon-search"></i>
    </el-input>
    EOF
  end
  tag 'num' do |t|
    <<-EOF
      <el-input-number v-model="#{t.attr['bind']}" controls-position="right" @change="handleChange" :min="1" :max="10"></el-input-number>
    EOF
  end
  tag 'rmbup' do |t|
    <<-EOF
    <el-input
      placeholder="大写金额"
      :disabled="true">
    </el-input>
    EOF
  end
  tag '' do |t|
    
  end
end
