class AcceptFriendRequest < Handler
  def self.process(session, msg, model)
  	# puts "msg:#{msg}"
    frd_id = msg['pid']
    
    zone = session.zone
    msg['idname'] = frd_id
    SendFriendRequest.process(session, msg, model)
  end
end