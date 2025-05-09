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
      # 使用当前工作目录作为项目根目录，保证读取到启动者目录下的 config.yml
      return @c[key.to_s] if @c

      # 1. 读取核心库默认配置
      core_config_path = File.join(File.dirname(__FILE__), '../../config.yml')
      core_config = File.exist?(core_config_path) ? YAML.load_file(core_config_path) : {}
      core_config = core_config.is_a?(Hash) ? core_config : {}

      # 2. 读取调用者项目配置
      project_config_path = File.join(Dir.pwd, 'config.yml')
      project_config = File.exist?(project_config_path) ? YAML.load_file(project_config_path) : {}
      project_config = project_config.is_a?(Hash) ? project_config : {}

      # 3. 合并，调用者配置覆盖核心库
      @c = core_config.merge(project_config)

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
