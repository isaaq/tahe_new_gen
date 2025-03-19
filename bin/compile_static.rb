#!/usr/bin/env ruby
# frozen_string_literal: true

# 静态编译脚本
# 用法: ruby bin/compile_static.rb [clean|compile|incremental|validate|full]

require_relative '../lib/ui/static_compiler'

# 确保输出目录存在
output_dir = File.join(File.dirname(__FILE__), '../web/static')
FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

# 创建编译器实例
compiler = StaticCompiler.new(
  File.join(File.dirname(__FILE__), '../views'),
  output_dir
)

# 处理命令行参数
command = ARGV[0] || 'full'

case command
when 'clean'
  puts "清理输出目录..."
  compiler.clean_output_directory
when 'compile'
  puts "编译所有模板..."
  compiler.compile_directory
when 'incremental'
  puts "增量编译模板..."
  compiler.incremental_compile
when 'validate'
  puts "验证编译后的文件..."
  compiler.validate_compiled_files
when 'full'
  puts "执行完整编译流程..."
  compiler.clean_output_directory
  compiler.compile_directory
  compiler.validate_compiled_files
else
  puts "未知命令: #{command}"
  puts "可用命令: clean, compile, incremental, validate, full"
  exit 1
end

puts "完成!"
