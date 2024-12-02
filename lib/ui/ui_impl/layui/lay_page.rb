# frozen_string_literal: true

class LayuiPage
  def default_layout
    <<~EOS
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Layui 基本模板</title>
          <!-- 引入 Layui 样式 -->
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/layui-v2.7.6/dist/css/layui.css">
          #style{}
      </head>
      <body>
          <!-- 页面主体内容 -->
          <div class="layui-container" style="margin-top: 20px;">
              <div class="layui-row">
                  <div class="layui-col-md12">
                      <h1 class="layui-text">欢迎使用 Layui</h1>
                      <button class="layui-btn layui-btn-primary" id="myBtn">点击我</button>
                  </div>
              </div>
          </div>

          <!-- 引入 Layui JavaScript 文件 -->
          <script src="https://cdn.jsdelivr.net/npm/layui-v2.7.6/dist/layui.all.js"></script>
          <%=yield%>
          
      </body>
      </html>
    EOS
  end

  def default_page
    <<~EOS
      #global_func{
rrtrr
      #}
      <[page type="layui" master="layui_source"]>
      <kr:test />
      <kr:input lbl="账号" name="username" />
      <kr:test />
      <kr:test2 />
    EOS
  end
end
