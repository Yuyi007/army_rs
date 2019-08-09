module PushHelper



  APNS.host = 'gateway.push.apple.com'
  APNS.port = 2195
  APNS.pem = Gm::Application.config.rs_base + '/certificate/ck.pem'
  APNS.pass = '123456'

  def self.pushApple(token, message)
    if message[:sandbox]
      APNS.host = 'gateway.sandbox.push.apple.com'
      APNS.pem = Gm::Application.config.rs_base + '/certificate/ck_dev.pem'
    else
      APNS.host = 'gateway.push.apple.com'
      APNS.pem = Gm::Application.config.rs_base + '/certificate/ck.pem'
    end

    if token.length > 0
      n1 = APNS::Notification.new(token, message)
      APNS.send_notifications([n1])
      count = 1
    else
      tokenArray = []
      tokenArray = RsRails.allDeviceTokens
      count = tokenArray.size
      notificationArrays = []

      tokenArray.each do |singleToken|
        notificationArrays << APNS::Notification.new(singleToken, message)
      end

      APNS.send_notifications(notificationArrays)
    end

    return true, count
  end

end
