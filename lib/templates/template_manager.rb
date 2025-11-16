# frozen_string_literal: true

require 'yaml'
require 'singleton'
require 'fileutils'

# 模板管理器
# 负责加载、解析、管理内置模板
class TemplateManager
  include Singleton
  
  def initialize
    @templates = {}
    @loaded = false
  end
  
  # 加载所有内置模板
  def self.load_builtin_templates
    instance.send(:load_builtin_templates)
  end
  
  # 获取模板
  def self.get_template(template_id)
    instance.send(:get_template, template_id)
  end
  
  # 实例化模板为kr标签
  def self.instantiate(template_id, customizations = {})
    instance.send(:instantiate, template_id, customizations)
  end
  
  # 列出所有可用模板
  def self.list_templates
    instance.send(:list_templates)
  end
  
  # 检查模板是否存在
  def self.template_exists?(template_id)
    instance.send(:template_exists?, template_id)
  end
  
  # 重新加载模板
  def self.reload_templates
    instance.send(:reload_templates)
  end
  
  private
  
  # 加载内置模板
  def load_builtin_templates
    return if @loaded
    
    builtin_dir = File.join(File.dirname(__FILE__), 'builtin')
    
    unless Dir.exist?(builtin_dir)
      puts "警告: 内置模板目录不存在: #{builtin_dir}" if dev?
      return
    end
    
    # 扫描所有.yml文件
    yaml_files = Dir.glob(File.join(builtin_dir, '*.yml'))
    
    yaml_files.each do |file_path|
      begin
        template_data = YAML.load_file(file_path)
        template_id = extract_template_id(template_data, file_path)
        
        if template_id
          @templates[template_id] = {
            data: template_data,
            file_path: file_path,
            loaded_at: Time.now
          }
          
          puts "已加载模板: #{template_id} (#{File.basename(file_path)})" if dev?
        else
          puts "警告: 无法从文件提取模板ID: #{file_path}" if dev?
        end
        
      rescue => e
        puts "错误: 加载模板文件失败 #{file_path}: #{e.message}" if dev?
      end
    end
    
    @loaded = true
    puts "模板加载完成，共加载 #{@templates.size} 个模板" if dev?
  end
  
  # 提取模板ID
  def extract_template_id(template_data, file_path)
    # 优先从metadata.id获取
    if template_data.is_a?(Hash) && template_data['metadata'] && template_data['metadata']['id']
      return template_data['metadata']['id']
    end
    
    # 从文件名获取（去除扩展名）
    File.basename(file_path, '.yml')
  end
  
  # 获取模板
  def get_template(template_id)
    ensure_loaded
    
    template_info = @templates[template_id.to_s]
    return nil unless template_info
    
    template_info[:data]
  end
  
  # 实例化模板为kr标签
  def instantiate(template_id, customizations = {})
    template_config = get_template(template_id)
    
    unless template_config
      raise "模板不存在: #{template_id}"
    end
    
    # 应用自定义配置
    merged_config = deep_merge(template_config, customizations)
    
    # 转换为kr标签
    require_relative 'template_to_kr_converter'
    TemplateToKrConverter.convert(merged_config)
  end
  
  # 列出所有模板
  def list_templates
    ensure_loaded
    
    @templates.map do |template_id, template_info|
      metadata = template_info[:data]['metadata'] || {}
      {
        id: template_id,
        name: metadata['name'] || template_id,
        description: metadata['description'] || '',
        category: metadata['category'] || 'uncategorized',
        version: metadata['version'] || '1.0.0',
        tags: metadata['tags'] || [],
        loaded_at: template_info[:loaded_at]
      }
    end
  end
  
  # 检查模板是否存在
  def template_exists?(template_id)
    ensure_loaded
    @templates.key?(template_id.to_s)
  end
  
  # 重新加载模板
  def reload_templates
    @templates.clear
    @loaded = false
    load_builtin_templates
  end
  
  # 确保模板已加载
  def ensure_loaded
    load_builtin_templates unless @loaded
  end
  
  # 深度合并Hash
  def deep_merge(base_hash, override_hash)
    result = base_hash.dup
    
    override_hash.each do |key, value|
      if result[key].is_a?(Hash) && value.is_a?(Hash)
        result[key] = deep_merge(result[key], value)
      else
        result[key] = value
      end
    end
    
    result
  end
  
  # 开发模式检查
  def dev?
    defined?(Rails) ? Rails.env.development? : true
  end
end
