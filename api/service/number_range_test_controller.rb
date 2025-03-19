# frozen_string_literal: true

require_relative "../../lib/ui/ui_page"
require_relative "../../lib/model/type/custom/number_range_field"

class TaheController < ApiController
  post "/test/number_range/save" do
    content_type :json
    
    # 获取表单数据
    data = params.to_h
    puts "Received data: #{data.inspect}"

    # 初始化结果对象
    result = { 
      original: {}, 
      processed: {},
      params: data 
    }
    
    # 遍历所有参数，处理以_range结尾的字段
    data.each do |key, value|
      if key.to_s.end_with?('_range')
        puts "Processing range field: #{key}, Value: #{value.inspect}"
        
        # 尝试解析JSON格式的数据
        begin
          if value.is_a?(String) && value.start_with?('[') && value.end_with?(']')
            parsed_value = JSON.parse(value)
            puts "  Parsed value: #{parsed_value.inspect}"
            
            # 存储原始数据
            result[:original][key] = parsed_value
            
            # 处理数字范围字段
            processed_data = {}
            NumberRangeField.process_data(processed_data, key, parsed_value)
            
            # 将处理后的数据添加到结果中
            result[:processed].merge!(processed_data)
          end
        rescue JSON::ParserError => e
          puts "  JSON parsing error: #{e.message}"
          result[:original][key] = value
        end
      end
    end

    # 返回结果
    result.to_json
  end

  get "/test/number_range" do
    content_type :html
    views_path = File.join(File.dirname(__FILE__), "../../views")
    erb_content = File.read(File.join(views_path, "number_range_test.erb"))
    parsed_content = UIPage.new(:kr).parse_code(erb_content)
    parsed_content = UIPage.new(:layui).parse_code(parsed_content)
    parsed_content
  end
end
