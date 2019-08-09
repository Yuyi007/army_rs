class GetTenFriends < Handler
  def self.process(session, msg, model)
    instance = model.instance
    pid = instance.player_id
    my_id = pid
    zone = session.zone
    ids = Player.get_range_players(pid)
    
    players_info = []
    ids.each do |cid|
      players = Player.get_players_by_cid(cid, zone)
      players.each do |info|
        frd_id = info.pid
        next if frd_id == my_id
        next if SocialDb.is_friend?(my_id, frd_id, zone)
        next if SocialDb.is_following?(my_id, frd_id, zone)
        players_info << info
      end
    end 
    reqs = players_info.sample(8)
   

    {'friends' => reqs.to_data}
  end
end