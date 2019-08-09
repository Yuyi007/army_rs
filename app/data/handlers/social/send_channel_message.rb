class SendChannelMessage < Handler
  def self.process(session, msg, model)
    uid, zone = session.player_id, session.zone   #cur_ch_id, session.chat_channel_id
    instance  = model.instance
    pid       = instance.pid
    ch_id     = msg['channel_id']
    message   = msg['text']
    tag       = msg['tag']
    return ng('invalidparam') if ch_id.nil?
    return ng('gmdeny') if Permission.denied?(uid, zone, 'chat')
    # message = Helper.validateString(message)
    # puts "--ch_id:#{ch_id}"
    # puts "--tag:#{tag}"
    return ng('invalidmsg') if message.nil? or message.empty?
    ch_id = 1 if tag == "WORLD"
    # lv_limit = GameConfig.chief_init_attrs['channel_chat_level']
    # return ng('levellimit') if model.chief.level < lv_limit
    # ch_id = ch_id.to_i
    # return ng('errid') if ch_id == 0
    # puts "----ch_id:#{ch_id} cur_ch_id:#{cur_ch_id}"
    # return ng('mustsame') if ch_id != cur_ch_id

    msg_no = ChannelChatDb.incr_msg_no(zone, ch_id)
    # puts "msg_no:#{msg_no}"
    res = {'success' => true}
    msg_content = {
      'ch_id' => ch_id,
      'msgno' => msg_no,
      'uid'   => uid,
      'pid'   => pid,
      'icon'  => instance.icon,
      'icon_frame' => instance.icon_frame,
      'gender' => instance.gender,
      'name'  => instance.name,
      'level' => instance.level,
      'text'  => message,
      'time'  => Time.now.to_i,
      'vip_level' => model.chief.vip_level,
      'tag'   => tag,
    }
    ChannelChatDb.send_message(ch_id, zone, msg_content)
    res['chid'] = ch_id
    # puts ">>>>>>res:#{res}"
    res
  end
end