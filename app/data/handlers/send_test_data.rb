class SendTestData < Handler
  def self.process(session, msg)
    res = { 'success' => false }
    data = msg['data']
    puts ">>>>>>>data:#{data}"
    res.success = true
    res['data'] = data
    res['info'] = "test success"
    res
  end
end