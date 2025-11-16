# frozen_string_literal: true

# 模板系统初始化文件
# 加载模板管理器和其他相关组件

require_relative 'template_manager'
require_relative 'template_to_kr_converter'

# 加载所有内置模板
begin
  TemplateManager.load_builtin_templates
  puts "模板系统初始化成功" if ENV['RACK_ENV'] != 'production'
rescue => e
  puts "模板系统初始化失败: #{e.message}"
  puts "错误详情: #{e.backtrace.first(5).join("\n")}" if ENV['RACK_ENV'] != 'production'
end

