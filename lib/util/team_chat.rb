class TeamChat
  class WSRoom
    attr_accessor :id, :ws

    def initialize(id, ws)
      @id = id
      @ws = ws
    end
  end

  attr_accessor :params, :ws, :mc

  def initialize(mc, params, ws)
    @mc = mc
    @params = params
    @ws = ws
  end

  def get_prev
    # chats = mc[:chats].find(to_id: params['openid']).to_a.take(10).map{ |m| m[:content][:chat_role]=0;m }
    # mychats = mc[:chats].find(from_id: params['openid']).to_a.take(10).map{ |m| m[:content][:chat_role]=1;m }
    # chats = (chats + mychats).sort_by { |o| DateTime.parse(o[:content][:createdtime]) }
    chats = mc[:chats].find(to_id: params['car_number'])
    @ws.send(chats.map { |m| m['content'] }.to_json)
    mc[:chats].update_many({ to_id: params['openid'] }, "$set": { "read": true })
    WSRoom.new(params['car_number'], @ws)
  end

  def get_msg; end
end
