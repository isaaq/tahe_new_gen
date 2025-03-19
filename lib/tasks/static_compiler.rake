# frozen_string_literal: true

require_relative '../ui/static_compiler'

namespace :static do
  desc "清理静态编译输出目录"
  task :clean do
    compiler = StaticCompiler.new(
      File.join(File.dirname(__FILE__), '../../views'),
      File.join(File.dirname(__FILE__), '../../web/static')
    )
    compiler.clean_output_directory
  end
  
  desc "编译所有模板为静态HTML"
  task :compile => :clean do
    compiler = StaticCompiler.new(
      File.join(File.dirname(__FILE__), '../../views'),
      File.join(File.dirname(__FILE__), '../../web/static')
    )
    compiler.compile_directory
  end
  
  desc "增量编译修改过的模板"
  task :incremental do
    compiler = StaticCompiler.new(
      File.join(File.dirname(__FILE__), '../../views'),
      File.join(File.dirname(__FILE__), '../../web/static')
    )
    compiler.incremental_compile
  end
  
  desc "验证编译后的文件"
  task :validate do
    compiler = StaticCompiler.new(
      File.join(File.dirname(__FILE__), '../../views'),
      File.join(File.dirname(__FILE__), '../../web/static')
    )
    compiler.validate_compiled_files
  end
  
  desc "完整的编译流程：清理、编译、验证"
  task :full => [:clean, :compile, :validate]
  
  if defined?(Listen)
    desc "监视文件变化并自动重新编译"
    task :watch do
      compiler = StaticCompiler.new(
        File.join(File.dirname(__FILE__), '../../views'),
        File.join(File.dirname(__FILE__), '../../web/static')
      )
      
      source_dir = File.join(File.dirname(__FILE__), '../../views')
      
      puts "开始监视目录: #{source_dir}"
      puts "按 Ctrl+C 停止监视"
      
      listener = Listen.to(source_dir) do |modified, added, removed|
        (modified + added).each do |file|
          if file.end_with?('.erb')
            puts "检测到文件变化: #{file}"
            compiler.compile_file(file)
          end
        end
      end
      
      listener.start
      sleep
    end
  else
    desc "监视功能需要Listen gem"
    task :watch do
      puts "请先安装Listen gem: gem install listen"
    end
  end
end

# 添加到默认任务
task :static => 'static:full'
