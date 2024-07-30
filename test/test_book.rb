require_relative 'test_common'
require_relative '../lib/book/_config'

class TestBook < Test::Unit::TestCase
  include Common

  def test_load_file
    path = './test/data/book/t1/main.page'
    b = Bookfile.read(path)
    x = b.scan(/#\{(.+?)\}/m)
    p YAML.load(x[0][0])
  end
end