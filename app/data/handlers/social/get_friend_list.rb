class GetFriendList < Handler
  def self.process(session, msg, model)
    instance = model.instance
    my_id, zone = instance.player_id, session.zone

    unread = FriendChatDb.get_unread(zone, my_id)
    
    friend_ids  = SocialDb.friends(my_id, zone)
    friends = friend_ids.map do |frd_id|
      # puts "frd_id:#{frd_id}"
      player_info = Player.read_by_id(frd_id, zone)
      info = {}
      info = player_info.to_hash if player_info
      info
    end

    res = {
      'success' => true,
      'requests' => friends,
      'unread' => unread,
    }
    res
  end
end