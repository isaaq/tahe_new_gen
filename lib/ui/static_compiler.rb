# frozen_string_literal: true

require 'fileutils'
require_relative 'ui_page'

# 静态编译器类，用于将模板编译为静态HTML文件
class StaticCompiler
  def initialize(source_dir, output_dir)
    @source_dir = source_dir
    @output_dir = output_dir
  end
  
  # 编译单个文件
  def compile_file(source_path, context = {})
    # 计算相对路径和输出路径
    relative_path = source_path.sub(@source_dir, '')
    relative_path = relative_path[1..-1] if relative_path.start_with?('/')
    output_path = File.join(@output_dir, relative_path.sub('.erb', '.html'))
    
    # 确保输出目录存在
    FileUtils.mkdir_p(File.dirname(output_path))
    
    begin
      # 读取模板
      template_content = File.read(source_path)
      
      # 双重解析
      begin
        # 第一次解析：kr标签
        kr_page = UIPage.new(:kr)
        kr_page.context = context
        intermediate_content = kr_page.parse_code(template_content)
        puts "First parsing completed successfully."
        
        # 第二次解析：layui标签
        layui_page = UIPage.new(:layui)
        layui_page.context = context
        final_content = layui_page.parse_code(intermediate_content)
        puts "Second parsing completed successfully."
      rescue => e
        puts "Error during parsing: #{e.message}"
        puts e.backtrace.join("\n")
        raise e
      end
      
      # 写入静态文件
      File.write(output_path, final_content)
      
      puts "Compiled: #{source_path} -> #{output_path}"
      return true
    rescue => e
      puts "Error compiling #{source_path}: #{e.message}"
      puts e.backtrace.join("\n")
      return false
    end
  end
  
  # 编译整个目录
  def compile_directory(context = {})
    success_count = 0
    failure_count = 0
    
    Dir.glob(File.join(@source_dir, '**', '*.erb')).each do |file|
      if compile_file(file, context)
        success_count += 1
      else
        failure_count += 1
      end
    end
    
    puts "Compilation complete: #{success_count} succeeded, #{failure_count} failed"
    return success_count, failure_count
  end
  
  # 增量编译（只编译修改过的文件）
  def incremental_compile(context = {})
    success_count = 0
    failure_count = 0
    skipped_count = 0
    
    Dir.glob(File.join(@source_dir, '**', '*.erb')).each do |source_path|
      relative_path = source_path.sub(@source_dir, '')
      relative_path = relative_path[1..-1] if relative_path.start_with?('/')
      output_path = File.join(@output_dir, relative_path.sub('.erb', '.html'))
      
      # 如果输出文件不存在或源文件更新时间更晚，则编译
      if !File.exist?(output_path) || File.mtime(source_path) > File.mtime(output_path)
        if compile_file(source_path, context)
          success_count += 1
        else
          failure_count += 1
        end
      else
        skipped_count += 1
      end
    end
    
    puts "Incremental compilation complete: #{success_count} succeeded, #{failure_count} failed, #{skipped_count} skipped"
    return success_count, failure_count, skipped_count
  end
  
  # 清理输出目录
  def clean_output_directory
    if File.directory?(@output_dir)
      FileUtils.rm_rf(Dir.glob(File.join(@output_dir, '*')))
      puts "Cleaned output directory: #{@output_dir}"
    else
      FileUtils.mkdir_p(@output_dir)
      puts "Created output directory: #{@output_dir}"
    end
  end
  
  # 验证编译后的文件
  def validate_compiled_files
    valid_count = 0
    invalid_count = 0
    
    Dir.glob(File.join(@output_dir, '**', '*.html')).each do |file|
      if File.size(file) > 0
        valid_count += 1
      else
        invalid_count += 1
        puts "Empty compiled file: #{file}"
      end
    end
    
    puts "Validation complete: #{valid_count} valid, #{invalid_count} invalid"
    return valid_count, invalid_count
  end
end
