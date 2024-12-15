# typed: false
module WechatHelper
  def generate_noce_str
    str = ('0'..'z').to_a.join()
    (0...32).map {str[rand(str.length)]}.join
  end

  def get_sign sign_params = [], key=''
    Digest::MD5.hexdigest(sign_params.sort.compact.join('&') +  "&key=#{key}").upcase
  end

  def create_xml(request_options = {}, sign = '')
    "<xml>
          <appid>#{request_options[:appid]}</appid>
          <mch_id>#{request_options[:mch_id]}</mch_id>
          <nonce_str>#{request_options[:nonce_str]}</nonce_str>
          <sign><![CDATA[#{sign}]]></sign>
          <body><![CDATA[#{request_options[:body]}]]></body>
          <out_trade_no>#{request_options[:out_trade_no]}</out_trade_no>
          <total_fee>#{request_options[:total_fee]}</total_fee>
          <spbill_create_ip>#{request_options[:spbill_create_ip]}</spbill_create_ip>
          <notify_url>#{request_options[:notify_url]}</notify_url>
          <trade_type>#{request_options[:trade_type]}</trade_type>
          <time_start>#{request_options[:time_start]}</time_start>
          <time_expire>#{request_options[:time_expire]}</time_expire>
       </xml>"
  end

  def request_unifiedorder(xml = '')
    request_url = 'https://api.mch.weixin.qq.com/pay/unifiedorder'
    HTTParty.post(request_url, body: xml, headers: {'ContentType' => 'application/xml'})
  end
end