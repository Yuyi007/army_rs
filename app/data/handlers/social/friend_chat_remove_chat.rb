class RemoveFriendChat < Handler
  def self.process(session, msg, model)
    instance = model.instance
    fid = msg['pid']
    return ng('invalidparam') if fid.nil?

    zone = session.zone
    pid = instance.player_id
    FriendChatDb.del_conversation(zone, pid, fid)
    FriendChatDb.del_conversation(zone, fid, pid)

    # unread = FriendChatDb.get_unread(zone, pid)
    # clist = FriendChatDb.get_list(zone, pid)

    # res = {'success' => true,
    #       'unread' => unread,
    #       'clist' => clist
    #       }
    # res
  end
  
end