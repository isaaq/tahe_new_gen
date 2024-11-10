require_relative 'test_common'
require_relative '../lib/book/_config'

class TestBook < Test::Unit::TestCase
  include Common

  def test_load_file_type_page
    path = './test/data/book/t1/main.page'
    b = Bookfile.read_file(path)
    x = b.scan(/#\{(.+?)\}/m)
    p YAML.load(x[0][0])
  end


  def test_load_book_pkg
    # Download Book Pkg
    # UnZip
    path = './test/data/book/t1/'
    b = Bookfile.scan(path)
  end
end