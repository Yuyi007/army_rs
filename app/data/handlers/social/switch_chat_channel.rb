class SwitchChatChannel < Handler
  def self.process(session, msg, model)
    uid, zone, cur_ch_id = session.player_id, session.zone, session.chat_channel_id
    ch_id = msg['chid']
    ch_id = ch_id.to_i
    channel_limit = GameConfig.chief_init_attrs['chat_channel_limit']
    return ng('errid') if ch_id <= 0 or ch_id > channel_limit
    return ng('same') if cur_ch_id == ch_id

    res = {'success' => true}

    #have not joined channel
    if cur_ch_id == 0
      ch_id = ChannelChatDb.add_player(ch_id, zone, uid)
      return ng('allfull') if ch_id == 0
      ChannelChatDb.add_online_player(ch_id, zone, uid)
    else
      #chagne channel
      if ch_id != cur_ch_id
        ret = ChannelChatDb.move_player(cur_ch_id, ch_id, zone, uid)
        case ret
        when -1
          return ng('notexist') 
        when -2
          return ng('dstfull')
        when 0
          #success
          ChannelChatDb.del_online_player(cur_ch_id, zone, uid)
          ChannelChatDb.add_online_player(ch_id, zone, uid)
        end
      end
    end

    session.chat_channel_id = ch_id
    model.social.chat_channel_id = ch_id

    res['chid'] = ch_id
    res
  end
end