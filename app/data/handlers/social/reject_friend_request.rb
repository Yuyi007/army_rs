class RejectFriendRequest < Handler
  def self.process(session, msg, model)
    pid = msg['pid']
    return ng('Invalid param') if pid.nil?

    msg['type'] = 1
    
    RemoveFriend.process(session, msg, model)
    
  end
end