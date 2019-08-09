class RegisterChannel < Handler
  def self.process(session, msg, model)
    uid, zone, instance = session.player_id, session.zone, model.instance
    pid =  instance.player_id
    res = {'success' => true}
    ch_id = msg['chid']
    # ch_id = 0 if not ch_id

    # puts "register[ch_id111]:#{ch_id}"
    ch_id = ChannelChatDb.add_player2(ch_id, zone, pid)
    puts "register[ch_id]:#{ch_id}"
    ChannelChatDb.add_online_player(ch_id, zone, pid)
    res['chid'] = ch_id
    # end  
    res
  end
end