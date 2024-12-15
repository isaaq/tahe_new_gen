require 'thor'
require 'tmpdir'

class Build < Thor
  desc "db_init", "数据库初始化"
  def db_init
    path = "./test/data/dsl/model/"
    p path
  end
end

Build.start(ARGV)