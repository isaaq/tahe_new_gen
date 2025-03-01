class TaheController < ApiController
  get '/sys/funcs/:id' do
    f = M[:_脚本].query(_id: _params[:id]).to_a
    f.to_resp
  end

  # 新增：根据自然语言生成并执行查询
  post '/sys/generate_and_execute' do
    content_type :json
    begin
      body = JSON.parse(request.body.read)
      puts "请求体: #{body.inspect}"
      
      # 使用代码生成器解析自然语言查询
      generator = CodeGeneratorParser.new
      result = generator.parse({
        'content' => body['query'],
        '_meta' => {
          'parser' => 'code_generator',
          'type' => 'query'
        }
      })
      puts "生成的结果: #{result.inspect}"
      
      # 保存生成的代码
      script_id = save_generated_script(result)
      
      # 从正确的位置获取代码'

      code_to_execute = result[:script_record] && result[:script_record][:content]
      puts "要执行的代码: #{code_to_execute.inspect}"
      
      # 执行生成的代码
      execute_result = execute_generated_code(code_to_execute)
      
      {
        status: 'success',
        script_id: script_id,
        execution_plan: result['execution_plan'],
        result: execute_result
      }.to_json
    rescue => e
      puts "错误: #{e.message}"
      puts "错误堆栈: #{e.backtrace.join("\n")}"
      status 500
      {
        status: 'error',
        error: e.message
      }.to_json
    end
  end

  private

  def save_generated_script(result)
    script = {
      name: "generated_#{Time.now.to_i}",
      code: result['script_record'] && result['script_record'][:content],
      created_at: Time.now,
      execution_plan: result['execution_plan'],
      type: 'query'
    }
    
    # 使用正确的添加方法
    M[:_脚本].add(script)
    script[:_id].to_s
  end

  def execute_generated_code(code)
    return nil if code.nil?
    
    # 确保代码是字符串
    unless code.is_a?(String)
      raise "无效的代码格式: #{code.class}"
    end
    
    # 检查是否是路由定义
    if code.match?(/get ['"]([^'"]+)['"] do/)
      # 提取路由处理逻辑
      route_code = code.match(/get ['"]([^'"]+)['"] do(.*?)^    end/m)
      raise "无法解析路由代码" unless route_code
      
      route_path = route_code[1]
      route_handler = route_code[2].strip
      
      # 提取并定义辅助方法
      helper_methods = code.scan(/def ([^\n]+)(.*?)^    end/m)
      helper_methods.each do |method_name, method_body|
        clean_body = method_body.gsub(/^      /, '').strip
        self.class.class_eval <<-RUBY
          def #{method_name.strip}
            #{clean_body}
          end
        RUBY
      end
      
      # 注册路由
      self.class.class_eval <<-RUBY
        get '#{route_path}' do
          content_type :json
          result = begin
            #{route_handler}
          end
          result.to_json
        end
      RUBY
    else
      # 直接执行代码
      # 提取并定义辅助方法
      helper_methods = code.scan(/def ([^\n]+)(.*?)^    end/m)
      helper_methods.each do |method_name, method_body|
        clean_body = method_body.gsub(/^      /, '').strip
        self.class.class_eval <<-RUBY
          def #{method_name.strip}
            #{clean_body}
          end
        RUBY
      end
      
      # 执行主要代码逻辑
      main_code = code.sub(/^(def .+?^    end\n*)+/m, '')  # 移除所有辅助方法定义
      instance_eval(main_code)
    end
  end
end
