class ClearFriendUnReadMsg < Handler
  def self.process(session, msg, model)
    instance = model.instance
    zone = session.zone
    pid = instance.pid
    fid = msg['pid']
    
    # clist = FriendChatDb.get_list(zone, pid)
    unread = FriendChatDb.del_unread(zone, pid, fid)
    res = {'success' => true,
           # 'clist' => clist,
           'unread' => unread
            }
    res
  end
end