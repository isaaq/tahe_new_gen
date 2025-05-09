require_relative 'db_mongo_mod'

class DBMongo
  attr_accessor :db, :table, :table_alias, :model

  def initialize(opts = {})
    init(opts)
  end

  def init(opts = {})
    c = Common::C
    if opts.has_key?(:host)
      mc = Mongo::Client.new(\
        [opts[:host]] \
        , user: opts[:user] \
        , password: opts[:pass] \
        , database: opts[:db] \
        , op_timeout: 3, connect_timeout: 3
      )
    else
      mc = Mongo::Client.new(\
        [c['mongo']['host']]\
        , user: c['mongo']['user']\
        , password: c['mongo']['pass']\
        , database: c['mongo']['db'] \
        , op_timeout: 3, connect_timeout: 3
      )
    end
    mc = mc.use(c['mongo']['db_main'])
    @db = mc
  end


end
