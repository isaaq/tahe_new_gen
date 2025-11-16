# KR -> Layui -> HTML + Runtime 完整示例

require_relative '../lib/ui/ui_impl/kr_transformer'
require_relative '../lib/ui/ui_impl/layui/layui_transformer'

# 示例：创建一个包含数值范围控件的表单
def create_demo_form
  # 1. 定义 kr 标签结构
  kr_form = {
    tag: 'form',
    attributes: {
      id: 'demo_form',
      model: 'Product',
      action: '/api/products/save'
    },
    children: [
      {
        tag: 'input',
        attributes: {
          name: 'name',
          label: '产品名称',
          required: true
        }
      },
      {
        tag: 'number_range_input',
        attributes: {
          name: 'price_range',
          label: '价格区间',
          min: 0,
          max: 10000
        }
      }
    ]
  }
  
  # 2. 通过 KrTransformer 转换为 layui 标签
  layui_output = KrTransformer.trans(kr_form, {})
  
  # 3. 输出最终的 HTML + Runtime
  puts "=== KR -> Layui -> HTML + Runtime 示例 ==="
  puts layui_output
end

# 运行示例
create_demo_form if __FILE__ == $0
