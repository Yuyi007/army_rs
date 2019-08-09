class SaveDriveScheme < Handler
  def self.process(session, msg, model)
    instance   = model.instance
    hid        = msg['hid']
    schemeNum  = msg['scheme']

    instance.avatar_data.device_save_scheme(hid, schemeNum)
    # return ng("data was empty") if data.nil?

    res = {
    	'success' => true,
    	'hid'     => hid,
    	'scheme'  => schemeNum,
    }
    puts("[SaveDriveScheme]res:#{res}")
    res
  end
end