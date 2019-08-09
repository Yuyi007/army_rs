class RegisterListenChannelMessage < Handler
  def self.process(session, msg, model)
    uid, zone, instance = session.player_id, session.zone, model.instance
    # d{">>>>>>zone:#{zone}"} 
    pid =  instance.player_id
    res = {'success' => true}
    # puts ">>>>pid:#{pid}"
    ch_id = session.chat_channel_id 
    if ch_id == 0 then
      #join in
      # ch_id = 1  #model.social.chat_channel_id
      ch_id = ChannelChatDb.add_player(ch_id, zone, pid)
      # d{">>>>>>ch_id:#{ch_id}"} 
      return ng('allfull') if ch_id == 0
      ChannelChatDb.add_online_player(ch_id, zone, pid)

      session.chat_channel_id = ch_id
      puts "----session.chat_channel_id:#{session.chat_channel_id}"
      #model.social.chat_channel_id = ch_id
      res['chid'] = ch_id
    end

    #get latest msg
    msgs = ChannelChatDb.get_latest_messages(zone, ch_id)
    msgno = ChannelChatDb.get_msg_no(zone, ch_id)

    res['msgno'] = msgno
    res['msgs'] = msgs
    res
  end
end