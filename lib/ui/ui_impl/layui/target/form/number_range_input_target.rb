# frozen_string_literal: true

class NumberRangeInputTarget < InputTarget
  def elename
    'number_range_input'
  end

  def output_target
    attr = tag.attributes
    # 生成数字范围的前端代码
    id = attr['id'] || gen_id
    name = attr['name']
    name = SecureRandom.uuid if name.empty?

    lbl = attr['lbl'] || ''
    min_name = "#{name}_min"
    max_name = "#{name}_max"
    min_value = attr['min_value'] || ''
    max_value = attr['max_value'] || ''
    
    # 生成完整的HTML和JavaScript
    <<~HTML
      <div class="layui-form-item" id="number_range_container_#{id}" data-field-name="#{name}">
        <label class="layui-form-label">#{lbl}</label>
        <div class="layui-input-block number-range-container">
          <input type="number" class="layui-input number-range-min" id="min_#{id}" name="#{min_name}" 
                 placeholder="最小值" value="#{min_value}" style="width:45%;display:inline-block;">
          <span class="number-range-separator" style="display:inline-block;width:10%;text-align:center;">至</span>
          <input type="number" class="layui-input number-range-max" id="max_#{id}" name="#{max_name}" 
                 placeholder="最大值" value="#{max_value}" style="width:45%;display:inline-block;">
          <input type="hidden" class="number-range-value" name="#{name}_range" id="#{name}_#{id}" value="[#{min_value},#{max_value}]" data-field-name="#{name}">
        </div>
      </div>
      
      <script>
      layui.use(['jquery'], function(){
        var $ = layui.jquery;
        
        // 初始化隐藏字段的值
        var min = $('#min_#{id}').val() || "";
        var max = $('#max_#{id}').val() || "";
        $('##{name}_#{id}').val(JSON.stringify([min, max]));
        console.log('Initialized field #{name}_range with:', JSON.stringify([min, max]));
        
        // 监听输入框的变化
        $('#min_#{id}, #max_#{id}').on('input change', function() {
          var min = $('#min_#{id}').val() || "";
          var max = $('#max_#{id}').val() || "";
          $('##{name}_#{id}').val(JSON.stringify([min, max]));
          console.log('Updated field #{name}_range with:', JSON.stringify([min, max]));
        });
      });
      </script>
    HTML
  end
end
