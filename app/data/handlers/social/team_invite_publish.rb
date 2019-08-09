class TeamInvitePublish < Handler
  def self.process(session, msg, model)
    zone        = session.zone
    instance    = model.instance
    pid         = instance.player_id
    ch_id       = session.chat_channel_id
    uid         = session.player_id
    team_id     = msg['teamid']
    mtype       = msg['mtype']
    ctype       = msg['ctype']
    to_chid     = msg['chid']
    member_num  = msg['memberNum']
    # puts ">>>>>worldId#{ch_id}"
    res = {'success' => true}
    msg_content = {
      'ch_id' => ch_id,
      'to_ch_id' => to_chid,
      'team_id' => team_id,
      'uid'   => uid,
      'pid'   => pid,
      'icon'  => instance.icon,
      'icon_frame'  => instance.icon_frame,
      'name'  => instance.name,
      'level' => instance.level,
      'mtype' => mtype,
      'ctype' => ctype,
      'memnum'=> member_num,
      'time'  => Time.now.to_i,
      'vip_level' => model.chief.vip_level,
      'tag'   => "WORLD",
    }
    ChannelChatDb.send_message(ch_id, zone, msg_content)
    res['chid'] = ch_id
    res
  end
end