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

      <l:t>
      </l:t>
    CODE
    # code = UIPage.new(:kr).parse(code)
    code = "//[{\"type\":\"form\",\"id\":\"form_8fe2f66a\",\"input\":[{\"type\":\"input\",\"lbl\":\"账号\",\"name\":\"username\",\"is_required\":\"true\",\"id\":\"input_017e9583\"}]}]//\n<l:f>\n  //[null]//\n<l:i name=\"username\" lbl=\"账号\" is_required=\"true\" />\n</l:f>\n\n<l:t>\n</l:t>\n"
    code = "<l:f></l:f>"
    code2 = UIPage.new(:layui).parse(code)
    p code2
  end

end