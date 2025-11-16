# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'yaml'

# 插件代码生成器
# 基于模板批量生成插件代码
class PluginGenerator
  TEMPLATES_DIR = File.join(File.dirname(__FILE__), 'templates')
  
  def initialize
    @templates = {}
    load_templates
  end
  
  # 生成策略插件
  def generate_strategy_plugin(config)
    template = get_template('strategy_plugin_template.rb.erb')
    
    # 计算基础require路径
    base_require_path = calculate_base_require_path(
      'strategy',
      config[:category],
      config[:class_name]
    )
    
    # 构建模板变量
    template_vars = {
      base_require_path: base_require_path,
      category_module: config[:category_module] || classify(config[:category]),
      class_name: config[:class_name],
      domain: config[:domain] || 'document',
      action: config[:action],
      context: config[:context] || 'default',
      required_params: config[:required_params] || [],
      pre_process_logic: config[:pre_process_logic] || '',
      perform_logic: config[:perform_logic] || generate_default_perform_logic(config),
      result_fields: config[:result_fields] || '',
      success_message: config[:success_message] || '操作成功',
      post_process_logic: config[:post_process_logic] || ''
    }
    
    render_template(template, template_vars)
  end
  
  # 生成字段类型插件
  def generate_field_type_plugin(config)
    template = get_template('field_type_plugin_template.rb.erb')
    
    base_require_path = calculate_base_require_path(
      'field_type',
      config[:category],
      config[:class_name]
    )
    
    template_vars = {
      base_require_path: base_require_path,
      category_module: config[:category_module] || classify(config[:category]),
      class_name: config[:class_name],
      field_type_name: config[:field_type_name] || underscore(config[:class_name]),
      validation_logic: config[:validation_logic] || generate_default_validation_logic(config),
      mongo_conversion_logic: config[:mongo_conversion_logic] || 'value',
      mongo_from_logic: config[:mongo_from_logic] || 'value',
      ui_conversion_logic: config[:ui_conversion_logic] || 'value'
    }
    
    render_template(template, template_vars)
  end
  
  # 批量生成插件
  def batch_generate(plugin_configs, output_dir)
    FileUtils.mkdir_p(output_dir)
    
    results = []
    plugin_configs.each do |config|
      begin
        code = case config[:type]
        when 'strategy'
          generate_strategy_plugin(config)
        when 'field_type'
          generate_field_type_plugin(config)
        when 'form_behavior'
          # 使用表单行为模板生成
          template = get_template('form_behavior_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            behavior_logic: config[:behavior_logic] || '# 在此实现表单行为逻辑'
          })
          code
        when 'ui_component'
          template = get_template('ui_component_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            render_logic: config[:render_logic] || 'return "<div>UI Component</div>"'
          })
          code
        when 'hook'
          template = get_template('hook_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            hook_logic: config[:hook_logic] || '# 在此实现钩子逻辑'
          })
          code
        when 'ai_prompt'
          template = get_template('ai_prompt_plugin_template.rb.erb')
          code = render_template(template, {
            plugin_id: config[:plugin_id],
            name: config[:name] || config[:class_name],
            category: config[:category],
            class_name: config[:class_name],
            ai_logic: config[:ai_logic] || 'return { success: true, output: input }'
          })
          code
        else
          raise "未知的插件类型: #{config[:type]}"
        end
        
        # 确定输出路径
        output_path = determine_output_path(config, output_dir)
        FileUtils.mkdir_p(File.dirname(output_path))
        
        # 写入文件（确保UTF-8编码）
        File.write(output_path, code, encoding: 'UTF-8')
        
        results << {
          success: true,
          plugin_id: config[:plugin_id],
          output_path: output_path
        }
      rescue => e
        results << {
          success: false,
          plugin_id: config[:plugin_id],
          error: e.message
        }
      end
    end
    
    results
  end
  
  private
  
  def load_templates
    Dir.glob(File.join(TEMPLATES_DIR, '*.erb')).each do |template_file|
      name = File.basename(template_file)
      @templates[name] = File.read(template_file)
    end
  end
  
  def get_template(name)
    @templates[name] || raise("模板不存在: #{name}")
  end
  
  def render_template(template_content, vars)
    # 将变量设置为实例变量，以便ERB模板可以访问
    vars.each do |key, value|
      # 确保字符串值是UTF-8编码
      if value.is_a?(String)
        value = value.force_encoding('UTF-8') if value.encoding != Encoding::UTF_8
      elsif value.is_a?(Array)
        value = value.map { |v| v.is_a?(String) && v.encoding != Encoding::UTF_8 ? v.force_encoding('UTF-8') : v }
      end
      instance_variable_set("@#{key}", value)
    end
    
    # 确保模板内容是UTF-8编码
    template_content = template_content.force_encoding('UTF-8') if template_content.encoding != Encoding::UTF_8
    
    # 创建binding并渲染模板
    result = ERB.new(template_content, trim_mode: '-').result(binding)
    # 确保结果是UTF-8编码
    result.force_encoding('UTF-8')
  end
  
  def calculate_base_require_path(base_type, category, class_name)
    # 计算相对require路径
    # 例如: strategy/save -> '../../../strategy/base_strategy'
    depth = category.split('/').size + 1
    '../' * depth + "#{base_type}/base_#{base_type == 'strategy' ? 'strategy' : 'field_type'}"
  end
  
  def determine_output_path(config, base_dir)
    category_path = config[:category].gsub('_', '/')
    file_name = underscore(config[:class_name]) + '.rb'
    File.join(base_dir, category_path, file_name)
  end
  
  def generate_default_perform_logic(config)
    action = config[:action].to_s
    collection = config[:collection] || 'documents'
    
    if action == 'save'
      <<~RUBY
        data = params[:data]
        collection = params[:collection] || '#{collection}'
        
        # 使用 MongoDB 存储数据
        result = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')[collection].insert_one(data)
        
        {
          success: true,
          document_id: result.inserted_id.to_s,
          message: "文档已保存"
        }
      RUBY
    elsif action == 'query'
      <<~RUBY
        query = params[:query] || {}
        collection = params[:collection] || '#{collection}'
        
        # 执行查询
        results = Mongo::Client.new(["localhost:27017"], database: 'kr_new_gen')[collection].find(query).to_a
        
        {
          success: true,
          data: results,
          count: results.size
        }
      RUBY
    else
      <<~RUBY
        # 实现具体的策略逻辑
        {
          success: true
        }
      RUBY
    end
  end
  
  def generate_default_validation_logic(config)
    field_type = config[:field_type_name].to_s
    
    if field_type =~ /number|integer|float/
      <<~RUBY
        unless value.is_a?(Numeric)
          return [false, "\#{@name} 必须是数字"]
        end
        
        if @options[:min] && value < @options[:min]
          return [false, "\#{@name} 不能小于 \#{@options[:min]}"]
        end
        
        if @options[:max] && value > @options[:max]
          return [false, "\#{@name} 不能大于 \#{@options[:max]}"]
        end
      RUBY
    elsif field_type =~ /string|text/
      <<~RUBY
        unless value.is_a?(String)
          return [false, "\#{@name} 必须是字符串"]
        end
        
        if @options[:min_length] && value.length < @options[:min_length]
          return [false, "\#{@name} 长度不能小于 \#{@options[:min_length]}"]
        end
        
        if @options[:max_length] && value.length > @options[:max_length]
          return [false, "\#{@name} 长度不能超过 \#{@options[:max_length]}"]
        end
      RUBY
    else
      '# 自定义验证逻辑'
    end
  end
  
  def classify(str)
    str.split(/[_\s]+/).map(&:capitalize).join
  end
  
  def underscore(str)
    str.gsub(/::/, '/')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .tr('-', '_')
       .downcase
  end
end

