class SearchFriendRequest < Handler
	def self.process(session, msg, model)
		zone     = session.zone
		instance = model.instance
		my_pid   = instance.player_id
		idname = msg["idname"]
		return ng('empty name') if not idname
		res = {}
    reqs = []
		ids = Player.search_by_name(idname, zone)
    if ids.length == 0
      infos = Player.get_players_by_cid(idname, zone)
      infos.each do |playerinfo|
        next if playerinfo.pid == my_pid
        next if SocialDb.is_friend?(my_pid, playerinfo.id, zone)
        next if SocialDb.is_following?(my_pid, playerinfo.id, zone)
        reqs << playerinfo.to_hash
      end
    else  
		  ids.each do |pid|
        next if my_pid == pid
        next if SocialDb.is_friend?(my_pid, pid, zone)
        next if SocialDb.is_following?(my_pid, pid, zone)
        player_info = Player.get(pid)
        reqs << player_info.to_hash if not player_info.nil?
      end
    end  
    res = {
    	'success' => true,
    	'requests' => reqs
    }
    # puts "[[[[[res]]]]]]:#{res}" 
    res
  end		
end