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
      puts "Request body: #{body.inspect}"  # 添加请求日志
      
      # 使用代码生成器解析自然语言查询
      generator = CodeGeneratorParser.new
      result = generator.parse({
        'content' => body['query'],
        '_meta' => {
          'parser' => 'code_generator',
          'type' => 'query'
        }
      })
      puts "Generated code: #{result.inspect}"  # 添加生成代码日志
      
      # 保存生成的代码
      script_id = save_generated_script(result)
      
      # 执行生成的代码
      execute_result = execute_generated_code(result['generated_code'])
      
      {
        status: 'success',
        script_id: script_id,
        execution_plan: result['execution_plan'],
        result: execute_result
      }.to_json
    rescue => e
      puts "Error: #{e.message}"  # 添加错误日志
      puts "Backtrace: #{e.backtrace.join("\n")}"  # 添加错误堆栈
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
      code: result['generated_code'],
      created_at: Time.now,
      execution_plan: result['execution_plan'],
      type: 'query'
    }
    
    # 使用正确的添加方法
    M[:_脚本].add(script)
    script[:_id].to_s
  end

  def execute_generated_code(code)
    # 在安全的环境中执行生成的代码
    # TODO: 添加更多的安全检查
    eval(code)
  rescue => e
    raise "执行生成的代码时出错: #{e.message}"
  end
end
