class GetFriendChats < Handler
  def self.process(session, msg, model)
    instance = model.instance
    zone = session.zone
    pid = instance.player_id
    
    # clist = FriendChatDb.get_list(zone, pid)
    unread = FriendChatDb.get_unread(zone, pid)
    res = {'success' => true,
           # 'clist' => clist,
           'unread' => unread
            }
    res
  end
end