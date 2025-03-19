# frozen_string_literal: true

# 静态页面中间件
# 用于在动态解析前检查是否存在静态编译的页面
class StaticPagesMiddleware
  def initialize(app, options = {})
    @app = app
    @options = {
      enabled: ENV["USE_STATIC_PAGES"] == "true",
      static_dir: "web/static",
      excluded_paths: ["/api/", "/assets/"],
    }.merge(options)
  end

  def call(env)
    # 如果禁用了静态页面或请求路径在排除列表中，则跳过处理
    unless @options[:enabled]
      return @app.call(env)
    end

    path = env["PATH_INFO"]

    # 检查是否应该排除此路径
    @options[:excluded_paths].each do |excluded|
      if path.start_with?(excluded)
        return @app.call(env)
      end
    end

    # 计算静态文件路径
    static_path = compute_static_path(path)

    if static_path && File.exist?(static_path)
      # 找到静态文件，直接返回
      content = File.read(static_path)
      [200, { "Content-Type" => "text/html", "Content-Length" => content.bytesize.to_s }, [content]]
    else
      # 没有找到静态文件，继续正常处理
      @app.call(env)
    end
  end

  private

  def compute_static_path(path)
    # 处理路径，确定对应的静态文件
    if path == "/" || path.empty?
      # 主页
      File.join(@options[:static_dir], "index.html")
    elsif path.end_with?("/")
      # 目录路径
      File.join(@options[:static_dir], path, "index.html")
    elsif !path.include?(".")
      # 没有扩展名的路径
      File.join(@options[:static_dir], "#{path}.html")
    elsif path.end_with?(".html")
      # HTML路径
      File.join(@options[:static_dir], path)
    else
      # 其他路径
      nil
    end
  end
end
