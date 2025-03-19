require_relative 'test_common'

class TestModel < Test::Unit::TestCase
  include Common

  def test_input
    puts UIPage.new(:layui).parse()
  end

  def test_form
    code = <<~CODE
      <kr:form>
        <kr:input lbl="账号" name="username" is_required="true"/>
      </kr:form>
    CODE
    code = UIPage.new(:kr).parse(code)
    code2 = UIPage.new(:layui).parse(code)
    puts code2
  end

    ##
    # 整体页面测试
    # layui的页面分为两部分
    # 1. 布局部分
    # 2. 代码部分
    # 这两部分分别输出到对应的位置才行, 所以需要标记用以注册位置
    # @see /Users/isaac/codes/tahe/tahe_new_gen/test/data/web/t1.html 为测试页面   
    # 
  def test_page
    code = <<~CODE
      <kr:page layout="test/data/web/layout.html">
        <kr:form>
          <kr:input lbl="账号" name="username" is_required="true"/>
        </kr:form>
      </kr:page>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end 

  def test_table
    code = <<~CODE
      <kr:table>
        
      </kr:table>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end

  def test_number_range_input
    code = <<~CODE
      <kr:number_range_input lbl="价格" name="price_range" min_value="0" max_value="100"/>

      <kr:form>
            <kr:number_range_input name="price_range" lbl="价格范围" min_value="100" max_value="1000"></kr:number_range_input>
            <kr:number_range_input name="age_range" lbl="年龄范围"></kr:number_range_input>
            
            <div class="layui-form-item">
              <div class="layui-input-block">
                <button type="button" class="layui-btn" id="submitBtn">提交</button>
                <button type="reset" class="layui-btn layui-btn-primary">重置</button>
              </div>
            </div>
          </kr:form>
    CODE
    code = UIPage.new(:kr).parse_code(code)
    code2 = UIPage.new(:layui).parse_code(code)
    puts code2
  end
end