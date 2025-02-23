# typed: ignore
# frozen_string_literal: true
require_relative '../../lib/util/team_chat'
class WSController < ApiController
  #  use JwtAuth

  def save_msg(id, frominfo)
    f = M[:chats].find_by(uid: id)
    if f.nil?
      f = {
        uid: id,
        from_name: 'test',
        from_icon: 'images/msg/notice.jpg',
        chats: [
          {from_uid: frominfo[:uid],
           from_name: frominfo[:userInfo][:nickName],
           from_icon: frominfo[:userInfo][:avatarUrl],
           unread: 0,
           updated: Time.now,
           read: false}
        ],
      }
      M[:chats].add(f)
    end
    # 开始更新消息
    unless frominfo[:uid] == env[:user]['uid']
      f_c_index_you = f[:chats].find_index { |f| f[:from_uid] == frominfo[:uid] }
      if f_c_index_you.nil?
        f[:chats] << {from_uid: frominfo[:uid],
                      from_name: frominfo[:userInfo][:nickName],
                      from_icon: frominfo[:userInfo][:avatarUrl],
                      unread: 0,
                      updated: Time.now,
                      read: false}
        f_c_index_you = -1
      end
      f[:chats][f_c_index_you][:unread] += 1
      f[:chats][f_c_index_you][:updated] = Time.now
      f[:chats][f_c_index_you][:read] = false
      M[:chats].update({uid:f[:uid]}, f)
    end
    f
  end

  # region ws
  def send_ws_msg(json, r)
    json['read'] = false
    json['createdtime'] = DateTime.now.to_s

    # 找到就直接发送，并已读
    unless r.nil?
      json['read'] = true
      r.ws.send(json.to_json)
    end
    # 存数据库

    # 先存聊天列表表
    # 存我也存你
    # 我是谁, 先找我
    p json
    f_member_me = M[:userinfos].find_by(uid: json['from_id'])

    # 对方是谁
    f_member_to = M[:userinfos].find_by(uid: json['to_id'])
    # 给对方(你)的
    f_you = save_msg(json['to_id'], f_member_me)
    # 给自己的(我)
    f_me = save_msg(json['from_id'], f_member_to)

    data = {
      from_uid: json['from_id'],
      to_uid: json['to_id'],
      createdtime: Time.now,
      icon: f_member_me[:userInfo][:avatarUrl],
      msg: json['content']
    }
    M[:chat_msgs].add(data)
    # 再存聊天内容表

  end

  def is_spec_uid(uid)
    dict = ['0']
    role = {'0' => 'system'}
    dict.include?(uid)
  end

  def initialize(app = nil)
    super
    # EM.run {
    #   EM.add_periodic_timer(10) do
    #
    #   end
    # }
  end

  get '/chat' do
    if !request.websocket?
      <<~EOF
        <html>
          <body>
             <h1>此页面是websocket页面，无法独立访问</h1>
          </body>
        </html>
      EOF
    else
      request.websocket do |ws|
        tc = TeamChat.new(M, params, ws)
        ws.onopen do
          if !env[:user].nil?
            settings.sockets << tc.get_prev(env[:user]['uid'])
          else
            p 'onopen: 用户信息失败'
          end
        end
        ws.onmessage do |msg|
          EM.next_tick do
            p msg
            if env[:user].nil?
              (p 'onmessage: 用户信息失败')
              next
            else
              (p env[:user]['uid'])
            end
            j = begin
                  JSON.parse(msg)
                rescue StandardError
                  nil
                end
            if !j.nil?
              j['from_id'] = env[:user]['uid']
              case j['cmd'].to_s
              when 'JOIN' then

              when 'PING' then
                f_socket = settings.sockets.find { |f| f.id == j['from_id'] }
                f_socket.ws.send({cmd: 'PING', msg: 'ok'}.to_json)
                nts = M[:chat_notices].find_by(read: 0)
                nts.each do |e|
                  if e[:to_uid] ==  j['from_id']
                    f_socket.ws.send({cmd: 'NOTICE', data: e}.to_json)
                    #M[:chat_notices].find_one_and_update({_id: e[:_id]}, {'$set': {read: 1}})
                  end
                end
              end
              case j['chattype'].to_s
              when 'normal' then
                warn('一般消息')

                # if j['to_id'] =~ /^[\u4e00-\u9fa5]{1}[A-Z]{1}[A-Z_0-9]{5}$/
                #   f = M[:carteams].query(openid: {'$in': [j['from_id']]}).to_a[0]
                #   unless f.nil?
                #     f[:cars].each do |e|
                #       e[:pre_driver].each do |d|
                #         if d[:vehicle_plate_number] == j['to_id']
                #           to_openid = d[:openid]
                #           j['to_id'] = to_openid
                #         end
                #       end
                #     end
                #   end
                # end

                f_socket = settings.sockets.find { |f| f.id == j['to_id'] }
                f_member = M[:userinfos].find_by(uid: j['to_id'])

                j['from_openid'] = j['openid']
                j['to_openid'] = j['to_openid']
                j['username'] = f_member[:username] || f_member[:nickname]
                j['icon'] = f_member[:headimgurl]
                p "====>"
                p j["content"]
                send_ws_msg(j, f_socket)

                # openurl("http://#{C['domain']}/wechat/notice/msgs?openid=#{to_openid}&car_number=#{URI.encode(car_number)}")
              when 'team_broadcast' then
                # 广播
                warn('广播消息')
                team_id = j['to_id']
                team = M[:carteams].find_by(_id: team_id.to_objid)
                unless team.nil?
                  team[:cars].each do |e|
                    f = settings.sockets.find { |f| f.id == e[:member_id].to_s }
                    send_ws_msg(j, f)
                    # openurl("http://#{C['domain']}/wechat/notice/msg?openid=#{j['to_id']}")
                  end
                end
              when 'broadcast' then
                # 全服广播
                warn('全服广播')
                members = M[:members].find_by
                members.each do |e|
                  # 要排除我自己
                  f = settings.sockets.find { |f| f.id == e[:openid].to_s && e[:openid] != params['openid'] }
                  send_ws_msg(j, f)
                end
              else
                warn('默认')
              end
            else
              warn('json解析失败')
            end
          end
        end
        ws.onclose do
          warn('关闭ws')
          f = settings.sockets.find { |f| f.ws == ws }
          settings.sockets.delete(f)
        end
        ws.onerror(&:to_s)
      end
    end
  end
  # endregion

  get '/chat_info' do
    M[:members].find_by(openid: params[:openid]).to_json
  end

  get '/get_chat_list' do
    if !env[:user].nil?
      # p env[:user]['uid']
      M[:chats].find_by(uid: env[:user]['uid']).to_resp
      # M[:chat_msgs].find(to_uid: env[:user]['uid']).to_a[0]&.to_resp
    else
      make_resp('', 'error', 20003)
    end
  end

  get '/get_notice_list' do
    if !env[:user].nil?
      # notices = M[:chat_notices].query(uid: env[:user]['uid']).to_a
      # infos = M[:chat_infos].query(uid: env[:user]['uid']).to_a
      # systems = M[:chat_systems].query(uid: env[:user]['uid']).to_a
      likes = M[:chat_notices].find_by(to_uid: env[:user]['uid'], type: 'like')
      fans = M[:chat_notices].find_by(to_uid: env[:user]['uid'], type: 'fans')
      discusses = M[:chat_notices].find_by(to_uid: env[:user]['uid'], type: 'discuss')
      systems = M[:chat_notices].find_by(to_uid: env[:user]['uid'], type: 'system')

      ret = []
      ret << {type: 'like', content: likes[0], unread: likes.count { |c| c[:read] == 0 }}
      ret << {type: 'fans', content: fans[0], unread: fans.count { |c| c[:read] == 0 }}
      ret << {type: 'discusses', content: fans[0], unread: discusses.count { |c| c[:read] == 0 }}
      ret << {type: 'system', content: systems[0], unread: systems.count { |c| c[:read] == 0 }}
      ret.to_resp
    else
      make_resp('', 'error', 20003)
    end
  end

  get '/chat_msgs_by_openid/:uid' do
    my_uid = env[:user]['uid']
    uid = params[:uid]
    msgs = M[:chat_msgs].find_by("$or": [{
                                        from_uid: uid || 'guest',
                                        to_uid: my_uid
                                      }, {
                                        to_uid: uid || 'guest',
                                        from_uid: my_uid
                                      }])
    f = M[:chats].find_by(uid: my_uid)
    f_c_index = f[:chats].find_index { |f| f[:from_uid] == uid }
    if f_c_index.nil?
      # if my_uid != uid
      # f[:chats] <<
      # end
    else
      f[:chats][f_c_index][:read] = true
      f[:chats][f_c_index][:unread] = 0
      M[:chats].update({uid: my_uid}, f)
    end
    {cmd: 'MESSAGE', msgs: msgs}.to_resp
  end

  get '/chat_msgs_userinfos/:from_uid' do
    to_uid = env[:user]['uid']
    from = M[:userinfos].find_by(uid: params[:from_uid].to_s)
    to = M[:userinfos].find_by(uid: to_uid)
    {from: from, to: to}.to_resp
  end

  get '/chat_msgs_clerkinfos/:from_uid' do
    to_uid = env[:user]['uid']
    from = M[:clerks].find_by(_id: params[:from_uid].to_objid)
    from[:headimgurl] = from[:icon] || from[:avatarUrl]
    to = M[:userinfos].find_by(uid: to_uid)
    {from: from, to: to}.to_resp
  end

  get '/chat_msgs_by_type/:type' do
    my_uid = env[:user]['uid']
    type = params[:type]
    case type
    when 'like'
      M[:chat_notices]
    end
    {
      "createdtime": Time.now,
      "icon": nil,
      "msg": "yy",
      "from_uid": "like",
      "to_uid": my_uid
    }.to_resp
  end

  # 以该客服的名义发一条消息给客户
  get '/chooseCustomer' do
    id = params[:id]
    clerk = M[:clerk].find_by(_id: id.to_objid)
    frominfo = {
      to_id: id,
    }
    save_msg(id, frominfo)
    ''.to_resp
  end

  get '/chat_msgs_likeinfos/:id' do
    to_uid = env[:user]['uid']
    to = M[:userinfos].find_by(uid: to_uid)
    {
      from: {
        avatarUrl: 'like',
      },
      to: to
    }.to_resp
  end

  get '/chat_msgs_discussinfos/:id' do
    uid = env[:user]['uid']
    ul = M[:user_likes].find_by(uid: uid)
    ul[:likes].to_resp
  end

  get '/chat_msgs_fansinfos/:id' do
    uid = env[:user]['uid']
    ul = M[:user_likes].find_by(uid: uid)
    ul[:likes].to_resp
  end

  get '/chat_msgs_systeminfos/:id' do
    uid = env[:user]['uid']
    ul = M[:user_likes].find_by(uid: uid)
    ul[:likes].to_resp
  end
end
