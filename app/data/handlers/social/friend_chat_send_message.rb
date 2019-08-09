class FriendChatSendMessage < Handler
  def self.process(session, msg, model)
    instance = model.instance
    myPid = instance.player_id
    message = msg['message']
    frdPid = msg['pid']

    return ng('empty_pid') if frdPid.nil? or frdPid == ''

    return ng('invalidmsg') if message.nil? or message.empty?

    return ng('notfriend') if not SocialDb.is_friend?(myPid, frdPid, session.zone)

    res = {'success' => true}
    zone = session.zone           
    uid = session.player_id
    mo = FriendTalkMsg.new
    mo.frompid = myPid
    mo.topid   = frdPid
    mo.icon  = instance.icon
    mo.gender = instance.gender
    mo.level = instance.level
    mo.name  = instance.name
    mo.set_msg(message)
    ms = mo.to_json
    # puts ">>>>>>>ms:#{ms}"
    pids = []
    FriendChatDb.add_message(zone, myPid, frdPid, ms)
    res['msg']     = mo.to_hash
    res['mypid']   = myPid
    res['frdpid']  = frdPid
    pids << myPid
    pids << frdPid
    # clist = FriendChatDb.get_list(zone, myPid)
    # res['clist'] = clist
    
    #通知下发给好友
    hs = {'msg'  => mo.to_hash,
          'pids' => pids}
    Channel.publish('friend_chat', zone, hs)

    res
  end
end