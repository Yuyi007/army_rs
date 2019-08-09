class UnRegisterChannel < Handler
  def self.process(session, msg, model)
    instance, zone = model.instance, session.zone
    pid = instance.player_id
    
    ch_id = msg['ch_id'] ##session.chat_channel_id
    # puts ">>>>>>ch_id111:#{ch_id}"
    ChannelChatDb.del_player(ch_id, zone, pid)
    ChannelChatDb.del_online_player(ch_id, zone, pid)
    count = ChannelChatDb.get_channel_players_count(ch_id, zone)
    # puts ">>>>>>count:#{count}"
    if count == 0 
    	# puts ">>>>>>ch_id222:#{ch_id}"
      ChannelChatDb.del_channel_msgs(ch_id, zone)
      # ChannelChatDb.del_channel_id(ch_id, zone)
      # ChannelChatDb.del_mey_channel_id(ch_id)
    end  
    {'success' => true, 'clear' => true}
  end
end