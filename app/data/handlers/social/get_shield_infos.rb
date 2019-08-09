class GetShieldInfos < Handler
  def self.process(session, msg, model)
    res = {'success' => true}
    res['infos'] = []
    my_id, zone = session.player_id, session.zone
    friend_ids  = SocialDb.friends(my_id, zone)
    model.social.shield_uids.each_with_index do |id, index|
      info = {}
      info['uid'] = id
      info['time'] = model.social.shield_times[index]
      player = Player.read_by_id(id, zone)
      info['name'] = player.name
      info['level'] = player.level
      info['icon_id'] = player.icon_id
      info['gops'] = player.gops

      info['vip_level'] = player.vip_level

      is_friend = false
      friend_ids.each do |frd_id|
        if frd_id == id
          is_friend = true 
          break
        end
      end
      info['is_friend'] = is_friend
      res['infos'] << info
    end
    res
  end
end