# frozen_string_literal: true

## KrPageItem
# 整个页面
#
class PageItem < LayuiElement

  def pre_process
    # 初始化脚本池
    if tag && tag.respond_to?(:context) && tag.context && tag.context.respond_to?(:globals) && tag.context.globals
      # 使用更安全的方式检查并初始化 script_pool
      begin
        script_pool = tag.context.globals.instance_variable_get(:@hash)[:script_pool]
        if script_pool.nil?
          tag.context.globals.instance_variable_get(:@hash)[:script_pool] = {}
        end
      rescue
        tag.context.globals.instance_variable_set(:@hash, {}) unless tag.context.globals.instance_variable_defined?(:@hash)
        tag.context.globals.instance_variable_get(:@hash)[:script_pool] = {}
      end
    end
    
    if !tag['layout'].nil? && File.exist?(tag['layout'])
      tag.context.globals.layout = File.read(tag['layout'])
    end
    @view = tag.expand
  end

  def output_tag
    # 处理视图内容
    view_escaped = @view.to_s.inspect[1..-2] if @view
    
    # 如果有脚本内容，将其添加到脚本池
    script_content = ""
    if @script && !@script.to_s.strip.empty? && 
       tag && tag.respond_to?(:context) && tag.context && 
       tag.context.respond_to?(:globals) && tag.context.globals
      
      # 使用更安全的方式访问和修改 script_pool
      begin
        hash = tag.context.globals.instance_variable_get(:@hash)
        if hash
          hash[:script_pool] ||= {}
          
          # 生成脚本的摘要作为键
          digest = @script.hash.to_s
          
          # 如果脚本不存在于池中，则添加
          unless hash[:script_pool].key?(digest)
            hash[:script_pool][digest] = @script
          end
          
          # 获取脚本池中的所有脚本
          script_content = hash[:script_pool].values.map do |script|
            "<script>#{script}</script>"
          end.join("\n")
        end
      rescue => e
        # 如果出现错误，记录下来但不中断流程
        puts "Error processing script pool: #{e.message}"
      end
    end
    script_escaped = script_content.inspect[1..-2] if !script_content.empty?
    
    # 生成最终输出
    <<~EOF
      <%parse_reg_area('global_view',"#{view_escaped}", :append)%>
      <%parse_reg_area('global_script',"#{script_escaped}", :append)%>
      <div class="layui-container" style="margin-top: 20px;">
        #global_view{
        #}
      </div>
      #global_script{
      #}
    EOF
  end
end