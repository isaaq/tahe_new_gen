require 'yaml'
require 'singleton'
require_relative '../../_system'
require_relative 'mongo_common_util'
require_relative 'rpc_common_util'
require_relative 'ui_common_util'
require_relative 'redis_common_util'
require_relative 'common_func'
module Common
  class C
    include Singleton
    def self.[](key)
      temp = C.instance
      temp.read(key)
    end

    def read(key)
      path = File.join(File.dirname(__FILE__), '../../')
      @c = YAML.load_file("#{path}config.yml") if @c.nil?
      @c[key.to_s]
    end
  end
  # include ModelCommonUtil
  def self.included(base)

  end

  class M
    include Singleton
    type = C[:db]||'mongo'
    extend MongoCommonUtil if type == "mongo"
  end

  class S
    extend RPCCommonUtil
  end

  class R
    host = C['redis']['host']
    pass = C['redis']['pass']
    @r = Redis.new(host: host, port: 6379, password: pass)
    @r.select(1)
    def self.method_missing(symbol, *args)
      @r.send(symbol, args)
    end
  end

  class L
    type = C[:ui]
    extend LayoutCommonUtil
  end

  class U
    type = C[:ui]
    extend UICommonUtil
  end

  # at_exit do
  #   __p $! unless $!.nil?
  # end
end
