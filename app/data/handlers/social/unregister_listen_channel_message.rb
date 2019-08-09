class UnregisterListenChannelMessage < Handler
  def self.process(session, msg, model)
    instance, zone = model.instance, session.zone
    pid = instance.player_id
    ch_id = session.chat_channel_id 
    # d{">>>>>>ch_id:#{ch_id}"} 
    ChannelChatDb.del_player(ch_id, zone, pid)
    ChannelChatDb.del_online_player(ch_id, zone, pid)

    session.chat_channel_id = 0 
    {'success' => true}
  end
end