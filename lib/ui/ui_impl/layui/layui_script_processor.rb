# LayuiScriptProcessor 类用于处理 @layui_script 标记
# 将标记中的脚本内容添加到脚本池中
class LayuiScriptProcessor
  # 处理包含 @layui_script 标记的代码
  # 将标记中的脚本内容提取出来并添加到脚本池中
  def self.process(code, context)
    return code unless code.include?('@layui_script')
    
    # 初始化脚本池（如果不存在）
    # 首先确保 context 和 context.globals 存在
    if context && context.respond_to?(:globals) && context.globals
      # 初始化脚本池
      if !context.globals.respond_to?(:script_pool) || context.globals.script_pool.nil?
        context.globals.script_pool = {}
      end
    else
      # 如果 context 或 context.globals 不存在，直接返回原始代码
      return code
    end
    
    # 提取并处理所有 @layui_script 块
    code.gsub!(/@layui_script(.*?)@\/layui_script/m) do |match|
      script_content = $1.strip
      
      # 生成脚本的摘要作为键
      digest = script_content.hash.to_s
      
      # 如果脚本不存在于池中，则添加
      unless context.globals.script_pool.key?(digest)
        context.globals.script_pool[digest] = script_content
      end
      
      # 返回空字符串，移除原始标记
      ""
    end
    
    code
  end
  
  # 获取所有脚本内容
  def self.get_all_scripts(context)
    # 首先确保 context 和 context.globals 存在
    return "" unless context && context.respond_to?(:globals) && context.globals
    # 然后确保 script_pool 存在
    return "" unless context.globals.respond_to?(:script_pool) && context.globals.script_pool
    
    # 将所有脚本合并为一个字符串
    scripts = context.globals.script_pool.values.map do |script|
      "<script>#{script}</script>"
    end
    
    scripts.join("\n")
  end
end
