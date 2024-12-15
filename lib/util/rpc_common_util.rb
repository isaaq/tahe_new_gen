require 'redis'
module RPCCommonUtil
  def call(params)
    rpc = MessagePack::RPC::Client.new('127.0.0.1', 18800)
    rpc.call()
  end
end
