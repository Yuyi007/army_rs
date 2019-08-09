class GetFriendChatContent < Handler
  def self.process(session, msg, model)
    instance = model.instance
    mypid = instance.player_id
    fid = msg['pid']
    return ng('invalidparam') if fid.nil? or fid == ''

    zone = session.zone
    # uid = session.player_id
    # msg_content = []
    content = FriendChatDb.get_contents(zone, mypid, fid)
    content = content.map do |x|
      mo = FriendTalkMsg.new
      mo.from_json!(x)
      mo.to_hash
      # Jsonable.load_hash(x)
    end
    
    unread = FriendChatDb.del_unread(zone, mypid, fid)

    res = {'success' => true,
      'content' => content,
      'unread' => unread}
    res
  end
end