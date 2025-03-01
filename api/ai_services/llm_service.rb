require 'faraday'
require 'json'

class LLMService
  include Singleton
  
  def initialize
    @api_key = Common::C['llm_api_key']
    @api_endpoint = Common::C['llm_api_endpoint']
    @model = Common::C['llm_model'] || 'gpt-3.5-turbo'
  end

  def process(prompt)
    puts "开始处理 LLM 请求..."
    puts "API 端点: #{@api_endpoint}"
    puts "使用模型: #{@model}"
    
    conn = Faraday.new(url: @api_endpoint) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end

    request_body = {
      model: @model,
      messages: [{role: 'user', content: prompt}],
      temperature: 0.7,
      max_tokens: 2000
    }
    
    puts "发送请求体: #{request_body.inspect}"

    response = conn.post do |req|
      req.headers['Authorization'] = "Bearer #{@api_key}"
      req.headers['Content-Type'] = 'application/json'
      req.body = request_body.to_json
    end

    puts "API 响应状态: #{response.status}"
    puts "API 响应头: #{response.headers.inspect}"
    puts "API 响应体: #{response.body.inspect}"

    if response.status != 200
      raise "API 请求失败: #{response.status} - #{response.body.inspect}"
    end

    # 直接提取生成的代码内容
    if response.body['choices'] && response.body['choices'][0] && response.body['choices'][0]['message'] && response.body['choices'][0]['message']['content']
      code = response.body['choices'][0]['message']['content']
      puts "成功提取代码内容"
    else
      error_msg = "无法提取生成的代码，响应格式不正确: #{response.body.inspect}"
      puts error_msg
      raise error_msg
    end

    handle_response(code)
  rescue => e
    puts "处理过程中发生错误: #{e.message}"
    puts "错误堆栈: #{e.backtrace.join("\n")}"
    {error: e.message, status: 'error'}
  end

  private

  def handle_response(code)
    {
      result: code,
      status: 'success'
    }
  end
end
