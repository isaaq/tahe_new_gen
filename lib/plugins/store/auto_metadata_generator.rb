# frozen_string_literal: true

require_relative 'plugin_store'
require 'parser'
require 'ast'

# 自动元数据生成器
# 通过扫描代码自动生成插件元数据
class AutoMetadataGenerator
  def initialize
    @store = PluginStore.instance
  end
  
  # 扫描目录并生成元数据
  def scan_and_generate(plugin_dir)
    plugins = []
    
    Dir.glob(File.join(plugin_dir, '**', '*.rb')).each do |file_path|
      next if file_path.include?('/templates/') || file_path.include?('/store/')
      
      begin
        metadata = extract_metadata_from_file(file_path)
        plugins << metadata if metadata
      rescue => e
        puts "解析文件失败 #{file_path}: #{e.message}" if dev?
      end
    end
    
    plugins
  end
  
  # 从文件提取元数据
  def extract_metadata_from_file(file_path)
    content = File.read(file_path)
    
    # 解析Ruby代码
    ast = Parser::CurrentRuby.parse(content)
    return nil unless ast
    
    metadata = {
      file_path: file_path,
      is_builtin: true
    }
    
    # 提取类名
    class_name = extract_class_name(ast)
    metadata[:class_name] = class_name
    
    # 提取策略注册信息
    strategy_info = extract_strategy_info(ast)
    if strategy_info
      metadata.merge!(strategy_info)
      metadata[:type] = 'strategy'
    end
    
    # 提取字段类型信息
    field_type_info = extract_field_type_info(ast)
    if field_type_info
      metadata.merge!(field_type_info)
      metadata[:type] = 'field_type'
    end
    
    # 提取描述信息（注释）
    metadata[:description] = extract_description(content)
    
    # 生成插件ID
    metadata[:plugin_id] = generate_plugin_id(metadata)
    
    # 生成分类
    metadata[:category] = infer_category(file_path, metadata)
    
    metadata
  end
  
  private
  
  def extract_class_name(ast)
    return nil unless ast.is_a?(Parser::AST::Node)
    
    case ast.type
    when :class
      ast.children[0].children[1].to_s
    when :module
      ast.children[0].children[1].to_s
    else
      ast.children.each do |child|
        result = extract_class_name(child)
        return result if result
      end
      nil
    end
  end
  
  def extract_strategy_info(ast)
    return nil unless ast.is_a?(Parser::AST::Node)
    
    # 查找 strategy_for 调用
    if ast.type == :send && ast.children[1] == :strategy_for
      domain = ast.children[2]&.children&.[](0)&.children&.[](0)
      action = ast.children[3]&.children&.[](0)&.children&.[](0)
      context = ast.children[4]&.children&.[](0)&.children&.[](0) || 'default'
      
      return {
        domain: domain.to_s,
        action: action.to_s,
        context: context.to_s
      }
    end
    
    # 递归查找
    ast.children.each do |child|
      result = extract_strategy_info(child)
      return result if result
    end
    
    nil
  end
  
  def extract_field_type_info(ast)
    return nil unless ast.is_a?(Parser::AST::Node)
    
    # 查找 field_type_for 调用
    if ast.type == :send && ast.children[1] == :field_type_for
      field_type_name = ast.children[2]&.children&.[](0)&.children&.[](0)
      
      return {
        field_type_name: field_type_name.to_s
      }
    end
    
    # 递归查找
    ast.children.each do |child|
      result = extract_field_type_info(child)
      return result if result
    end
    
    nil
  end
  
  def extract_description(content)
    # 提取文件开头的注释作为描述
    lines = content.lines
    description_lines = []
    
    lines.each do |line|
      break unless line.strip.start_with?('#')
      next if line.strip == '# frozen_string_literal: true'
      next if line.strip.empty?
      
      desc = line.gsub(/^#\s*/, '').strip
      description_lines << desc unless desc.empty?
    end
    
    description_lines.join(' ').strip
  end
  
  def generate_plugin_id(metadata)
    if metadata[:type] == 'strategy'
      "strategy-#{metadata[:action]}-#{metadata[:context]}"
    elsif metadata[:type] == 'field_type'
      "field-type-#{metadata[:field_type_name]}"
    else
      underscore(metadata[:class_name] || 'unknown')
    end
  end
  
  def infer_category(file_path, metadata)
    # 从文件路径推断分类
    if file_path.include?('/strategy/')
      parts = file_path.split('/strategy/')[1].split('/')
      "strategy/#{parts[0]}"
    elsif file_path.include?('/field_type/')
      parts = file_path.split('/field_type/')[1].split('/')
      "field_type/#{parts[0]}"
    else
      metadata[:category] || 'other'
    end
  end
  
  def underscore(str)
    str.gsub(/::/, '/')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .tr('-', '_')
       .downcase
  end
  
  def dev?
    ENV['RACK_ENV'] != 'production'
  end
end

