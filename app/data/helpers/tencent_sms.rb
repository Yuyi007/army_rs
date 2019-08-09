
class TencentSms

  API_URL = "https://yun.tim.qq.com/v5/tlssmssvr/sendsms"
  APP_ID = '1400061226'
  APP_KEY = '3d1c4d3d78f1d1b2c5b5ac72d786b48b'

  def self.send_single(number, msg)
    random = (Random.rand * 100_000_000).to_i
    time = Time.now.to_i
    params = {
      'tel' => {
        'nationcode' => '86',
        'mobile' => number
      },
      'type' => 0,
      'msg' => "【游斯科技】#{msg}",
      'sig' => gen_sig(number, random, time),
      'time' => time,
      'extend' => '',
      'ext' => ''
    }

    begin
      result = self.post_msg("#{API_URL}?sdkappid=#{APP_ID}&random=#{random}", JSON.generate(params))
      res = Oj.load(result)
      Log_.d { "send_single: res=#{res}" }
      if res['result'] == 0
        return true
      else
        Log_.error("send_single res=#{res}")
      end
    rescue => er
      Log_.error('send_single Error: ', er)
    end

    return false
  end

  def self.gen_sig(number, random, time)
    str = "appkey=#{APP_KEY}&random=#{random}&time=#{time}&mobile=#{number}"
    Digest::SHA256.hexdigest(str)
  end

  def self.post_msg(url, msg)
    d {"url: #{url}, msg: #{msg}"}

    if EM.reactor_running?
      http = EventMachine::HttpRequest.new(url).post :body => msg
      http.response
    else
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.post(uri, msg, 'Content-Type' => 'application/json')
      res.body
    end
  end

end
