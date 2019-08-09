class RemoveFriendChatUnread < Handler
  def self.process(session, msg, handler)
    fid = msg['fid']
    return ng('invalidparam') if fid.nil? or fid == ''

    zone = session.zone
    uid = session.player_id

    unread = FriendChatDb.del_unread(zone, uid, fid)
    res = {'success' => true,
      'unread' => unread}
    res
  end
end