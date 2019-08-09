class GetFriendRequestList < Handler
  def self.process(session, msg, model)
    instance = model.instance
    id,zone = instance.player_id, session.zone
    requests = SocialDb.friend_requests(id, zone)

    reqs = []
    # puts ">>>>>>request:#{requests}"
    requests.each do |pid|
      # puts ">>>uid:#{uid}"
      player_info = Player.read_by_id(pid, zone)
      reqs <<  player_info.to_hash if !player_info.nil?
    end
    
    res = {
      'success' => true,
      'requests' => reqs
    }
  end
end