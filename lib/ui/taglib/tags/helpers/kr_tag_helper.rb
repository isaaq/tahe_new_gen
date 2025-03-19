# frozen_string_literal: true

require_relative 'lay_ui_tag_helper_form'
require 'securerandom'

module KrTagHelper
  include TagHelper

  def self.extended(base)
    # p base
    # p base.instance_variable_get(:@tag_prefix)
  end
  
  # 生成唯一ID
  def gen_id
    SecureRandom.base64(8).gsub("/", "_").gsub(/[=+$]/, "")
  end
  
  # 数字范围输入控件
  def number_range_input(opt)
    id = gen_id
    min_name = "#{opt['name']}_min"
    max_name = "#{opt['name']}_max"
    
    min_value = opt['min_value'] || ''
    max_value = opt['max_value'] || ''
    
    out = <<~EOF
      <label class="layui-form-label">#{opt['lbl']}</label>
      <div class="layui-input-block number-range-container">
        <input type="number" class="layui-input number-range-min" id="min_#{id}" name="#{min_name}" 
               placeholder="最小值" value="#{min_value}" style="width:45%;display:inline-block;">
        <span class="number-range-separator" style="display:inline-block;width:10%;text-align:center;">至</span>
        <input type="number" class="layui-input number-range-max" id="max_#{id}" name="#{max_name}" 
               placeholder="最大值" value="#{max_value}" style="width:45%;display:inline-block;">
        <input type="hidden" name="#{opt['name']}" id="#{opt['name']}_#{id}" value="[#{min_value},#{max_value}]">
      </div>
      
      @layui_script
      layui.use(['jquery'], function(){
        var $ = layui.jquery;
        $('#min_#{id}, #max_#{id}').on('change', function() {
          var min = $('#min_#{id}').val() || null;
          var max = $('#max_#{id}').val() || null;
          $('##{opt['name']}_#{id}').val(JSON.stringify([min, max]));
        });
      });
      @/layui_script
    EOF
    
    form_block(out)
  end
end
