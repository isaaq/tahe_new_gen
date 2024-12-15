# frozen_string_literal: true

# typed: ignore
class TaheController < ApiController
  helpers WechatHelper
  register Sinatra::Namespace
  include Auth
  tMessage = "ddd"

  def get_Message(openid,tId,tMessage)
    appid = 'wxd0ce44141d139646'
    appsecret = '0d9168752611661d2b4910f1f511e7fd'
    o = URI.open("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{appid}&secret=#{appsecret}")
    token = o.read
    j = JSON.parse(token)
    #openId JSON.parse(
    u = "https://api.weixin.qq.com/cgi-bin/message/subscribe/send?access_token=#{j['access_token']}"
    uri = URI.parse(u)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    body_data = {
      touser: openid,
      templateId:tId,
      tMessage:tMessage
    }
    request.body = body_data.to_resp
    response = http.request(request)
    response.to_resp
  end

  def get_price(snapinfo)
    gs = M[:goods_snaps].find(_id: snapinfo[:snap_id].to_objid).to_a[0]
    num = snapinfo[:num]
    if gs[:snap_spec_value].nil?
      g = M[:goods].find(_id: gs[:goods_id].to_objid).to_a[0]
      total = g[:price] * num
    else
      total = gs[:snap_spec_value][:price] * num
    end
    total
  end

  namespace '/wechat' do
    get '/getmsg' do
      # uname, pwd = params[:username], params[:password]
      # json_parse = JSON.parse(request.body.read)
      # json_parse['key'] java
      # params[:file][:tempfile].read
      data = [ params[:v1],params[:v2],params[:v3],params[:v4]]
      tid,openid = params[:tid],params[:openid]
      get_Message(openid,tid,data).to_resp
    end

    get '/getbycode/:code' do
      appid = C['appid']
      appsecret = C['appsecret']
      code = params[:code]
      # http访问

      ret = Faraday.get("https://api.weixin.qq.com/sns/jscode2session?appid=#{appid}&secret=#{appsecret}&js_code=#{code}&grant_type=authorization_code")
      retjson = JSON.parse(ret.body)
      # retjson[]
      retjson.to_resp
    end

    get '/prepay' do
      appid = C['appid']
      mch_id = C['mch_id']
      uid = env[:user]['uid']
      nonce_str = SecureRandom.hex
      u = M[:userinfos].find(uid: uid).to_a[0]
      order = M[:orders].find(_id: params[:orderid].to_objid).to_a[0]
      total = order[:goods_snapshots].inject(0) do |t, i|
        t += get_price(i)
        t
      end
      order_no = "#{u[:uid]}-#{Time.current.to_i}"
      M[:orders].find_one_and_update({ _id: params[:orderid].to_objid }, { '$set': { out_trade_no: order_no } })
      remote_ip = '127.0.0.1'
      # created_at = DateTime.now
      # expiration_at = DateTime.now + DateTime.new
      key = 'QoErJErwrpTd7y04xGvJDowULToAEnyV'
      certFileContent = '/cert/apiclient_cert.p12'
      caFileContent = '/cert/apiclient_cert.pem'
      timeout = 10_000
      totalfee = total.round(2) * 100
      request_options = {
        appid: appid,
        mch_id: mch_id,
        body: "h#{order_no}",
        out_trade_no: order_no,
        total_fee: 1, # totalfee.to_i,
        spbill_create_ip: remote_ip,
        notify_url: 'https://hzz.hainanbi.com:9292/paopao/v1/wechat/cb',
        trade_type: 'JSAPI',
        openid: u[:openid],
        key: key
        # time_start: created_at.strftime('%Y%m%d%H%M%S'),
        # time_expire: expiration_at.strftime('%Y%m%d%H%M%S')
      }
      # xml = create_xml(request_options, sign)
      # request_unifiedorder(xml)
      res = WxPay::Service.invoke_unifiedorder(request_options)
      if res.success?
        prepay_id = res['prepay_id']
        pre_pay_id_expired_at = Time.current + 2.hours
        res['time_stamp'] = Time.now.to_i.to_s
        res['nonce_str'] = SecureRandom.hex
        pay_p = {
          appId: appid,
          timeStamp: res['time_stamp'],
          nonceStr: res['nonce_str'],
          package: "prepay_id=#{prepay_id}",
          signType: 'MD5',
          key: key
        }

        res['sign_new'] = WxPay::Sign.generate(pay_p)
      end
      res.to_resp

      # reqstr = "appid=#{appid}&nonceStr=#{nonceStr}&package=#{package}&singType=MD5&timestamp=#{timeStamp}&key=#{key}"
    end

    post '/afterpay_verify' do
      body = request.body.read
      json = JSON.parse(body)
    end

    get '/token' do
      appid = 'wx0cfb01512fa70f08'
      appsecret = '2ac0138cfca822572cc252e32a2fc5c6'
      o = open("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{appid}&secret=#{appsecret}")
      token = o.read
      j = JSON.parse(token)
      u = "https://api.weixin.qq.com/cgi-bin/wxaapp/createwxaqrcode?access_token=#{j['access_token']}"
      uri = URI.parse(u)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = "{\"path\":\"pages/vips/msdetail?code=#{params[:code]}&id=#{params[:id]}\"}"
      response = http.request(request)
      content_type 'image/jpeg'
      response.body
    end

    get '/authcode' do
      appid = C['appid']
      appsecret = C['appsecret']
      url = 'https://api.weixin.qq.com/sns/jscode2session'
      data = {
        appid: appid,
        secret: appsecret,
        grant_type: 'authorization_code',
        js_code: params[:code]
      }
      query = URI.encode_www_form(data)
      r = Faraday.get("#{url}?#{query}").body
      json = JSON.parse(r)
      u = M[:b_users].query({ openid: json['openid'] }).to_a[0]
      if u.nil?
        last_uid = M[:b_users].query.limit(1).sort({ "uid": -1 }).to_a[0]
        uid = last_uid.nil? ? 1 : (last_uid['uid'].to_i + 1)

        userinfo = json.merge(fetch_token_hash({ uid: uid }))
        userinfo['uid'] = uid.to_s.rjust(6, '0')
        userinfo['createdtime'] = DateTime.now
        userinfo['price'] = 0
        userinfo['exp'] = 0
        userinfo['coin'] = 0

        M[:b_users].add(userinfo)
        userinfo.to_resp
      else
        u.merge!(json)
        M[:b_users].update({ openid: json['openid'] }, u)
        fetch_token(u)
      end
    end

    post '/cb' do
      body = request.body.read
      json = Hash.from_xml(body)
      r = M[:paycb].insert_one(json['xml'])
      fee = json['xml']['cash_fee'].to_i / 100
      nt = {
        total_fee: fee,
        out_trade_no: json['xml']['out_trade_no'],
        content: "您已经成功支付#{fee}元"
      }
      M[:chat_notices].insert_one(nt)
      content_type 'text/xml'
      '<xml><return_code><![CDATA[SUCCESS]]></return_code><return_msg><![CDATA[OK]]></return_msg></xml>'
    end

    post '/authphone' do
      uid = env[:user]['uid']
      user = M[:userinfos].find(uid: uid).to_a[0]

      json = JSON.parse(request.body.read)
      enc = Base64.decode64(json['encryptedData'])
      iv = Base64.decode64(json['iv'])
      session_key = Base64.decode64(user[:session_key])

      cipher = OpenSSL::Cipher.new('aes-128-cbc')
      cipher.decrypt
      cipher.key = session_key
      cipher.iv = iv

      ret = JSON.parse(cipher.update(enc) + cipher.final)
      phone = ret['phoneNumber']
      user = M[:userinfos].find(uid: env[:user]['uid']).to_a[0]
      user[:phone] = phone
      M[:userinfos].find_one_and_update({ uid: env[:user]['uid'] }, user)
      raise('appid不匹配') if ret['watermark']['appid'] != C['appid']

      ok
    end
  end
end
