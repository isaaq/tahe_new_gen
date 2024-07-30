require_relative 'db_mongo_mod'

class DBMongo
  attr_accessor :db, :table

  def initialize
    init
  end

  def init
    path = File.join(File.dirname(__FILE__), '../../')
    c = YAML.load_file("#{path}config.yml") if @c.nil?

    mc = Mongo::Client.new(\
    [c['mongo']['host']]\
              , user: c['mongo']['user']\
              , password: c['mongo']['pass']\
              , database: c['mongo']['db']
    )
    mc = mc.use(c['mongo']['db_main'])
    @db = mc
  end


end
